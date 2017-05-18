//
//  JAHConvertJingle+RTP.m
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle+RTP.h"

static NSString *const NS = @"urn:xmpp:jingle:apps:rtp:1";
static NSString *const FBNS = @"urn:xmpp:jingle:apps:rtp:rtcp-fb:0";
static NSString *const HDRNS = @"urn:xmpp:jingle:apps:rtp:rtp-hdrext:0";
static NSString *const INFONS = @"urn:xmpp:jingle:apps:rtp:info:1";
static NSString *const SSMANS = @"urn:xmpp:jingle:apps:rtp:ssma:0";
static NSString *const GROUPNS = @"urn:xmpp:jingle:apps:grouping:0";

@implementation JAHConvertJingle (RTP)

+ (void)load {
    XMLToObjectBlock descriptionToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* description = [NSMutableDictionary dictionary];

        description[@"descType"] = @"rtp";
        description[@"media"] = [JAHConvertJingle attributeForXMLElement:element withName:@"media" defaultValue:nil];
        description[@"ssrc"] = [JAHConvertJingle attributeForXMLElement:element withName:@"ssrc" defaultValue:nil];

        NSString* bandwidth = [JAHConvertJingle subTextForElement:element withName:@"bandwidth" namespace:NS defaultValue:nil];
        NSString* bandwidthType = [JAHConvertJingle subAttributeForXMLElement:element withName:@"bandwidth" namespace:NS attributeName:@"type" defaultValue:nil];
        if ([bandwidth length] && [bandwidth length]) {
            description[@"bandwidth"] = @{@"bandwidth": bandwidth,
                                          @"type": bandwidthType};
        }

        description[@"mux"] = @([JAHConvertJingle childrenExistForXMLElement:element withName:@"rtcp-mux" namespace:NS]);

        NSArray* feedback = [JAHConvertJingle childrenOfElement:element withName:@"rtcp-fb" namespace:FBNS];
        NSArray* moreFeedback = [JAHConvertJingle childrenOfElement:element withName:@"rtcp-fb-trr-int" namespace:FBNS];
        feedback = [feedback arrayByAddingObjectsFromArray:moreFeedback];
        description[@"feedback"] = feedback;

        description[@"headerExtensions"] = [JAHConvertJingle childrenOfElement:element withName:@"rtp-hdrext" namespace:HDRNS];
        description[@"payloads"] = [JAHConvertJingle childrenOfElement:element withName:@"payload-type" namespace:NS];

        description[@"sourceGroups"] = [JAHConvertJingle childrenOfElement:element withName:@"ssrc-group" namespace:SSMANS];
        description[@"sources"] = [JAHConvertJingle childrenOfElement:element withName:@"source" namespace:SSMANS];

        return description;
    };
    ObjectToXMLBlock objectToDescription = ^id(id object) {
        NSXMLElement* description = [NSXMLElement elementWithName:@"description"];
        [description addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:description attributeWithName:@"media" value:object[@"media"]];
        [JAHConvertJingle addToElement:description attributeWithName:@"ssrc" value:object[@"ssrc"]];

        if (object[@"bandwidth"]) {
            ObjectToXMLBlock convertBandwidth = [JAHConvertJingle blockForName:@"bandwidth" namespace:NS];
            [description addChild:convertBandwidth(object[@"bandwidth"])];
        }
        if ([(NSNumber*)object[@"mux"] boolValue]) {
            NSXMLElement* mux = [NSXMLElement elementWithName:@"rtcp-mux"];
            [mux addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];
            [description addChild:mux];
        }

        ObjectToXMLBlock convertFeedback = [JAHConvertJingle blockForName:@"rtcp-fb" namespace:FBNS];
        ObjectToXMLBlock convertMoreFeedback = [JAHConvertJingle blockForName:@"rtcp-fb-trr-int" namespace:FBNS];
        for (NSDictionary* feedback in object[@"feedback"]) {
            if ([feedback[@"type"] isEqualToString:@"trr-int"]) {
                [description addChild:convertFeedback(feedback)];
            } else {
                [description addChild:convertMoreFeedback(feedback)];
            }
        }

        ObjectToXMLBlock convertExtension = [JAHConvertJingle blockForName:@"rtp-hdrext" namespace:HDRNS];
        for (NSDictionary* extension in object[@"headerExtensions"]) {
            [description addChild:convertExtension(extension)];
        }

        ObjectToXMLBlock convertPayload = [JAHConvertJingle blockForName:@"payload-type" namespace:NS];
        for (NSDictionary* payload in object[@"payloads"]) {
            [description addChild:convertPayload(payload)];
        }

        ObjectToXMLBlock convertSourceGroup = [JAHConvertJingle blockForName:@"ssrc-group" namespace:SSMANS];
        for (NSDictionary* sourceGroup in object[@"sourceGroups"]) {
            [description addChild:convertSourceGroup(sourceGroup)];
        }
        ObjectToXMLBlock convertSource = [JAHConvertJingle blockForName:@"source" namespace:SSMANS];
        for (NSDictionary* source in object[@"sources"]) {
            [description addChild:convertSource(source)];
        }

        return description;
    };
    [[self class] registerElementName:@"description" namespace:NS withDictionary:@{@"toObject": descriptionToObject, @"toElement": objectToDescription}];

    XMLToObjectBlock bandwidthToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* bandwidth = [NSMutableDictionary dictionary];

        bandwidth[@"bandwidth"] = [element stringValue];
        bandwidth[@"type"] = [JAHConvertJingle attributeForXMLElement:element withName:@"type" defaultValue:nil];

        return bandwidth;
    };
    ObjectToXMLBlock objectToBandwidth = ^id(id object) {
        NSXMLElement* bandwidth = [NSXMLElement elementWithName:@"bandwidth"];
        [bandwidth addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];
        [bandwidth setStringValue:object[@"bandwidth"]];

        [JAHConvertJingle addToElement:bandwidth attributeWithName:@"type" value:object[@"type"]];

        return  bandwidth;
    };
    [[self class] registerElementName:@"bandwidth" namespace:NS withDictionary:@{@"toObject": bandwidthToObject, @"toElement": objectToBandwidth}];

    XMLToObjectBlock payloadToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* payload = [NSMutableDictionary dictionary];

        payload[@"channels"] = [JAHConvertJingle attributeForXMLElement:element withName:@"channels" defaultValue:nil];
        payload[@"clockrate"] = [JAHConvertJingle attributeForXMLElement:element withName:@"clockrate" defaultValue:nil];
        payload[@"id"] = [JAHConvertJingle attributeForXMLElement:element withName:@"id" defaultValue:nil];
        payload[@"maxptime"] = [JAHConvertJingle attributeForXMLElement:element withName:@"maxptime" defaultValue:nil];
        payload[@"name"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        payload[@"ptime"] = [JAHConvertJingle attributeForXMLElement:element withName:@"ptime" defaultValue:nil];

        NSArray* feedback = [JAHConvertJingle childrenOfElement:element withName:@"rtcp-fb" namespace:FBNS];
        NSArray* moreFeedback = [JAHConvertJingle childrenOfElement:element withName:@"rtcp-fb-trr-int" namespace:FBNS];
        feedback = [feedback arrayByAddingObjectsFromArray:moreFeedback];
        payload[@"feedback"] = feedback;

        payload[@"parameters"] = [JAHConvertJingle childrenOfElement:element withName:@"parameter" namespace:NS];

        return payload;
    };
    ObjectToXMLBlock objectToPayload = ^id(id object) {
        NSXMLElement* payload = [NSXMLElement elementWithName:@"payload-type"];
        [payload addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:payload attributeWithName:@"channels" value:object[@"channels"]];
        [JAHConvertJingle addToElement:payload attributeWithName:@"clockrate" value:object[@"clockrate"]];
        [JAHConvertJingle addToElement:payload attributeWithName:@"id" value:object[@"id"]];
        [JAHConvertJingle addToElement:payload attributeWithName:@"maxptime" value:object[@"maxptime"]];
        [JAHConvertJingle addToElement:payload attributeWithName:@"name" value:object[@"name"]];
        [JAHConvertJingle addToElement:payload attributeWithName:@"ptime" value:object[@"ptime"]];

        ObjectToXMLBlock convertFeedback = [JAHConvertJingle blockForName:@"rtcp-fb" namespace:FBNS];
        ObjectToXMLBlock convertMoreFeedback = [JAHConvertJingle blockForName:@"rtcp-fb-trr-int" namespace:FBNS];
        for (NSDictionary* feedback in object[@"feedback"]) {
            if ([feedback[@"type"] isEqualToString:@"trr-int"]) {
                [payload addChild:convertFeedback(feedback)];
            } else {
                [payload addChild:convertMoreFeedback(feedback)];
            }
        }

        ObjectToXMLBlock convertParameter = [JAHConvertJingle blockForName:@"parameter" namespace:NS];
        for (NSDictionary* parameter in object[@"parameters"]) {
            [payload addChild:convertParameter(parameter)];
        }

        return  payload;
    };
    [[self class] registerElementName:@"payload-type" namespace:NS withDictionary:@{@"toObject": payloadToObject, @"toElement": objectToPayload}];

    XMLToObjectBlock feedbackToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* feedback = [NSMutableDictionary dictionary];
        feedback[@"type"] = [JAHConvertJingle attributeForXMLElement:element withName:@"type" defaultValue:nil];
        feedback[@"subtype"] = [JAHConvertJingle attributeForXMLElement:element withName:@"subtype" defaultValue:nil];
        return feedback;
    };
    ObjectToXMLBlock objectToFeedback = ^id(id object) {
        NSXMLElement* feedback = [NSXMLElement elementWithName:@"rtcp-fb"];
        [feedback addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:FBNS]];

        [JAHConvertJingle addToElement:feedback attributeWithName:@"type" value:object[@"type"]];
        [JAHConvertJingle addToElement:feedback attributeWithName:@"subtype" value:object[@"subtype"]];

        return feedback;
    };
    [[self class] registerElementName:@"rtcp-fb" namespace:FBNS withDictionary:@{@"toObject": feedbackToObject, @"toElement": objectToFeedback}];

    XMLToObjectBlock moreFeedbackToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* feedback = [NSMutableDictionary dictionary];
        feedback[@"type"] = [JAHConvertJingle attributeForXMLElement:element withName:@"type" defaultValue:nil];
        feedback[@"value"] = [JAHConvertJingle attributeForXMLElement:element withName:@"value" defaultValue:nil];
        return feedback;
    };
    ObjectToXMLBlock objectToMoreFeedback = ^id(id object) {
        NSXMLElement* feedback = [NSXMLElement elementWithName:@"rtcp-fb-trr-int"];
        [feedback addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:FBNS]];

        [JAHConvertJingle addToElement:feedback attributeWithName:@"type" value:object[@"type"]];
        [JAHConvertJingle addToElement:feedback attributeWithName:@"value" value:object[@"value"]];

        return feedback;
    };
    [[self class] registerElementName:@"rtcp-fb-trr-int" namespace:FBNS withDictionary:@{@"toObject": moreFeedbackToObject, @"toElement": objectToMoreFeedback}];

    XMLToObjectBlock headerToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* header = [NSMutableDictionary dictionary];
        header[@"id"] = [JAHConvertJingle attributeForXMLElement:element withName:@"id" defaultValue:nil];
        header[@"uri"] = [JAHConvertJingle attributeForXMLElement:element withName:@"uri" defaultValue:nil];
        header[@"senders"] = [JAHConvertJingle attributeForXMLElement:element withName:@"senders" defaultValue:nil];
        return header;
    };
    ObjectToXMLBlock objectToHeader = ^id(id object) {
        NSXMLElement* header = [NSXMLElement elementWithName:@"rtp-hdrext"];
        [header addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:HDRNS]];

        [JAHConvertJingle addToElement:header attributeWithName:@"id" value:object[@"id"]];
        [JAHConvertJingle addToElement:header attributeWithName:@"uri" value:object[@"uri"]];
        [JAHConvertJingle addToElement:header attributeWithName:@"senders" value:object[@"senders"]];

        return header;
    };
    [[self class] registerElementName:@"rtp-hdrext" namespace:HDRNS withDictionary:@{@"toObject": headerToObject, @"toElement": objectToHeader}];

    XMLToObjectBlock parameterToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* parameter = [NSMutableDictionary dictionary];
        parameter[@"key"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        parameter[@"value"] = [JAHConvertJingle attributeForXMLElement:element withName:@"value" defaultValue:nil];
        return parameter;
    };
    ObjectToXMLBlock objectToParameter = ^id(id object) {
        NSXMLElement* parameter = [NSXMLElement elementWithName:@"parameter"];
        [parameter addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:NS]];

        [JAHConvertJingle addToElement:parameter attributeWithName:@"name" value:object[@"key"]];
        [JAHConvertJingle addToElement:parameter attributeWithName:@"value" value:object[@"value"]];

        return parameter;
    };
    [[self class] registerElementName:@"parameter" namespace:NS withDictionary:@{@"toObject": parameterToObject, @"toElement": objectToParameter}];

