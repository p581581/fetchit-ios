//
//  Server.m
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "Server.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

Server const* Self;
@interface Server () <NSStreamDelegate>{
    CFSocketRef server;
    BOOL isActive;
}

@property NSInputStream *inputStream;
@property NSOutputStream *outputStream;

@end

@implementation Server

# pragma handle socket and streaming

- (id) initWithPort:(NSUInteger) serverport {
    
    self = [super init];
    
    if (self) {
        Self = self;
        isActive = YES;
        int socketSetupContinue = 1;
        struct sockaddr_in addr;
        
        // 使用TCP傳輸協定，以及ipv4建立Socket通道
        if( !(server = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM,IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&AcceptCallBack, NULL) ) ) {
            NSLog(@"CFSocketCreate failed");
            socketSetupContinue = 0;
        }
        
        if( socketSetupContinue ) {
            int yes = 1;
            if( setsockopt(CFSocketGetNative(server), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(int))) {
                NSLog(@"setsockopt failed");
                CFRelease(server);
                socketSetupContinue = 0;
            }
        }
        
        if( socketSetupContinue ) {
            // 設定ip & port 以及監聽區段
            memset(&addr, 0, sizeof(addr));
            addr.sin_len = sizeof(struct sockaddr_in);
            addr.sin_family = AF_INET;
            addr.sin_port = htons(serverport);
            addr.sin_addr.s_addr = htonl(INADDR_ANY);
            
            NSData *address = [NSData dataWithBytes:&addr length:sizeof(addr)];
            if (CFSocketSetAddress(server, (__bridge CFDataRef)address) != kCFSocketSuccess) {
                NSLog(@"CFSocketSetAddress failed");
                CFRelease(server);
                socketSetupContinue =0;
            }
        }
        
        // make socket in the run loop
        if( socketSetupContinue ) {
            CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, server, 0);
            CFRunLoopAddSource(CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes);
            CFRelease(sourceRef);
        }
    }
    return self;
}

// initialize input stream after server connects
void AcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    /* The native socket, used for various operations */
    CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
    
    /* Create the read and write streams for the socket */
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock, &readStream, &writeStream);
    
    
    if (!readStream || !writeStream) {
        close(sock);
        fprintf(stderr, "CFStreamCreatePairWithSocket() failed\n");
        return;
    }
    
    Self.inputStream = (__bridge NSInputStream *)readStream;
    if (readStream) {
        
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        Self.inputStream = (__bridge NSInputStream *)readStream;
        [Self.inputStream setDelegate:Self];
        [Self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [Self.inputStream open];
        
        NSLog(@"AcceptCallBack");
    }
}

// handle request
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
    //當訊息從主機由iStream端進入時
    switch (eventCode) {
    case NSStreamEventEndEncountered:
        NSLog(@"Event end.");
        [self close];
        break;
    case NSStreamEventErrorOccurred:
        NSLog(@"Error");
        [self close];
        break;
    case NSStreamEventHasSpaceAvailable:
        NSLog(@"HasSpaceAvailable");
        break;
    case NSStreamEventOpenCompleted:
        NSLog(@"open");
        break;
    case NSStreamEventNone:
        NSLog(@"None");
        break;
        
    case NSStreamEventHasBytesAvailable:
            
        if (!isActive) {
            break;
        }
        
        @try {
            [_delegate HasBytesAvailable: (NSInputStream*)stream];
        }
        @catch (NSException *exception) {
            // List the error
            NSLog(@"[ERROR]");
            NSLog(@"name: %@",exception.name);
            NSLog(@"reason: %@",exception.reason);
            // Close the input/output streams and release the server socket
            [self close];
        }
        
        break;
        
    default:
        break;
    }
}

// close all stream and socket
-(void) close {
    NSLog(@"server prepare to close.");
    
    if (_inputStream) {
        [_inputStream setDelegate:nil];
        [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream close];
    }
    if (_outputStream) {
        [_outputStream setDelegate:nil];
        [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream close];
    }
    
    _inputStream = nil;
    _outputStream = nil;
    
    if (server) {
        close(CFSocketGetNative(server));
        CFSocketInvalidate(server);  //closes the socket, unless you set the option to not close on invalidation
    }
    server = nil;
    isActive = NO;
}

- (BOOL) isActive {
    return isActive;
}

@end
