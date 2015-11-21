//
//  JAHJRTC.h
//
//  Copyright © 2015 Jon Hjelle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/DDXML.h>

@interface JAHJRTC : NSObject

#pragma mark - Register data channel namespace

+ (void)registerDatachannelNamespace:(NSString*)namespace;

#pragma mark - Conversion to/from Jingle XML and SDP

+ (NSDictionary*)incomingAnswerForElement:(NSXMLElement*)element;
+ (NSDictionary*)incomingOfferForElement:(NSXMLElement*)element;

+ (NSString*)incomingSDPAnswerForElement:(NSXMLElement*)element;
+ (NSString*)incomingSDPOfferForElement:(NSXMLElement*)element;

+ (NSXMLElement*)outgoingElementAnswerForSDP:(NSString*)sessionSDP;
+ (NSXMLElement*)outgoingElementOfferForSDP:(NSString*)sessionSDP;

#pragma mark - Conversion for ICE candidates

+ (NSArray*)candidatesForElement:(NSXMLElement *)element previousRemoteState:(NSDictionary*)remoteState;
+ (NSXMLElement*)elementForSDPCandidate:(NSString*)candidateSDP mid:(NSString*)mid;

#pragma mark - Other convenience methods

+ (NSXMLElement*)elementForJingleObject:(NSDictionary*)object;
+ (NSDictionary*)objectForElement:(NSXMLElement*)element;

#pragma mark - Conversion from objects to SDP

+ (NSString*)incomingSDPOfferForSession:(NSDictionary*)session;
+ (NSString*)outgoingSDPOfferForSession:(NSDictionary*)session;
+ (NSString*)incomingSDPAnswerForSession:(NSDictionary*)session;
+ (NSString*)outgoingSDPAnswerForSession:(NSDictionary*)session;

+ (NSString*)incomingMediaSDPOfferForMedia:(NSDictionary*)media;
+ (NSString*)outgoingMediaSDPOfferForMedia:(NSDictionary*)media;
+ (NSString*)incomingMediaSDPAnswerForMedia:(NSDictionary*)media;
+ (NSString*)outgoingMediaSDPAnswerForMedia:(NSDictionary*)media;

#pragma mark - Conversion from SDP to objects

+ (NSDictionary*)incomingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator;
+ (NSDictionary*)outgoingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator;
+ (NSDictionary*)incomingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator;
+ (NSDictionary*)outgoingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator;

+ (NSDictionary*)incomingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator;
+ (NSDictionary*)outgoingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator;
+ (NSDictionary*)incomingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator;
+ (NSDictionary*)outgoingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator;

@end
