//
//  OSCDispatcher.m
//  CocoaOSC
//
//  Created by Daniel Dickison on 3/6/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import "OSCDispatcher.h"
#import "OSCPacket.h"
#import "RegexKitLite.h"
#import "NS+OSCAdditions.h"


static NSCharacterSet* getIllegalAddressNameSet();
static NSString* globToRegex(NSString *glob);


@interface OSCAddressNode : NSObject
{
    OSCAddressNode *parent;
    NSString *name;
    NSMutableDictionary *children;
    id target;
    SEL action;
}

@property (nonatomic, assign) OSCAddressNode *parent;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, readonly) NSMutableDictionary *children;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL action;

@property (nonatomic, readonly) NSString *address;

- (NSString *)description;
- (NSArray *)descendantsMatchingPattern:(NSArray *)pattern;
- (NSArray *)descendantsWithTarget:(id)t action:(SEL)a;
- (void)addMethodAtSubAddress:(NSArray *)address target:(id)t action:(SEL)a;
- (void)delete;
- (void)dispatchMessage:(OSCPacket *)message;

@end


@implementation OSCAddressNode

@synthesize parent, name, target, action;

- (void)dealloc
{
    [children release];
    [name release];
    [super dealloc];
}

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"%@ -> %@ (%@)", self.address, self.target, NSStringFromSelector(self.action)];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *allChildren = [[self.children allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [sortDescriptor release];
    for (OSCAddressNode *child in allChildren)
    {
        [string appendFormat:@"\n%@", child];
    }
    return string;
}

- (NSMutableDictionary *)children
{
    if (!children)
    {
        children = [[NSMutableDictionary alloc] init];
    }
    return children;
}

- (NSString *)address
{
    // Base case for root node.
    if (!parent) return @"";
    else return [parent.address stringByAppendingFormat:@"/%@", self.name];
}

- (void)addMethodAtSubAddress:(NSArray *)address target:(id)t action:(SEL)a
{
    if ([address count] == 0)
    {
        // Don't use accessor for children to avoid creating unnecessary empty dictionaries for leaves.
        NSAssert1([children count] == 0, @"Cannot turn a OSC address container node in to a method leaf: %@", self);
        NSAssert1(t, @"Target cannot be nil for OSC address: %@", self);
        NSAssert1(a, @"Action cannot be NULL for OSC address: %@", self);
        self.target = t;
        self.action = a;
        return;
    }
    
    NSAssert1(self.target == nil, @"Cannot add child address to an OSC method leaf node: %@", self);
    NSString *childName = [address car];
    OSCAddressNode *child = [self.children objectForKey:childName];
    if (!child)
    {
        child = [[OSCAddressNode alloc] init];
        child.name = childName;
        child.parent = self;
        [self.children setObject:child forKey:childName];
        [child release];
    }
    [child addMethodAtSubAddress:[address cdr] target:t action:a];
}

- (NSArray *)descendantsMatchingPattern:(NSArray *)pattern
{
    if ([pattern count] == 0)
    {
        // Container nodes don't count.
        if (self.target) return [NSArray arrayWithObject:self];
        else return [NSArray array];
    }
    
    NSString *childPattern = [pattern car];
    NSArray *subPattern = [pattern cdr];
    OSCAddressNode *exactMatchChild = [self.children objectForKey:childPattern];
    if (exactMatchChild)
    {
        return [exactMatchChild descendantsMatchingPattern:subPattern];
    }
    
    NSMutableArray *matchedChildren = [NSMutableArray array];
    for (NSString *childName in self.children)
    {
        if ([childName isMatchedByRegex:childPattern])
        {
            OSCAddressNode *child = [self.children objectForKey:childName];
            NSArray *descendantMatches = [child descendantsMatchingPattern:subPattern];
            [matchedChildren addObjectsFromArray:descendantMatches];
        }
    }
    return matchedChildren;
}

- (NSArray *)descendantsWithTarget:(id)t action:(SEL)a
{
    if (self.target &&
        (!t || self.target == t) &&
        (!a || self.action == a))
    {
        return [NSArray arrayWithObject:self];
    }
    NSMutableArray *matchedChildren = [NSMutableArray array];
    for (OSCAddressNode *child in [self.children allValues])
    {
        [matchedChildren addObjectsFromArray:[child descendantsWithTarget:t action:a]];
    }
    return matchedChildren;
}

- (void)delete
{
    [self.parent.children removeObjectForKey:self.name];
}

- (void)dispatchMessage:(OSCPacket *)message
{
    [self.target performSelector:self.action withObject:message];
}

@end



@implementation OSCDispatcher

- (id)init
{
    if (self = [super init])
    {
        rootNode = [[OSCAddressNode alloc] init];
        rootNode.name = @"";
    }
    return self;
}

- (void)dealloc
{
    [self cancelQueuedBundles];
    [queuedBundles release];
    [rootNode release];
    [super dealloc];
}


- (void)addMethodAddress:(NSString *)address target:(id)target action:(SEL)action
{
    NSArray *addressComponents = [OSCDispatcher splitAddressComponents:address];
    NSAssert1(addressComponents, @"Failed to add OSC method with invalid address: %@", address);
    [rootNode addMethodAtSubAddress:addressComponents target:target action:action];
}

- (void)removeMethodsAtAddressPattern:(NSString *)addressPattern
{
    NSArray *patternComponents = [OSCDispatcher splitPatternComponentsToRegex:addressPattern];
    NSAssert1(patternComponents, @"Failed to remove OSC method with invalid address pattern: %@", addressPattern);
    NSArray *nodes = [rootNode descendantsMatchingPattern:patternComponents];
    [nodes makeObjectsPerformSelector:@selector(delete)];
}

- (void)removeAllTargetMethods:(id)targetOrNil action:(SEL)actionOrNULL
{
    NSArray *nodes = [rootNode descendantsWithTarget:targetOrNil action:actionOrNULL];
    [nodes makeObjectsPerformSelector:@selector(delete)];
}


- (void)dispatchPacket:(OSCPacket *)packet
{
    // TODO: bundles...
    
    NSArray *patternComponents = [OSCDispatcher splitPatternComponentsToRegex:packet.address];
    NSAssert1(patternComponents, @"Failed to remove OSC method with invalid address pattern: %@", packet.address);
    NSArray *nodes = [rootNode descendantsMatchingPattern:patternComponents];
    [nodes makeObjectsPerformSelector:@selector(dispatchMessage:) withObject:packet];
}


- (NSArray *)cancelQueuedBundles
{
    // TODO
}


+ (NSArray *)splitAddressComponents:(NSString *)address
{
    if (![address hasPrefix:@"/"]) return nil;
    
    NSArray *components = [address componentsSeparatedByString:@"/"];
    NSCharacterSet *illegalChars = getIllegalAddressNameSet();
    for (NSString *name in components)
    {
        if ([name rangeOfCharacterFromSet:illegalChars].location != NSNotFound)
        {
            return nil;
        }
    }
    return [components subarrayWithRange:NSMakeRange(1, [components count]-1)];
}

+ (NSArray *)splitPatternComponentsToRegex:(NSString *)pattern
{
    if (![pattern hasPrefix:@"/"]) return nil;
    
    NSString *regexPattern = globToRegex(pattern);
    if (![regexPattern isRegexValid]) return nil;
    
    NSArray *components = [regexPattern componentsSeparatedByString:@"/"];
    return [components subarrayWithRange:NSMakeRange(1, [components count]-1)];
}

@end



NSCharacterSet* getIllegalAddressNameSet()
{
    NSCharacterSet *set = nil;
    if (!set)
    {
        set = [[NSCharacterSet characterSetWithRange:NSMakeRange(0x20, 94)] mutableCopy];
        [(NSMutableCharacterSet *)set removeCharactersInString:@" #,/?*{}[]"];
        [(NSMutableCharacterSet *)set invert];
    }
    return set;
}

// This isn't totally correct as far as quoting occurences of regex-special characters in glob etc, but it's probably good enough for most uses.
NSString* globToRegex(NSString *glob)
{
    NSMutableString *result = [glob mutableCopy];
    [result replaceOccurrencesOfString:@"." withString:@"\\." options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"?" withString:@"." options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"*" withString:@".*?" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"[!" withString:@"[^" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"(" withString:@"\\(" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"{" withString:@"(?:" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@")" withString:@"\\)" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"}" withString:@")" options:0 range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"," withString:@"|" options:0 range:NSMakeRange(0, [result length])];
    return result;
}
