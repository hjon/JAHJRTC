//
//  JAHConvertSDP.h
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JAHConvertSDP : NSObject

+ (NSDictionary*)dictionaryForSDP:(NSString*)sdp options:(NSDictionary*)options;
+ (NSString*)SDPForSession:(NSDictionary*)session options:(NSDictionary*)options;

+ (NSString*)sdpForCandidate:(NSDictionary*)candidate;
+ (NSDictionary*)candidateForLine:(NSString*)line;

@end
