//
//  Client.h
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Client : NSObject

@property NSInputStream *inputStream;
@property NSOutputStream *outputStream;

+ (Client *) defaultClient;

-(void) connectionWithIp:(NSString *) ip port:(NSString *)port;
-(BOOL) connectionWithIp:(NSString *) ip port:(NSString *)port timeOut:(double)time;
- (void)close;

@end
