//
//  JAHConvertJingle+ICE.m
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle+ICE.h"

static NSString *const NS = @"urn:xmpp:jingle:transports:ice-udp:1";

@implementation JAHConvertJingle (ICE)

+ (void)load {
    XMLToObjectBlock transportToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* iceDictionary = [NSMutableDictionary dictionary];

        iceDictionary[@"transType"] = @"iceUdp";
        iceDictionary[@"pwd"] = [JAHConvertJingle attributeForXMLElement:element withName:@"pwd" defaultValue:nil];
        iceDictionary[@"ufrag"] = [JAHConvertJingle attributeForXMLElement:element withName:@"ufrag" defaultValue:nil];

        iceDictionary[@"candidates"] = [JAHConvertJingle childrenOfElement:element withName:@"candidate" namespace:NS];
        iceDictionary[@"fingerprints"] = [JAHConvertJingle childrenOfElement:element withName:@"fingerprint" namespace:@"urn:xmpp:jingle:apps:dtls:0"];
        iceDictionary[@"sctp"] = [JAHConvertJingle childrenOfElement:element withName:@"sctpmap" namespace:@"urn:xmpp:jingle:transports:dtls-sctp:1"];

        return iceDictionary;
    };
    ObjectToXMLBlock objectToTransport = ^id(id transportObject) {
        NSXMLElement* transportElement = [NSXMLElement elementWithName:@"transport"];
        [transportElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:transportElement attributeWithName:@"pwd" value:transportObject[@"pwd"]];
        [JAHConvertJingle addToElement:transportElement attributeWithName:@"ufrag" value:transportObject[@"ufrag"]];

        ObjectToXMLBlock convertCandidate = [JAHConvertJingle blockForName:@"candidate" namespace:NS];
        for (NSDictionary* candidate in transportObject[@"candidates"]) {
            [transportElement addChild:convertCandidate(candidate)];
        }
        ObjectToXMLBlock convertFingerprint = [JAHConvertJingle blockForName:@"fingerprint" namespace:@"urn:xmpp:jingle:apps:dtls:0"];
        for (NSDictionary* fingerprint in transportObject[@"fingerprints"]) {
            [transportElement addChild:convertFingerprint(fingerprint)];
        }
        ObjectToXMLBlock convertSCTP = [JAHConvertJingle blockForName:@"sctpmap" namespace:@"urn:xmpp:jingle:transports:dtls-sctp:1"];
        for (NSDictionary* sctp in transportObject[@"sctp"]) {
            [transportElement addChild:convertSCTP(sctp)];
        }

        return transportElement;
    };
    [[self class] registerElementName:@"transport" namespace:NS withDictionary:@{@"toObject": transportToObject, @"toElement": objectToTransport}];

    XMLToObjectBlock candidateToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* candidateDictionary = [NSMutableDictionary dictionary];

        candidateDictionary[@"component"] = [JAHConvertJingle attributeForXMLElement:element withName:@"component" defaultValue:nil];
        candidateDictionary[@"foundation"] = [JAHConvertJingle attributeForXMLElement:element withName:@"foundation" defaultValue:nil];
        candidateDictionary[@"generation"] = [JAHConvertJingle attributeForXMLElement:element withName:@"generation" defaultValue:nil];
        candidateDictionary[@"id"] = [JAHConvertJingle attributeForXMLElement:element withName:@"id" defaultValue:nil];
        candidateDictionary[@"ip"] = [JAHConvertJingle attributeForXMLElement:element withName:@"ip" defaultValue:nil];
        candidateDictionary[@"network"] = [JAHConvertJingle attributeForXMLElement:element withName:@"network" defaultValue:nil];
        candidateDictionary[@"port"] = [JAHConvertJingle attributeForXMLElement:element withName:@"port" defaultValue:nil];
        candidateDictionary[@"priority"] = [JAHConvertJingle attributeForXMLElement:element withName:@"priority" defaultValue:nil];
        candidateDictionary[@"protocol"] = [JAHConvertJingle attributeForXMLElement:element withName:@"protocol" defaultValue:nil];
        candidateDictionary[@"relAddr"] = [JAHConvertJingle attributeForXMLElement:element withName:@"rel-addr" defaultValue:nil];
        candidateDictionary[@"relPort"] = [JAHConvertJingle attributeForXMLElement:element withName:@"rel-port" defaultValue:nil];
        candidateDictionary[@"type"] = [JAHConvertJingle attributeForXMLElement:element withName:@"type" defaultValue:nil];

        return candidateDictionary;
    };
    ObjectToXMLBlock objectToCandidate = ^id(id candidateObject) {
        NSXMLElement* candidateElement = [NSXMLElement elementWithName:@"candidate"];
        [candidateElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"component" value:candidateObject[@"component"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"foundation" value:candidateObject[@"foundation"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"generation" value:candidateObject[@"generation"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"id" value:candidateObject[@"id"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"ip" value:candidateObject[@"ip"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"network" value:candidateObject[@"network"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"port" value:candidateObject[@"port"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"priority" value:candidateObject[@"priority"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"protocol" value:candidateObject[@"protocol"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"rel-addr" value:candidateObject[@"relAddr"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"rel-port" value:candidateObject[@"relPort"]];
        [JAHConvertJingle addToElement:candidateElement attributeWithName:@"type" value:candidateObject[@"type"]];

        return candidateElement;
    };
    [[self class] registerElementName:@"candidate" namespace:NS withDictionary:@{@"toObject": candidateToObject, @"toElement": objectToCandidate}];

    XMLToObjectBlock fingerprintToObject = ^id(NSXMLElement  *element) {
        NSMutableDictionary* fingerprintDictionary = [NSMutableDictionary dictionary];

        fingerprintDictionary[@"hash"] = [JAHConvertJingle attributeForXMLElement:element withName:@"hash" defaultValue:nil];
        fingerprintDictionary[@"setup"] = [JAHConvertJingle attributeForXMLElement:element withName:@"setup" defaultValue:nil];
        fingerprintDictionary[@"value"] = [element stringValue];

        return fingerprintDictionary;
    };
    ObjectToXMLBlock objectToFingerprint = ^id(id fingerprintObject) {
        NSXMLElement* fingerprintElement = [NSXMLElement elementWithName:@"fingerprint"];
        [fingerprintElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:xmpp:jingle:apps:dtls:0"]];
        [fingerprintElement setStringValue:fingerprintObject[@"value"]];

        [JAHConvertJingle addToElement:fingerprintElement attributeWithName:@"hash" value:fingerprintObject[@"hash"]];
        [JAHConvertJingle addToElement:fingerprintElement attributeWithName:@"setup" value:fingerprintObject[@"setup"]];

        return fingerprintElement;
    };
    [[self class] registerElementName:@"fingerprint" namespace:@"urn:xmpp:jingle:apps:dtls:0" withDictionary:@{@"toObject": fingerprintToObject, @"toElement": objectToFingerprint}];

    XMLToObjectBlock sctpToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* sctpDictionary = [NSMutableDictionary dictionary];

        sctpDictionary[@"number"] = [JAHConvertJingle attributeForXMLElement:element withName:@"number" defaultValue:nil];
        sctpDictionary[@"protocol"] = [JAHConvertJingle attributeForXMLElement:element withName:@"protocol" defaultValue:nil];
        sctpDictionary[@"streams"] = [JAHConvertJingle attributeForXMLElement:element withName:@"streams" defaultValue:nil];

        return sctpDictionary;
    };
    ObjectToXMLBlock objectToSCTP = ^id(id sctpObject) {
        NSXMLElement* sctpElement = [NSXMLElement elementWithName:@"sctpmap"];
        [sctpElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"urn:xmpp:jingle:transports:dtls-sctp:1"]];

        [JAHConvertJingle addToElement:sctpElement attributeWithName:@"number" value:sctpObject[@"number"]];
        [JAHConvertJingle addToElement:sctpElement attributeWithName:@"protocol" value:sctpObject[@"protocol"]];
        [JAHConvertJingle addToElement:sctpElement attributeWithName:@"streams" value:sctpObject[@"streams"]];

        return sctpElement;
    };
    [[self class] registerElementName:@"sctpmap" namespace:@"urn:xmpp:jingle:transports:dtls-sctp:1" withDictionary:@{@"toObject": sctpToObject, @"toElement": objectToSCTP}];
}

@end
