//
//  JAHSenders.m
//
//  Copyright © 2015 Jon Hjelle. All rights reserved.
//

#import "JAHSenders.h"

@implementation JAHSenders

+ (NSDictionary*)senders {
    return @{
             @"initiator": @{
                     @"incoming": @{
                             @"initiator": @"recvonly",
                             @"responder": @"sendonly",
                             @"both": @"sendrecv",
                             @"none": @"inactive",
                             @"recvonly": @"initiator",
                             @"sendonly": @"responder",
                             @"sendrecv": @"both",
                             @"inactive": @"none"
                             },
                     @"outgoing": @{
                             @"initiator": @"sendonly",
                             @"responder": @"recvonly",
                             @"both": @"sendrecv",
                             @"none": @"inactive",
                             @"recvonly": @"responder",
                             @"sendonly": @"initiator",
                             @"sendrecv": @"both",
                             @"inactive": @"none"
                             }
                     },
             @"responder": @{
                     @"incoming": @{
                             @"initiator": @"sendonly",
                             @"responder": @"recvonly",
                             @"both": @"sendrecv",
                             @"none": @"inactive",
                             @"recvonly": @"responder",
                             @"sendonly": @"initiator",
                             @"sendrecv": @"both",
                             @"inactive": @"none"
                             },
                     @"outgoing": @{
                             @"initiator": @"recvonly",
                             @"responder": @"sendonly",
                             @"both": @"sendrecv",
                             @"none": @"inactive",
                             @"recvonly": @"initiator",
                             @"sendonly": @"responder",
                             @"sendrecv": @"both",
                             @"inactive": @"none"
                             }
                     }
             };
}

@end
