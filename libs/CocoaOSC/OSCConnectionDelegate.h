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

- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet;
- (void)oscConnection:(OSCConnection *)connection didReceivePacket:(OSCPacket *)packet fromHost:(NSString *)host port:(UInt16)port;
- (void)oscConnection:(OSCConnection *)connection failedToReceivePacketWithError:(NSError *)error;

@end