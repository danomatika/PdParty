//
//  OSCConnection.h
//  CocoaOSC
//
//  Created by Daniel Dickison on 3/6/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSCConnectionDelegate.h"


@class AsyncSocket;
@class AsyncUdpSocket;
@class OSCPacket;
@class OSCDispatcher;


typedef enum {
    OSCConnectionUDP,
    OSCConnectionTCP_Int32Header,
    OSCConnectionTCP_RFC1055
} OSCConnectionProtocol;



@interface OSCConnection : NSObject
{
    id<OSCConnectionDelegate> delegate;
    OSCDispatcher *dispatcher;
    
    AsyncSocket *tcpListenSocket;
    AsyncSocket *tcpSocket;
    AsyncUdpSocket *udpSocket;
    
    OSCConnectionProtocol protocol;
    
    NSMutableDictionary *pendingPacketsByTag;
    long lastSendTag;
    
    BOOL continuouslyReceivePackets;
}

// Don't change any of these properties after calling connect or accept.
@property (nonatomic, assign) id<OSCConnectionDelegate> delegate;
@property (nonatomic, readonly) OSCDispatcher *dispatcher;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly) NSString *connectedHost;
@property (nonatomic, readonly) UInt16 connectedPort;
@property (nonatomic, readonly) NSString *localHost;
@property (nonatomic, readonly) UInt16 localPort;
@property (nonatomic, readonly) OSCConnectionProtocol protocol;

// Connect and either accept or bind are mutually exclusive.  Don't call one after calling the other.
- (BOOL)connectToHost:(NSString *)host port:(UInt16)port protocol:(OSCConnectionProtocol)protocol error:(NSError **)errPtr;
- (void)disconnect;

// Only TCP connections can accept incoming connections.  Interface can be nil to accept on all interfaces.  Accepted connections will be set to have the given protocol (which must be one of the TCP protocols).
- (BOOL)acceptOnInterface:(NSString *)interface port:(UInt16)port protocol:(OSCConnectionProtocol)proto error:(NSError **)errPtr;

// Bind can be used by a server UDP socket to receive packets before sending anything out.  This will set the protocol property to OSCConnectionUDP.  localAddr can be nil.
- (BOOL)bindToAddress:(NSString *)localAddr port:(UInt16)port error:(NSError **)errPtr;

// Sends a packet.  Use only after calling connect.
- (void)sendPacket:(OSCPacket *)packet;

// Sends a packet to the specified host and port.  This should only be used with UDP sockets that have been set up with bind and have received a packet from a client.
- (void)sendPacket:(OSCPacket *)packet toHost:(NSString *)host port:(UInt16)port;

// Waits for a packet or continuously waits for packets and dispatches them.  Use only after calling connect or bind, or with a connection received via accept.
- (void)receivePacket;
@property (nonatomic, assign) BOOL continuouslyReceivePackets;

@end
