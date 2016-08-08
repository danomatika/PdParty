/*
 *  OSCConnectionDelegate.h
 *  CocoaOSC
 *
 *  Created by Daniel Dickison on 3/6/10.
 *  Copyright 2010 Daniel_Dickison. All rights reserved.
 *
 */

@class OSCConnection;
@class OSCPacket;


@protocol OSCConnectionDelegate <NSObject>

@optional

- (void)oscConnectionWillConnect:(OSCConnection *)connection;
- (void)oscConnectionDidConnect:(OSCConnection *)connection;
- (void)oscConnectionDidDisconnect:(OSCConnection *)connection;

- (void)oscConnection:(OSCConnection *)connection willSendPacket:(OSCPacket *)packet;
- (void)oscConnection:(OSCConnection *)connection didSendPacket:(OSCPacket *)packet;

/** Provide an opportunity for delegates to reject a packet before parsing
 
 Parsing is an expensive operation, and there may be a situation where a packet will
 eventually be discarded without being used. Returning NO from this method will
 cause the data to be discarded before it's parsed.
 */
- (BOOL)oscConnection:(OSCConnection *)connection shouldReceivePacketWithData:(NSData *)data fromHost:(NSString *)host port:(UInt16)port;

- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet;
- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet fromHost:(NSString *)host port:(UInt16)port;
- (void)oscConnection:(OSCConnection *)connection failedToReceivePacketWithError:(NSError *)error;

- (dispatch_queue_t)queue;
@end