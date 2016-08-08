//
//  OSCPacket.h
//  CocoaOSC
//
//  Created by Daniel Dickison on 1/26/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : char {
    OSCValueTypeNone = 0,

    // Standard arguments
    OSCValueTypeInteger = 'i',  // Int32
    OSCValueTypeFloat = 'f',    // float
    OSCValueTypeString = 's',   // char*
    OSCValueTypeBlob = 'b',

    // Nonstandard arguments
    OSCValueTypeLong = 'h',     // Int64
    OSCValueTypeTimetag = 't'   // Int64
} OSCValueType;

/**
 OSCPacket is a class cluster.  The initializer initWithData: returns one of the two subclasses depending on whether the data describes an OSC message or bundle.  This is used for receiving and parsing OSC packets.  To construct a new packet for sending, using the init initializer of one of the subclasses directly, then call encode to get the network data.
 */
@interface OSCPacket : NSObject <NSCopying, NSCoding>

// Decode/encode from/to NSData.
- (id)initWithData:(NSData *)data;
- (NSData *)encode;
+ (NSData *)dataForContentObject:(id)obj;

// If true, then it has a timetag and childPackets, but no arguments or address.
@property (nonatomic, readonly, getter=isBundle) BOOL bundle;

@property (nonatomic, readonly, copy) NSString *address;
@property (nonatomic, readonly) NSArray *arguments;
@property (nonatomic, readonly, copy) NSDate *timetag;
@property (nonatomic, readonly) NSArray *childPackets;

@end



@interface OSCMutableMessage : OSCPacket
{
    NSString *address;
    NSArray *arguments;
}

- (id)init;

@property (nonatomic, readwrite, copy) NSString *address;

// Use the specific add* methods if possible.  Any unknown types will fail when encode is called.
- (void)addArgument:(id)arg;

- (void)addInt:(int)anInt;
- (void)addFloat:(float)aFloat;
- (void)addString:(NSString *)str;
- (void)addBlob:(NSData *)blob;
- (void)addTimeTag:(NSDate *)time;
- (void)addBool:(BOOL)aBool;
- (void)addNull;
- (void)addImpulse;

@property (nonatomic, readonly) NSString *typeTag;

@end


/** Immutable lazily-parsed message
 */
@interface OSCMessage : OSCPacket
{
    /** Preprocessed packet data
     
     All arguments have been converted to their native endianness after initWithData:
     */
    __strong NSMutableData *packetData;
}

/// System time at which the packet was received (set in initWithData:)
@property (readonly) CFAbsoluteTime timestamp;

/** Initialize with raw packet buffer
 
 @param data raw packet buffer
 
 The data will be converted in-place where byte orders differ from the host CPU
 */
- (id)initWithData:(NSData *)data;


- (NSUInteger)countOfArguments;



/** Pointer to data inside of packet buffer
 
 This method exposes the raw packet data 
 @param index Must be < countOfArguments
 
 @warning This method will return NULL for certain types
 */
- (void *)pointerToArgumentAtIndex:(NSUInteger)index;

/** Length of consumable data

 This method does not take 4-byte alignment into consideration
 */
- (NSUInteger)lengthOfArgumentAtIndex:(NSUInteger)index;
- (OSCValueType)typeOfArgumentAtIndex:(NSUInteger)index;

@end

@interface OSCMutableBundle : OSCPacket
{
    NSDate *timetag;
    NSArray *childPackets;
}

- (id)init;

@property (nonatomic, readwrite, copy) NSDate *timetag;
- (void)addChildPacket:(OSCPacket *)packet;

@end


@interface OSCImpulse : NSObject

+ (OSCImpulse *)impulse;

@end


@interface OSCBool : NSObject

+ (OSCBool *)yes;
+ (OSCBool *)no;
@property (nonatomic, readonly) BOOL value;

@end
