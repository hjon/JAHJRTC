//
//  JAHConvertJingle+Jingle.m
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle+Jingle.h"

static NSString *const NS = @"urn:xmpp:jingle:1";
static NSString *const GROUPNS = @"urn:xmpp:jingle:apps:grouping:0";
static NSString *const INFONS = @"urn:xmpp:jingle:apps:rtp:info:1";
static NSString *const DATANS = @"urn:xmpp:jingle:apps:rtp:1";
static NSString *const ICENS = @"urn:xmpp:jingle:transports:ice-udp:1";

@implementation JAHConvertJingle (Jingle)

+ (void)load {
    XMLToObjectBlock jingleToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* jingleDictionary = [NSMutableDictionary dictionary];

        jingleDictionary[@"action"] = [JAHConvertJingle attributeForXMLElement:element withName:@"action" defaultValue:nil];
        jingleDictionary[@"initiator"] = [JAHConvertJingle attributeForXMLElement:element withName:@"initiator" defaultValue:nil];
        jingleDictionary[@"responder"] = [JAHConvertJingle attributeForXMLElement:element withName:@"responder" defaultValue:nil];
        jingleDictionary[@"sid"] = [JAHConvertJingle attributeForXMLElement:element withName:@"sid" defaultValue:nil];

        jingleDictionary[@"contents"] = [JAHConvertJingle childrenOfElement:element withName:@"content" namespace:NS];
        jingleDictionary[@"groups"] = [JAHConvertJingle childrenOfElement:element withName:@"group" namespace:GROUPNS];
        jingleDictionary[@"muteGroup"] = [JAHConvertJingle childrenOfElement:element withName:@"mute" namespace:INFONS];
        jingleDictionary[@"unmuteGroup"] = [JAHConvertJingle childrenOfElement:element withName:@"unmute" namespace:INFONS];

        return jingleDictionary;
    };
    ObjectToXMLBlock objectToJingle = ^id(id jingleObject) {
        NSXMLElement* jingleElement = [NSXMLElement elementWithName:@"jingle"];
        [jingleElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:jingleElement attributeWithName:@"action" value:jingleObject[@"action"]];
        [JAHConvertJingle addToElement:jingleElement attributeWithName:@"initiator" value:jingleObject[@"initiator"]];
        [JAHConvertJingle addToElement:jingleElement attributeWithName:@"responder" value:jingleObject[@"responder"]];
        [JAHConvertJingle addToElement:jingleElement attributeWithName:@"sid" value:jingleObject[@"sid"]];

        ObjectToXMLBlock convertContent = [JAHConvertJingle blockForName:@"content" namespace:NS];
        for (NSDictionary* content in jingleObject[@"contents"]) {
            [jingleElement addChild:convertContent(content)];
        }
        ObjectToXMLBlock convertGroup = [JAHConvertJingle blockForName:@"group" namespace:GROUPNS];
        for (NSDictionary* group in jingleObject[@"groups"]) {
            [jingleElement addChild:convertGroup(group)];
        }
        ObjectToXMLBlock convertMuteGroup = [JAHConvertJingle blockForName:@"mute" namespace:INFONS];
        for (NSDictionary* mute in jingleObject[@"muteGroup"]) {
            [jingleElement addChild:convertMuteGroup(mute)];
        }
        ObjectToXMLBlock convertUnmuteGroup = [JAHConvertJingle blockForName:@"unmute" namespace:INFONS];
        for (NSDictionary* unmute in jingleObject[@"unmuteGroup"]) {
            [jingleElement addChild:convertUnmuteGroup(unmute)];
        }

        return jingleElement;
    };
    [[self class] registerElementName:@"jingle" namespace:NS withDictionary:@{@"toObject": jingleToObject, @"toElement": objectToJingle}];

    XMLToObjectBlock contentToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* contentDictionary = [NSMutableDictionary dictionary];

        contentDictionary[@"creator"] = [JAHConvertJingle attributeForXMLElement:element withName:@"creator" defaultValue:nil];
        contentDictionary[@"disposition"] = [JAHConvertJingle attributeForXMLElement:element withName:@"disposition" defaultValue:@"session"];
        contentDictionary[@"name"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        contentDictionary[@"senders"] = [JAHConvertJingle attributeForXMLElement:element withName:@"senders" defaultValue:@"both"];

        for (NSXMLNode* node in [element children]) {
            if ([node kind] == NSXMLElementKind) {
                NSXMLElement* element = (NSXMLElement*)node;
                if ([[element name] isEqualToString:@"description"]) {
                    id descriptionObject = [JAHConvertJingle objectForElement:element];
                    if (descriptionObject) {
                        contentDictionary[@"description"] = descriptionObject;
                    }
                } else if ([[element name] isEqualToString:@"transport"]) {
                    id transportObject = [JAHConvertJingle objectForElement:element];
                    if (transportObject) {
                        contentDictionary[@"transport"] = transportObject;
                    }
                }
            }
        }

        return contentDictionary;
    };
    ObjectToXMLBlock objectToContent = ^id(id contentObject) {
        NSXMLElement* contentElement = [NSXMLElement elementWithName:@"content"];
        [contentElement addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:contentElement attributeWithName:@"creator" value:contentObject[@"creator"]];
        [JAHConvertJingle addToElement:contentElement attributeWithName:@"disposition" value:contentObject[@"disposition"]];
        [JAHConvertJingle addToElement:contentElement attributeWithName:@"name" value:contentObject[@"name"]];
        [JAHConvertJingle addToElement:contentElement attributeWithName:@"senders" value:contentObject[@"senders"]];

        NSDictionary* description = contentObject[@"description"];
        if ([description[@"descType"] isEqualToString:@"datachannel"]) {
            ObjectToXMLBlock convertDescription = [JAHConvertJingle blockForName:@"description" namespace:@"http://talky.io/ns/datachannel"];
            [contentElement addChild:convertDescription(description)];
        } else if (description[@"descType"] != nil) {
            ObjectToXMLBlock convertDescription = [JAHConvertJingle blockForName:@"description" namespace:DATANS];
            [contentElement addChild:convertDescription(description)];
        }
        if (contentObject[@"transport"]) {
            ObjectToXMLBlock convertTransport = [JAHConvertJingle blockForName:@"transport" namespace:ICENS];
            [contentElement addChild:convertTransport(contentObject[@"transport"])];
        }

        return contentElement;
    };
    [[self class] registerElementName:@"content" namespace:NS withDictionary:@{@"toObject": contentToObject, @"toElement": objectToContent}];
}


@end
