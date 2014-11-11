//
//  Server.h
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FetchitServerDelegate <NSObject>

-(void) HasBytesAvailable: (NSInputStream*) stream;

@end

@interface Server : NSObject

@property(strong, nonatomic) id<FetchitServerDelegate> delegate;

-(void) close;
- (id) initWithPort:(NSUInteger) serverport;
- (BOOL) isActive;

@end
