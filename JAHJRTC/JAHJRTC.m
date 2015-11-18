//
//  JAHJRTC.m
//
//  Copyright © 2015 Jon Hjelle. All rights reserved.
//

#import "JAHJRTC.h"

#import "JAHConvertJingle.h"
#import "JAHConvertSDP.h"

@implementation JAHJRTC

#pragma mark - Conversion from Jingle XML to SDP

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

+ (NSDictionary*)objectForSDPCandidate:(NSString*)candidateSDP {
    return [JAHConvertSDP candidateForLine:candidateSDP];
}

#pragma mark - Other convenience methods

+ (NSXMLElement*)elementForJingleObject:(NSDictionary*)object {
    ObjectToXMLBlock convertObjectToElement = [JAHConvertJingle blockForName:@"jingle" namespace:@"urn:xmpp:jingle:1"];
    NSXMLElement* element = convertObjectToElement(object);

    return element;
}

+ (NSString*)sdpForJingleElement:(NSXMLElement*)element {
    NSDictionary* object = [JAHConvertJingle objectForElement:element];
    return [JAHConvertSDP SDPForSession:object options:nil];
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
