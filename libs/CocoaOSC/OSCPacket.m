//
//  OSCPacket.m
//  CocoaOSC
//
//  Created by Daniel Dickison on 1/26/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import "OSCPacket.h"
#import "NS+OSCAdditions.h"


static id parseOSCObject(char typetag, const void *bytes, NSUInteger *ioIndex, NSUInteger length);


@implementation OSCImpulse

+ (OSCImpulse *)impulse
{
    static OSCImpulse *impulse = nil;
    if (!impulse)
    {
        impulse = [[OSCImpulse alloc] init];
    }
    return impulse;
}

@end


@implementation OSCBool

+ (OSCBool *)yes
{
    static OSCBool *yes = nil;
    if (!yes)
    {
        yes = [[OSCBool alloc] init];
    }
    return yes;
}

+ (OSCBool *)no
{
    static OSCBool *no = nil;
    if (!no)
    {
        no = [[OSCBool alloc] init];
    }
    return no;
}

- (BOOL)value
{
    return (self == [OSCBool yes]);
}

- (NSString *)description
{
    return (self.value ? @"YES" : @"NO");
}

@end




@implementation OSCPacket


// Following accessors overridden by concrete subclasses.

- (NSString *)address
{
    return nil;
}

- (NSArray *)arguments
{
    return nil;
}

- (NSDate *)timetag
{
    return nil;
}

- (NSArray *)childPackets
{
    return nil;
}



// Methods common to cluster.

- (BOOL)isBundle
{
    return self.childPackets != nil;
}


