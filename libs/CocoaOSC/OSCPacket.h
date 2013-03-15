//
//  OSCPacket.h
//  CocoaOSC
//
//  Created by Daniel Dickison on 1/26/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import <Foundation/Foundation.h>


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
