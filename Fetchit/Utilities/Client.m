//
//  Client.m
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "Client.h"

@interface Client () <NSStreamDelegate>

@end

@implementation Client

+ (Client *) defaultClient {
    return [[Client alloc] init];
}

-(BOOL) connectionWithIp:(NSString *) ip port:(NSString *)port timeOut:(double)time {
    
    [self connectionWithIp:ip port:port];
    
    // delay function
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow: time ];
    [NSThread sleepUntilDate:future];
    
    if ([_outputStream streamStatus] != NSStreamStatusOpen) {
        NSLog(@"connect timout!!");
        [self close];
        return NO;
    } else {
        return YES;
    }
}

//與server之間建立通道
-(void) connectionWithIp:(NSString *) ip port:(NSString *)port {
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)ip, [port intValue], &readStream, &writeStream);
    
    if (readStream && writeStream) {
        
        //設定如果串流關閉，socket即跟著關閉
        CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        _outputStream = (__bridge NSOutputStream *)writeStream;
        [_outputStream setDelegate:self];
        [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_outputStream open];
    }
}


- (void)close {
    NSLog(@"Closing streams");
    
    [_inputStream setDelegate:nil];
    [_outputStream setDelegate:nil];
    
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream close];
    [_outputStream close];
    
    _inputStream = nil;
    _outputStream = nil;
}

@end