#pragma mark - Content Group
    XMLToObjectBlock contentGroupToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* contentGroup = [NSMutableDictionary dictionary];
        contentGroup[@"semantics"] = [JAHConvertJingle attributeForXMLElement:element withName:@"semantics" defaultValue:nil];
        contentGroup[@"contents"] = [JAHConvertJingle multiSubAttributeForXMLElement:element withName:@"content" namespace:GROUPNS attributeName:@"name"];
        return contentGroup;
    };
    ObjectToXMLBlock objectToContentGroup = ^id(id object) {
        NSXMLElement* contentGroup = [NSXMLElement elementWithName:@"group"];
        [contentGroup addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:GROUPNS]];

        [JAHConvertJingle addToElement:contentGroup attributeWithName:@"semantics" value:object[@"semantics"]];
        [JAHConvertJingle setMultiSubAttributeForXMLElement:contentGroup withName:@"content" namespace:GROUPNS attributeName:@"name" value:object[@"contents"]];

        return contentGroup;
    };
    [[self class] registerElementName:@"group" namespace:GROUPNS withDictionary:@{@"toObject": contentGroupToObject, @"toElement": objectToContentGroup}];

#pragma mark - Source Group
    XMLToObjectBlock sourceGroupToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* sourceGroup = [NSMutableDictionary dictionary];
        sourceGroup[@"semantics"] = [JAHConvertJingle attributeForXMLElement:element withName:@"semantics" defaultValue:nil];
        sourceGroup[@"sources"] = [JAHConvertJingle multiSubAttributeForXMLElement:element withName:@"source" namespace:SSMANS attributeName:@"ssrc"];
        return sourceGroup;
    };
    ObjectToXMLBlock objectToSourceGroup = ^id(id object) {
        NSXMLElement* sourceGroup = [NSXMLElement elementWithName:@"ssrc-group"];
        [sourceGroup addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:SSMANS]];

        [JAHConvertJingle addToElement:sourceGroup attributeWithName:@"semantics" value:object[@"semantics"]];
        [JAHConvertJingle setMultiSubAttributeForXMLElement:sourceGroup withName:@"source" namespace:SSMANS attributeName:@"ssrc" value:object[@"sources"]];

        return sourceGroup;
    };
    [[self class] registerElementName:@"ssrc-group" namespace:SSMANS withDictionary:@{@"toObject": sourceGroupToObject, @"toElement": objectToSourceGroup}];