- (id)initWithData:(NSData *)data
{
    if (self = [super init])
    {
        if ([data length] == 0)
        {
            [self release];
            return nil;
        }
        unsigned char firstByte[1];
        [data getBytes:firstByte length:1];
        if (firstByte[0] == '/')
        {
            [self release];
            self = [[OSCMutableMessage alloc] initWithData:data];
        }
        else if (firstByte[0] == '#')
        {
            [self release];
            self = [[OSCMutableBundle alloc] initWithData:data];
        }
        else
        {
            NSLog(@"Unrecognized first byte for OSC message: %@", data);
            [self release];
            return nil;
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [self release];
    self = nil;
    NSData *data = [aDecoder decodeObjectForKey:@"data"];
    if (data) {
        self = [[OSCPacket alloc] initWithData:data];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    // There are certainly more efficient ways to do this, but this is good enough for now.
    return [[OSCPacket alloc] initWithData:[self encode]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self encode] forKey:@"data"];
}

+ (NSData *)dataForContentObject:(id)obj
{
    if ([obj isKindOfClass:[NSNumber class]])
    {
        const char *objCType = [obj objCType];
        switch (objCType[0])
        {
            case 'c':
            case 'C':
            case 'i':
            case 'I':
            case 's':
            case 'S':
            case 'l':
            case 'L':
            case 'q':
            case 'Q':
            {
                uint32_t num = CFSwapInt32HostToBig([obj intValue]);
                return [NSData dataWithBytes:&num length:4];
            }
            case 'f':
            case 'd':
            {
                CFSwappedFloat32 num = CFConvertFloat32HostToSwapped([obj floatValue]);
                return [NSData dataWithBytes:&num length:4];
            }
            case 'B':
                return [NSData data];
            default:
                return nil;
        }
    }
    else if ([obj isKindOfClass:[NSString class]])
    {
        return [obj oscStringData];
    }
    else if ([obj isKindOfClass:[NSData class]])
    {
        uint32_t contentLength = (uint32_t)[obj length];
        NSUInteger length = 4 + contentLength;
        while (length % 4 > 0) length++;
        NSMutableData *data = [NSMutableData dataWithCapacity:length];
        uint32_t swappedLength = CFSwapInt32HostToBig(contentLength);
        [data appendBytes:&swappedLength length:4];
        [data appendData:obj];
        [data setLength:length];
        return data;
    }
    else if ([obj isKindOfClass:[NSNull class]])
    {
        return [NSData data];
    }
    else if ([obj isKindOfClass:[OSCImpulse class]])
    {
        return [NSData data];
    }
    else if ([obj isKindOfClass:[OSCBool class]])
    {
        return [NSData data];
    }
    else if ([obj isKindOfClass:[NSDate class]])
    {
        uint64_t swapped = CFSwapInt64HostToBig([obj ntpTimestamp]);
        return [NSData dataWithBytes:&swapped length:8];
    }
    // Unknown types return nil;
    return nil;
}


- (NSData *)encode
{
    return nil;
}

@end



@implementation OSCMutableMessage

@synthesize arguments;
@synthesize address;

- (void)dealloc
{
    [arguments release];
    [address release];
    [super dealloc];
}

- (id)init
{
    return [self initWithData:nil];
}

- (id)initWithData:(NSData *)data
{
    if (self = [super init])
    {
        // Init ivars.
        arguments = [[NSMutableArray alloc] init];
        address = @"/";
        
        // Parse data.
        NSUInteger length = [data length];
        if (length > 0)
        {
            const void *bytes = [data bytes];
            NSUInteger index = 0;
            
            // Parse address.
            self.address = parseOSCObject('s', bytes, &index, length);
            
            // Parse type tag and arguments according to those types.
            NSString *typetag = parseOSCObject('s', bytes, &index, length);
            const char *typeCStr = [typetag UTF8String];
            for (unsigned tagIndex = 0; typeCStr[tagIndex] != '\0'; tagIndex++)
            {
                // First character is ',' so skip that.
                if (tagIndex > 0)
                {
                    [self addArgument:parseOSCObject(typeCStr[tagIndex], bytes, &index, length)];
                }
            }
        }
    }
    return self;
}


- (void)addArgument:(id)arg
{
    [self willChangeValueForKey:@"arguments"];
    [(NSMutableArray *)arguments addObject:arg];
    [self didChangeValueForKey:@"arguments"];
}

- (void)addInt:(int)anInt
{
    [self addArgument:[NSNumber numberWithInt:anInt]];
}

- (void)addFloat:(float)aFloat
{
    [self addArgument:[NSNumber numberWithFloat:aFloat]];
}

- (void)addString:(NSString *)str
{
    [self addArgument:str];
}

- (void)addBlob:(NSData *)blob
{
    [self addArgument:blob];
}

- (void)addTimeTag:(NSDate *)time
{
    [self addArgument:time];
}

- (void)addBool:(BOOL)aBool
{
    [self addArgument:(aBool ? [OSCBool yes] : [OSCBool no])];
}

- (void)addNull
{
    [self addArgument:[NSNull null]];
}

- (void)addImpulse
{
    [self addArgument:[OSCImpulse impulse]];
}


- (NSString *)typeTag
{
    NSMutableString *str = [NSMutableString stringWithCapacity:[arguments count]+1];
    [str appendString:@","];
    for (id arg in arguments)
    {
        if ([arg isKindOfClass:[NSNumber class]])
        {
            const char *objCType = [arg objCType];
            switch (objCType[0])
            {
                case 'c':
                case 'C':
                case 'i':
                case 'I':
                case 's':
                case 'S':
                case 'l':
                case 'L':
                case 'q':
                case 'Q':
                    [str appendString:@"i"];
                    break;
                case 'f':
                case 'd':
                    [str appendString:@"f"];
                    break;
                case 'B':
                    if ([arg boolValue])
                    {
                        [str appendString:@"T"];
                    }
                    else
                    {
                        [str appendString:@"F"];
                    }
                    break;
                default:
                    [str appendString:@"?"];
            }
        }
        else if ([arg isKindOfClass:[NSString class]])
        {
            [str appendString:@"s"];
        }
        else if ([arg isKindOfClass:[NSData class]])
        {
            [str appendString:@"b"];
        }
        else if ([arg isKindOfClass:[NSNull class]])
        {
            [str appendString:@"N"];
        }
        else if ([arg isKindOfClass:[OSCImpulse class]])
        {
            [str appendString:@"I"];
        }
        else if ([arg isKindOfClass:[OSCBool class]])
        {
            [str appendString:([(OSCBool *)arg value] ? @"T" : @"F")];
        }
        else if ([arg isKindOfClass:[NSDate class]])
        {
            [str appendString:@"t"];
        }
    }
    return str;
}


- (NSData *)encode
{
    NSMutableData *data = [NSMutableData data];
    if (![address hasPrefix:@"/"])
    {
        NSLog(@"Failed to encode OSCPacket because address doesn't start with a slash: %@", address);
        return nil;
    }
    [data appendData:[address oscStringData]];
    [data appendData:[self.typeTag oscStringData]];
    for (id arg in arguments)
    {
        [data appendData:[OSCPacket dataForContentObject:arg]];
    }
    return data;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<OSCMutableMessage (%@) %@>", address, arguments];
}

@end



@implementation OSCMutableBundle

@synthesize childPackets;
@synthesize timetag;

- (void)dealloc
{
    [childPackets release];
    [timetag release];
    [super dealloc];
}

- (id)init
{
    return [self initWithData:nil];
}

- (id)initWithData:(NSData *)data
{
    if (self = [super init])
    {
        // Init ivars.
        childPackets = [[NSMutableArray alloc] init];
        timetag = [[NSDate alloc] init];
        
        // Parse data if it's not empty (or nil).
        NSUInteger length = [data length];
        if (length > 0)
        {
            const void *bytes = [data bytes];
            NSUInteger index = 0;
            
            // Validate bundle marker.
            NSString *bundleMarker = parseOSCObject('s', bytes, &index, length);
            if (![bundleMarker isEqualToString:@"#bundle"])
            {
                NSLog(@"Malformed bundle marker: %@", bundleMarker);
                [self release];
                return nil;
            }
            
            // Parse time tag.
            self.timetag = parseOSCObject('t', bytes, &index, length);
            
            // Parse children.
            while (index < length)
            {
                NSUInteger size = [parseOSCObject('i', bytes, &index, length) unsignedIntegerValue];
                NSData *subData = [data subdataWithRange:NSMakeRange(index, size)];
                OSCPacket *childPacket = [[OSCPacket alloc] initWithData:subData];
                [self addChildPacket:childPacket];
                [childPacket release];
                index += size;
            }
        }
    }
    return self;
}

- (void)addChildPacket:(OSCPacket *)packet
{
    [(NSMutableArray *)childPackets addObject:packet];
}


- (NSData *)encode
{
    NSMutableData *data = [NSMutableData data];
    [data appendData:[@"#bundle" oscStringData]];
    [data appendData:[OSCPacket dataForContentObject:timetag]];
    for (OSCPacket *child in childPackets)
    {
        NSData *childData = [child encode];
        uint32_t swappedChildLength = CFSwapInt32HostToBig((uint32_t)[childData length]);
        [data appendBytes:&swappedChildLength length:4];
        [data appendData:childData];
    }
    return data;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<OSCMutableBundle (%lu) @ %@>", (unsigned long)[childPackets count], timetag];
}

@end



static id parseOSCObject(char typetag, const void *bytes, NSUInteger *ioIndex, NSUInteger length)
{
    id returnValue;
    switch (typetag)
    {
        case 's':
        {
            // Strings.
            // This implementation mallocs a buffer large enough to hold the rest of the bytes array.  This will be grossly inefficient if this string is followed by large blobs or strings.  Hopefully that is relatively rare.  The upshot is that if the data is missing the terminating NULL character, we won't end up reading random garbage from memory.
            NSUInteger bufferSize = length - (*ioIndex);
            char *buffer = malloc(bufferSize * sizeof(char));
            strncpy(buffer, bytes + (*ioIndex), bufferSize);
            if (buffer[bufferSize-1] == '\0')
            {
                NSUInteger strLength = strlen(buffer);
                returnValue = [[[NSString alloc] initWithBytesNoCopy:buffer length:strLength encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];
                *ioIndex += strLength+1;
            }
            else
            {
                NSLog(@"OSC string was not NULL-terminated!");
                free(buffer);
                *ioIndex = length;
                returnValue = nil;
            }
            break;
        }
        case 'i':
        {
            const void *intPtr = bytes + *ioIndex;
            uint32_t hostInt = CFSwapInt32BigToHost(*(uint32_t *)intPtr);
            returnValue = [NSNumber numberWithInt:hostInt];
            *ioIndex += 4;
            break;
        }
        case 'f':
        {
            const void *floatPtr = bytes + *ioIndex;
            Float32 hostFloat = CFConvertFloat32SwappedToHost(*(CFSwappedFloat32 *)floatPtr);
            returnValue = [NSNumber numberWithFloat:hostFloat];
            *ioIndex += 4;
            break;
        }
        case 'b':
        {
            NSUInteger blobLength = [parseOSCObject('i', bytes, ioIndex, length) unsignedIntegerValue];
            returnValue = [NSData dataWithBytes:(bytes + (*ioIndex)) length:blobLength];
            *ioIndex += blobLength;
            break;
        }
        case 't':
        {
            const void *intPtr = bytes + *ioIndex;
            uint64_t timestamp = CFSwapInt64BigToHost(*(uint64_t *)intPtr);
            returnValue = [NSDate dateWithNTPTimestamp:timestamp];
            *ioIndex += 8;
            break;
        }
        case 'T':
        {
            returnValue = [OSCBool yes];
            break;
        }
        case 'F':
        {
            returnValue = [OSCBool no];
            break;
        }
        case 'I':
        {
            returnValue = [OSCImpulse impulse];
            break;
        }
        case 'N':
        {
            returnValue = [NSNull null];
            break;
        }
        default:
        {
            NSLog(@"Unrecognized OSC type tag: %c", typetag);
            returnValue = nil;
            *ioIndex = length;
            break;
        }
    }
    while (*ioIndex % 4 > 0) (*ioIndex)++;
    
    return returnValue;
}

