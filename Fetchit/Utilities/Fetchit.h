//
//  Fetchit.h
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/11.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fetchit : NSObject

+ (NSArray *) getIPAddress;
+ (NSString*) stringwithIpArray: (NSArray*) ips;
+ (NSArray*) ArrayWithIpPort: (NSArray*) ips;
+ (BOOL) validateIP: (NSString *) candidate;

@end
