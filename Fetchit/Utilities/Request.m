//
//  Request.m
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/10.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "Request.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface Request ()

@property (strong) AFHTTPRequestOperationManager *manager;

@end

@implementation Request

- (id) init{
    self = [super init];
    
    if (self) {
        _manager = [AFHTTPRequestOperationManager manager];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return  self;
}

+ (Request *) defaultRequest {
    return [[Request alloc] init];
}

- (void) postWithURL:(NSString *) url parameters:(id)parameters completion:AFCALLBACK_H completion {
    [_manager POST:url parameters:parameters success:nil failure: AFCALLBACK_C {
        id json = [Request JSONObjectWithData:callBack.responseData];
        completion(callBack, json);
    }];
}

- (void) getWithURL:(NSString *) url parameters:(id) parameters completion:AFCALLBACK_H completion {
    [_manager GET:url parameters:parameters success:nil failure: AFCALLBACK_C {
        id json = [Request JSONObjectWithData:callBack.responseData];
        completion(callBack, json);
    }];
}

+ (NSString *) JSONArrayWithArray:(NSArray *) array {
    NSData* data = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id) JSONObjectWithString:(NSString *) json {
    return [NSJSONSerialization JSONObjectWithData: [json dataUsingEncoding:NSUTF8StringEncoding] options: 0 error: nil];;
}

+ (id) JSONObjectWithData:(NSData *) data {
    return [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];;
}



@end
