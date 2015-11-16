//
//  JAHConvertSDP.h
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JAHConvertSDP : NSObject

+ (NSDictionary*)dictionaryForSDP:(NSString*)sdp withCreatorRole:(NSString*)creator;
+ (NSString*)SDPForSession:(NSDictionary*)session sid:(NSString*)sid time:(NSString*)time;

@end
