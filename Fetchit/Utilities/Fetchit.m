//
//  Fetchit.m
//  SocketFiletTransfer
//
//  Created by 581 on 2014/11/11.
//  Copyright (c) 2014年 581. All rights reserved.
//

#import "Fetchit.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#define SERVER_PORT @22750

@implementation Fetchit

#pragma access ip and port

+ (BOOL) validateIP: (NSString *) candidate {
    
    struct in_addr pin;
    int success = inet_aton([candidate UTF8String],&pin);
    if (success == 1) return TRUE;
    return FALSE;
}

+ (NSArray *) getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    NSMutableArray *addrs = [[NSMutableArray alloc] init];
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                [addrs addObject:address];
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return addrs;
}

+ (NSArray*) ArrayWithIpPort: (NSArray*) ips {
    
    NSMutableArray * ip_ports = [[NSMutableArray alloc] init];
    for (NSString* ip in ips) {
        [ip_ports addObject:@{@"ip": ip, @"port": SERVER_PORT}];
    }
    return ip_ports;
}

+ (NSString*) stringwithIpArray: (NSArray*) ips {
    
    NSMutableString * IPString = [[NSMutableString alloc] init];
    for (NSString* ip in ips) {
        [IPString appendString:ip];
        [IPString appendString:@"\n"];
    }
    return IPString;
}

@end
