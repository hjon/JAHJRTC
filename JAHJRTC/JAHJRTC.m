//
//  JAHJRTC.m
//
//  Copyright © 2015 Jon Hjelle. All rights reserved.
//

#import "JAHJRTC.h"

#import "JAHConvertJingle.h"
#import "JAHConvertSDP.h"

@implementation JAHJRTC

#pragma mark - Conversion from object to SDP

+ (NSString*)incomingSDPOfferForSession:(NSDictionary*)session {
    return [JAHConvertSDP SDPForSession:session options:@{@"role": @"responder", @"direction": @"incoming"}];
}

+ (NSString*)outgoingSDPOfferForSession:(NSDictionary*)session {
    return [JAHConvertSDP SDPForSession:session options:@{@"role": @"initiator", @"direction": @"ougoing"}];
}

+ (NSString*)incomingSDPAnswerForSession:(NSDictionary*)session {
    return [JAHConvertSDP SDPForSession:session options:@{@"role": @"initiator", @"direction": @"incoming"}];
}

+ (NSString*)outgoingSDPAnswerForSession:(NSDictionary*)session {
    return [JAHConvertSDP SDPForSession:session options:@{@"role": @"responder", @"direction": @"outgoing"}];
}

+ (NSString*)incomingMediaSDPOfferForMedia:(NSDictionary*)media {
    return [JAHConvertSDP SDPForSession:media options:@{@"role": @"responder", @"direction": @"incoming"}];
}

+ (NSString*)outgoingMediaSDPOfferForMedia:(NSDictionary*)media {
    return [JAHConvertSDP SDPForSession:media options:@{@"role": @"initiator", @"direction": @"outgoing"}];
}

+ (NSString*)incomingMediaSDPAnswerForMedia:(NSDictionary*)media {
    return [JAHConvertSDP SDPForSession:media options:@{@"role": @"initiator", @"direction": @"incoming"}];
}

+ (NSString*)outgoingMediaSDPAnswerForMedia:(NSDictionary*)media {
    return [JAHConvertSDP SDPForSession:media options:@{@"role": @"responder", @"direction": @"outgoing"}];
}

//toCandidateSDP
//toMediaSDP
//toSessionSDP

#pragma mark - Conversion from SDP to objects

+ (NSDictionary*)incomingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:@{@"role": @"responder", @"direction": @"incoming", @"creator": creator}];
}

+ (NSDictionary*)outgoingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:@{@"role": @"initiator", @"direction": @"outgoing", @"creator": creator}];
}

+ (NSDictionary*)incomingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:@{@"role": @"initiator", @"direction": @"incoming", @"creator": creator}];
}

+ (NSDictionary*)outgoingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:@{@"role": @"responder", @"direction": @"outgoing", @"creator": creator}];
}

+ (NSDictionary*)incomingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:@{@"role": @"responder", @"direction": @"incoming", @"creator": creator}];
}

+ (NSDictionary*)outgoingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:@{@"role": @"initiator", @"direction": @"outgoing", @"creator": creator}];
}

+ (NSDictionary*)incomingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:@{@"role": @"initiator", @"direction": @"incoming", @"creator": creator}];
}

+ (NSDictionary*)outgoingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:@{@"role": @"responder", @"direction": @"outgoing", @"creator": creator}];
}

//toCandidateSDP
//toMediaSDP
//toSessionSDP

@end
