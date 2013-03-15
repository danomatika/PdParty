//
//  OSCDispatcher.h
//  CocoaOSC
//
//  Created by Daniel Dickison on 3/6/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OSCAddressNode;
@class OSCPacket;


@interface OSCDispatcher : NSObject
{
    OSCAddressNode *rootNode;
    NSMutableArray *queuedBundles;
}

// Action selectors should have the signature:
// - (void)actionWithMessage:(OSCPacket *)message;
// Targets are not retained, so make sure you remove them before they get dealloced.
// Also note that it is an error for an address to be both a method leaf AND to contain children.  Attempting to add child methods to an already existing method address, or turning an existing parent address in to a method will result in exceptions.
- (void)addMethodAddress:(NSString *)address target:(id)target action:(SEL)action;
- (void)removeMethodsAtAddressPattern:(NSString *)addressPattern;
- (void)removeAllTargetMethods:(id)targetOrNil action:(SEL)actionOrNULL;

// If packet is a message, it will be delivered immediately. If it's a bundle, it may be queued if the timestamp is in the future.
- (void)dispatchPacket:(OSCPacket *)packet;

// Cancels queued bundles from being delivered.  Returns the canceled bundles.
- (NSArray *)cancelQueuedBundles;

// Validates the address.  Returns nil if address is syntactically invalid.
+ (NSArray *)splitAddressComponents:(NSString *)address;
+ (NSArray *)splitPatternComponentsToRegex:(NSString *)pattern;

@end
