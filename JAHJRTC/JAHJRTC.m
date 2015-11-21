//
//  JAHJRTC.m
//
//  Copyright © 2015 Jon Hjelle. All rights reserved.
//

#import "JAHJRTC.h"

#import "JAHConvertJingle.h"
#import "JAHConvertSDP.h"

@implementation JAHJRTC

#pragma mark - Register data channel namespace

+ (void)registerDatachannelNamespace:(NSString*)namespace {
    [JAHConvertJingle registerDatachannelNamespace:namespace];
}

#pragma mark - Conversion from Jingle XML to SDP

+ (NSDictionary*)incomingAnswerForElement:(NSXMLElement*)element {
    NSDictionary* object = [JAHConvertJingle objectForElement:element];
    return @{@"sdp": [[self class] incomingSDPAnswerForSession:object], @"object": object};
}

+ (NSDictionary*)incomingOfferForElement:(NSXMLElement*)element {
    NSDictionary* object = [JAHConvertJingle objectForElement:element];
    return @{@"sdp": [[self class] incomingSDPOfferForSession:object], @"object": object};
}

+ (NSString*)incomingSDPAnswerForElement:(NSXMLElement*)element {
    NSDictionary* object = [JAHConvertJingle objectForElement:element];
    return [[self class] incomingSDPAnswerForSession:object];
}

+ (NSString*)incomingSDPOfferForElement:(NSXMLElement*)element {
    NSDictionary* object = [JAHConvertJingle objectForElement:element];
    return [[self class] incomingSDPOfferForSession:object];
}

+ (NSXMLElement*)outgoingElementAnswerForSDP:(NSString*)sessionSDP {
    NSDictionary* object = [[self class] outgoingObjectAnswerForSDP:sessionSDP creator:nil];

    ObjectToXMLBlock convertObjectToJingle = [JAHConvertJingle blockForName:@"jingle" namespace:@"urn:xmpp:jingle:1"];
    NSXMLElement* element = convertObjectToJingle(object);

    return element;
}

+ (NSXMLElement*)outgoingElementOfferForSDP:(NSString*)sessionSDP {
    NSDictionary* object = [[self class] outgoingObjectOfferForSDP:sessionSDP creator:nil];

    ObjectToXMLBlock convertObjectToJingle = [JAHConvertJingle blockForName:@"jingle" namespace:@"urn:xmpp:jingle:1"];
    NSXMLElement* element = convertObjectToJingle(object);

    return element;
}

#pragma mark - Conversion for ICE candidates

+ (NSString*)sdpCandidateForObject:(NSDictionary*)object {
    return [JAHConvertSDP sdpForCandidate:object];
}

+ (NSArray*)candidatesForElement:(NSXMLElement *)element previousRemoteState:(NSDictionary*)remoteState {
    NSDictionary *object = [JAHJRTC objectForElement:element];

    NSMutableArray* candidates = [NSMutableArray array];
    for (NSDictionary *content in object[@"contents"]) {
        for (NSDictionary *candidate in content[@"transport"][@"candidates"]) {
            NSString *sdp = [JAHJRTC sdpCandidateForObject:candidate];
            // Drop a=
            sdp = [sdp substringFromIndex:2];
            NSInteger mline = 0;
            NSInteger currentIndex = 0;
            for (NSDictionary *oldContent in remoteState[@"contents"]) {
                if ([oldContent[@"name"] isEqualToString:content[@"name"]]) {
                    mline = currentIndex;
                    break;
                }
                ++currentIndex;
            }

            [candidates addObject:@{@"mid": content[@"name"], @"index": @(mline), @"sdp": sdp}];
        }
    }
    return [candidates copy];
}

// TODO: Add 'action' and 'sid' to the returned <jingle> element?
// TODO: Actually return an <iq> instead of a <jingle> element, with the appropriate type, to, and elementID?
+ (NSXMLElement*)elementForSDPCandidate:(NSString*)candidateSDP mid:(NSString*)mid {
    // The SDP from RTCPeerConnection/RTCICECandidate doesn't quite match what the translator expects, so add 'a=' to the beginning
    candidateSDP = [@"a=" stringByAppendingString:candidateSDP];
    NSDictionary *candidateObject = [JAHConvertSDP candidateForLine:candidateSDP];

    // We want a full <jingle> element to be returned, so wrap the candidate in the structure needed for the translator to return a <jingle> element
    NSDictionary *content = @{@"name": mid,
                              @"transport": @{
                                      @"candidates": @[candidateObject]
                                      }};
    NSDictionary *object = @{@"contents": @[content]};

    return [JAHJRTC elementForJingleObject:object];
}

#pragma mark - Other convenience methods

+ (NSXMLElement*)elementForJingleObject:(NSDictionary*)object {
    ObjectToXMLBlock convertObjectToElement = [JAHConvertJingle blockForName:@"jingle" namespace:@"urn:xmpp:jingle:1"];
    NSXMLElement* element = convertObjectToElement(object);

    return element;
}

+ (NSDictionary*)objectForElement:(NSXMLElement*)element {
    return [JAHConvertJingle objectForElement:element];
}

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

#pragma mark - Conversion from SDP to objects

+ (NSDictionary*)incomingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"responder", @"direction": @"incoming", @"creator": creator};
    } else {
        options = @{@"role": @"responder", @"direction": @"incoming"};
    }
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:options];
}

+ (NSDictionary*)outgoingObjectOfferForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"initiator", @"direction": @"outgoing", @"creator": creator};
    } else {
        options = @{@"role": @"initiator", @"direction": @"outgoing"};
    }
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:options];
}

+ (NSDictionary*)incomingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"initiator", @"direction": @"incoming", @"creator": creator};
    } else {
        options = @{@"role": @"initiator", @"direction": @"incoming"};
    }
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:options];
}

+ (NSDictionary*)outgoingObjectAnswerForSDP:(NSString*)sessionSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"responder", @"direction": @"outgoing", @"creator": creator};
    } else {
        options = @{@"role": @"responder", @"direction": @"outgoing"};
    }
    return [JAHConvertSDP dictionaryForSDP:sessionSDP options:options];
}

+ (NSDictionary*)incomingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"responder", @"direction": @"incoming", @"creator": creator};
    } else {
        options = @{@"role": @"responder", @"direction": @"incoming"};
    }
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:options];
}

+ (NSDictionary*)outgoingMediaObjectOfferForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"initiator", @"direction": @"outgoing", @"creator": creator};
    } else {
        options = @{@"role": @"initiator", @"direction": @"outgoing"};
    }
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:options];
}

+ (NSDictionary*)incomingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"initiator", @"direction": @"incoming", @"creator": creator};
    } else {
        options = @{@"role": @"initiator", @"direction": @"incoming"};
    }
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:options];
}

+ (NSDictionary*)outgoingMediaObjectAnswerForSDP:(NSString*)mediaSDP creator:(NSString*)creator {
    NSDictionary* options;
    if (creator) {
        options = @{@"role": @"responder", @"direction": @"outgoing", @"creator": creator};
    } else {
        options = @{@"role": @"responder", @"direction": @"outgoing"};
    }
    return [JAHConvertSDP dictionaryForSDP:mediaSDP options:options];
}

@end
