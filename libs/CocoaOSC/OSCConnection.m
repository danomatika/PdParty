//
//  OSCConnection.m
//  CocoaOSC
//
//  Created by Daniel Dickison on 3/6/10.
//  Copyright 2010 Daniel_Dickison. All rights reserved.
//

#import "OSCConnection.h"
#import "OSCPacket.h"
#import "OSCDispatcher.h"
#import "AsyncSocket.h"
#import "AsyncUdpSocket.h"


#define MAX_PACKET_LENGTH 1048576


enum {
    kPacketHeaderTag = -1,
    kPacketDataTag   = -2
};


@interface OSCConnection ()

- (void)dispatchPacketData:(NSData *)data fromHost:(NSString *)host port:(UInt16)port;
- (void)notifyDelegateOfSentPacketWithTag:(long)tag;
- (void)disconnectAndNotifyDelegate:(BOOL)notify;
@property (nonatomic, readonly) id socket; // TCP or UDP socket or nil.

@end


@implementation OSCConnection

@synthesize protocol, delegate, dispatcher, continuouslyReceivePackets;

- (id)init
{
    if (self = [super init])
    {
        dispatcher = [[OSCDispatcher alloc] init];
        pendingPacketsByTag = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
    [dispatcher release];
    [pendingPacketsByTag release];
    [super dealloc];
}


- (void)disconnect
{
    [self disconnectAndNotifyDelegate:self.connected];
}

- (void)disconnectAndNotifyDelegate:(BOOL)notify
{
    [tcpListenSocket setDelegate:nil];
    [tcpListenSocket disconnect];
    [tcpListenSocket release];
    tcpListenSocket = nil;
    
    [tcpSocket setDelegate:nil];
    [tcpSocket disconnect];
    [tcpSocket release];
    tcpSocket = nil;
     
    [udpSocket setDelegate:nil];
    [udpSocket release];
    udpSocket = nil;
     
    [pendingPacketsByTag removeAllObjects];
    if (notify &&
        [delegate respondsToSelector:@selector(oscConnectionDidDisconnect:)])
    {
        [delegate oscConnectionDidDisconnect:self];
    }
}


- (BOOL)isConnected
{
    return [self.socket isConnected];
}


- (id)socket
{
    return (tcpSocket ? (id)tcpSocket : (id)udpSocket);
}


- (NSString *)connectedHost
{
    return [self.socket connectedHost];
}

- (UInt16)connectedPort
{
    return [self.socket connectedPort];
}

- (NSString *)localHost
{
    return [self.socket localHost];
}

- (UInt16)localPort
{
    return [self.socket localPort];
}


- (BOOL)connectToHost:(NSString *)host port:(UInt16)port protocol:(OSCConnectionProtocol)proto error:(NSError **)errPtr
{
    [self disconnectAndNotifyDelegate:self.connected];
    
    protocol = proto;
    
    if ([delegate respondsToSelector:@selector(oscConnectionWillConnect:)])
    {
        [delegate oscConnectionWillConnect:self];
    }
    
    if (protocol == OSCConnectionTCP_Int32Header ||
        protocol == OSCConnectionTCP_RFC1055)
    {
        tcpSocket = [[AsyncSocket alloc] initWithDelegate:self];
        if (![tcpSocket connectToHost:host onPort:port error:errPtr])
        {
            goto onError;
        }
    }
    else
    {
        udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
        if (![udpSocket connectToHost:host onPort:port error:errPtr])
        {
            goto onError;
        }
        else
        {
            // UDP has no actual connection, so we assume it's all peachy and send off the connected notification.
            if ([delegate respondsToSelector:@selector(oscConnectionDidConnect:)])
            {
                [delegate oscConnectionDidConnect:self];
            }
        }
    }
    return YES;
    
onError:
    [self disconnectAndNotifyDelegate:NO];
    return NO;
}


- (BOOL)acceptOnInterface:(NSString *)interface port:(UInt16)port protocol:(OSCConnectionProtocol)proto error:(NSError **)errPtr
{
    NSAssert(proto == OSCConnectionTCP_Int32Header ||
             proto == OSCConnectionTCP_RFC1055,
             @"Can only accept connections on TCP sockets!");
    [self disconnectAndNotifyDelegate:self.connected];
    protocol = proto;
    tcpListenSocket = [[AsyncSocket alloc] initWithDelegate:self];
    return [tcpListenSocket acceptOnInterface:interface port:port error:errPtr];
}


- (BOOL)bindToAddress:(NSString *)localAddr port:(UInt16)port error:(NSError **)errPtr
{
    [self disconnectAndNotifyDelegate:self.connected];
    protocol = OSCConnectionUDP;
    udpSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    return [udpSocket bindToAddress:localAddr port:port error:errPtr];
}


- (void)sendPacket:(OSCPacket *)packet
{
    if (!self.connected)
    {
        // Make this non-fatal since sometimes a disconnect is not detected immediately.
        NSLog(@"Attempted to send an OSC packet while disconnected; ignoring.");
        return;
    }
    
    if ([delegate respondsToSelector:@selector(oscConnection:willSendPacket:)])
    {
        [delegate oscConnection:self willSendPacket:packet];
    }
    
    lastSendTag++;
    [pendingPacketsByTag setObject:packet forKey:[NSNumber numberWithLong:lastSendTag]];
    
    NSData *packetData = [packet encode];
    if (protocol == OSCConnectionUDP)
    {
        [udpSocket sendData:packetData withTimeout:-1 tag:lastSendTag];
    }
    else if (protocol == OSCConnectionTCP_Int32Header)
    {
        uint32_t length = CFSwapInt32HostToBig((uint32_t)[packetData length]);
        NSData *lengthData = [NSData dataWithBytes:&length length:4];
        [tcpSocket writeData:lengthData withTimeout:-1 tag:kPacketHeaderTag];
        [tcpSocket writeData:packetData withTimeout:-1 tag:lastSendTag];
    }
    else
    {
        // TODO: see http://www.faqs.org/rfcs/rfc1055.html
        NSLog(@"OSCConnectionTCP_RFC1055 not yet implemented.");
    }
}


- (void)sendPacket:(OSCPacket *)packet toHost:(NSString *)host port:(UInt16)port
{
    NSAssert(protocol == OSCConnectionUDP &&
             udpSocket &&
             ![udpSocket isConnected],
             @"-[OSCConnection sendPacket:toHost:port] can only be called on a UDP connection that has been binded.");
    lastSendTag++;
    [pendingPacketsByTag setObject:packet forKey:[NSNumber numberWithLong:lastSendTag]];
    [udpSocket sendData:[packet encode] toHost:host port:port withTimeout:-1 tag:lastSendTag];
}


- (void)receivePacket
{
    if (protocol == OSCConnectionUDP)
    {
        [udpSocket receiveWithTimeout:-1 tag:0];
    }
    else if (protocol == OSCConnectionTCP_Int32Header)
    {
        [tcpSocket readDataToLength:4 withTimeout:-1 tag:kPacketHeaderTag];
    }
    else
    {
        // TODO: see http://www.faqs.org/rfcs/rfc1055.html
        NSLog(@"OSCConnectionTCP_RFC1055 not yet implemented.");
    }
}



- (void)dispatchPacketData:(NSData *)data fromHost:(NSString *)host port:(UInt16)port
{
    OSCPacket *packet = [[OSCPacket alloc] initWithData:data];
    if (!packet)
    {
        if ([delegate respondsToSelector:@selector(oscConnection:failedToReceivePacketWithError:)])
        {
            [delegate oscConnection:self failedToReceivePacketWithError:nil];
        }
        return;
    }
    
    [dispatcher dispatchPacket:packet];
    
    if (protocol == OSCConnectionUDP &&
        [delegate respondsToSelector:@selector(oscConnection:didReceivePacket:fromHost:port:)])
    {
        [delegate oscConnection:self didReceivePacket:packet fromHost:host port:port];
    }
    else if ([delegate respondsToSelector:@selector(oscConnection:didReceivePacket:)])
    {
        [delegate oscConnection:self didReceivePacket:packet];
    }
    [packet release];
}


- (void)notifyDelegateOfSentPacketWithTag:(long)tag
{
    NSNumber *key = [NSNumber numberWithLong:tag];
    if ([delegate respondsToSelector:@selector(oscConnection:didSendPacket:)])
    {
        OSCPacket *packet = [pendingPacketsByTag objectForKey:key];
        [delegate oscConnection:self didSendPacket:packet];
    }
    [pendingPacketsByTag removeObjectForKey:key];
}



#pragma mark TCP Delegate Methods

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    [self disconnectAndNotifyDelegate:NO];
    tcpSocket = [newSocket retain];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    if ([delegate respondsToSelector:@selector(oscConnectionDidConnect:)])
    {
        [delegate oscConnectionDidConnect:self];
    }
}


- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    [self disconnectAndNotifyDelegate:YES];
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == kPacketHeaderTag)
    {
        if ([data length] != 4)
        {
            NSLog(@"Expected 4-byte packet header but received %@", data);
            [self disconnectAndNotifyDelegate:YES];
            return;
        }
        const void *bytes = [data bytes];
        uint32_t length = CFSwapInt32BigToHost(*(uint32_t *)bytes);
        if (length > MAX_PACKET_LENGTH)
        {
            NSLog(@"Packet exceeds maximum size (%d > %d bytes)", length, MAX_PACKET_LENGTH);
            [self disconnectAndNotifyDelegate:YES];
            return;
        }
        [sock readDataToLength:length withTimeout:-1 tag:kPacketDataTag];
    }
    else if (tag == kPacketDataTag)
    {
        [self dispatchPacketData:data fromHost:nil port:0];
        if (self.continuouslyReceivePackets)
        {
            [self receivePacket];
        }
    }
}


- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if (tag != kPacketHeaderTag)
    {
        [self notifyDelegateOfSentPacketWithTag:tag];
    }
}


#pragma mark UDP Delegate Methods

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    [self dispatchPacketData:data fromHost:host port:port];
    if (self.continuouslyReceivePackets)
    {
        [self receivePacket];
    }
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    [self notifyDelegateOfSentPacketWithTag:tag];
}

@end