#pragma mark - Source
    XMLToObjectBlock sourceToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* source = [NSMutableDictionary dictionary];

        source[@"ssrc"] = [JAHConvertJingle attributeForXMLElement:element withName:@"ssrc" defaultValue:nil];
        source[@"parameters"] = [JAHConvertJingle childrenOfElement:element withName:@"parameter" namespace:SSMANS];

        return source;
    };
    ObjectToXMLBlock objectToSource = ^id(id object) {
        NSXMLElement* source = [NSXMLElement elementWithName:@"source"];
        [source addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:SSMANS]];

        [JAHConvertJingle addToElement:source attributeWithName:@"ssrc" value:object[@"ssrc"]];

        ObjectToXMLBlock convertParameter = [JAHConvertJingle blockForName:@"parameter" namespace:SSMANS];
        for (NSDictionary* parameter in object[@"parameters"]) {
            [source addChild:convertParameter(parameter)];
        }

        return source;
    };
    [[self class] registerElementName:@"source" namespace:SSMANS withDictionary:@{@"toObject": sourceToObject, @"toElement": objectToSource}];

    XMLToObjectBlock sourceParameterToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* parameter = [NSMutableDictionary dictionary];
        parameter[@"key"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        parameter[@"value"] = [JAHConvertJingle attributeForXMLElement:element withName:@"value" defaultValue:nil];
        return parameter;
    };
    ObjectToXMLBlock objectToSourceParameter = ^id(id object) {
        NSXMLElement* parameter = [NSXMLElement elementWithName:@"parameter"];
        [parameter addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:SSMANS]];

        [JAHConvertJingle addToElement:parameter attributeWithName:@"name" value:object[@"key"]];
        [JAHConvertJingle addToElement:parameter attributeWithName:@"value" value:object[@"value"]];

        return parameter;
    };
    [[self class] registerElementName:@"parameter" namespace:SSMANS withDictionary:@{@"toObject": sourceParameterToObject, @"toElement": objectToSourceParameter}];

    XMLToObjectBlock muteToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* mute = [NSMutableDictionary dictionary];
        mute[@"creator"] = [JAHConvertJingle attributeForXMLElement:element withName:@"creator" defaultValue:nil];
        mute[@"name"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        return mute;
    };
    ObjectToXMLBlock objectToMute = ^id(id object) {
        NSXMLElement* mute = [NSXMLElement elementWithName:@"mute"];
        [mute addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:INFONS]];

        [JAHConvertJingle addToElement:mute attributeWithName:@"creator" value:object[@"creator"]];
        [JAHConvertJingle addToElement:mute attributeWithName:@"name" value:object[@"name"]];

        return mute;
    };
    [[self class] registerElementName:@"mute" namespace:INFONS withDictionary:@{@"toObject": muteToObject, @"toElement": objectToMute}];

    XMLToObjectBlock unmuteToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* unmute = [NSMutableDictionary dictionary];
        unmute[@"creator"] = [JAHConvertJingle attributeForXMLElement:element withName:@"creator" defaultValue:nil];
        unmute[@"name"] = [JAHConvertJingle attributeForXMLElement:element withName:@"name" defaultValue:nil];
        return unmute;
    };
    ObjectToXMLBlock objectToUnmute = ^id(id object) {
        NSXMLElement* unmute = [NSXMLElement elementWithName:@"unmute"];
        [unmute addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:INFONS]];

        [JAHConvertJingle addToElement:unmute attributeWithName:@"creator" value:object[@"creator"]];
        [JAHConvertJingle addToElement:unmute attributeWithName:@"name" value:object[@"name"]];

        return unmute;
    };
    [[self class] registerElementName:@"unmute" namespace:INFONS withDictionary:@{@"toObject": unmuteToObject, @"toElement": objectToUnmute}];
}

+ (void)registerDatachannelNamespaceAtRTPLevel:(NSString*)namespace {
    XMLToObjectBlock descriptionToObject = ^id(NSXMLElement *element) {
        NSMutableDictionary* description = [NSMutableDictionary dictionary];
        description[@"descType"] = @"datachannel";
        return description;
    };
    ObjectToXMLBlock objectToDescription = ^id(id object) {
        NSXMLElement* description = [NSXMLElement elementWithName:@"description"];
        [description addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:namespace]];

        return description;
    };
    [[self class] registerElementName:@"description" namespace:namespace withDictionary:@{@"toObject": descriptionToObject, @"toElement": objectToDescription}];
}

@end
