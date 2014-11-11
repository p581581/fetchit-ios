//
//  Request.h
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPRequestOperation.h>

#define AFCALLBACK_H (void (^)(AFHTTPRequestOperation*, id))
#define AFCALLBACK_C ^(AFHTTPRequestOperation *callBack, id responseData)

#define FETCHIT_API_URL @"http://api.magiclen.org/app/fetchit.php"
#define FETCHIT_API_KEY @"testkey"

@interface Request : NSObject

@property (strong, nonatomic) NSString* url;
@property (strong, nonatomic) id parameters;

+ (Request *) defaultRequest;

+ (NSString *) JSONArrayWithArray:(NSArray *) array;
+ (id) JSONObjectWithString:(NSString *) json;
+ (id) JSONObjectWithData:(NSData *) data;

- (void) postWithURL:(NSString *) url parameters:(id)parameters completion:AFCALLBACK_H completion;
- (void) getWithURL:(NSString *) url parameters:(id) parameters completion:AFCALLBACK_H completion;

@end
