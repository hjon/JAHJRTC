//
//  JAHConvertJingle.m
//  JAHConvertJingle
//
//  Created by Jon Hjelle on 7/16/14.
//  Copyright (c) 2014 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle.h"

@implementation JAHConvertJingle

#pragma mark - XML to objects

+ (id)objectForElement:(NSXMLNode*)node {
    if ([node kind] == NSXMLElementKind) {
        NSXMLElement* element = (NSXMLElement*)node;

        XMLToObjectBlock block = [[self class] blockForElement:element];
        if (block) {
            return block(element);
        }
    }

    return nil;
}

+ (NSMutableDictionary*)sharedConversionMap {
    static NSMutableDictionary* conversionMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        conversionMap = [NSMutableDictionary dictionary];
    });
    return conversionMap;
}

+ (void)registerElementName:(NSString*)name namespace:(NSString*)namespace withDictionary:(NSDictionary*)dictionary {
    NSString* key = [NSString stringWithFormat:@"%@|%@", name, namespace];
    [[[self class] sharedConversionMap] setObject:dictionary forKey:key];
}

+ (XMLToObjectBlock)blockForElement:(NSXMLElement*)element {
    NSXMLNode* namespace = [element resolveNamespaceForName:[element name]];
    NSString* key = [NSString stringWithFormat:@"%@|%@", [element localName], [namespace stringValue]];
    NSDictionary* dictionary = [[[self class] sharedConversionMap] objectForKey:key];
    return dictionary[@"toObject"];
}

+ (ObjectToXMLBlock)blockForName:(NSString*)name namespace:(NSString*)namespace {
    NSString* key = [NSString stringWithFormat:@"%@|%@", name, namespace];
    NSDictionary* dictionary = [[[self class] sharedConversionMap] objectForKey:key];
    return dictionary[@"toElement"];
}

+ (NSString*)attributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name defaultValue:(NSString*)defaultValue {
    NSXMLNode* attribute = [element attributeForName:name];
    NSString* value = [attribute stringValue] ?: defaultValue;
    value = value ?: @"";
    return value;
}

+ (NSArray*)childrenOfElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace {
    NSMutableArray* children = [NSMutableArray array];
    for (NSXMLNode* node in [element elementsForLocalName:name URI:namespace]) {
        id object = [JAHConvertJingle objectForElement:node];
        if (object) {
            [children addObject:object];
        }
    }

    return children;
}

+ (NSString*)subAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute defaultValue:(NSString*)defaultValue {
    NSArray* children = [element elementsForLocalName:name URI:namespace];

    for (NSXMLElement* child in children) {
        return [[child attributeForName:attribute] stringValue];
    }

    return defaultValue ?: @"";
}

+ (NSString*)subTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace defaultValue:(NSString*)defaultValue {
    defaultValue = defaultValue ?: @"";

    NSArray* children = [element elementsForLocalName:name URI:namespace];

    NSString* value = [(NSXMLElement*)[children firstObject] stringValue];
    value = value ?: defaultValue;
    return value;
}

+ (NSArray*)multiSubTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace extractorBlock:(ExtractorBlock)extractorBlock {
    NSArray* children = [element elementsForLocalName:name URI:namespace];
    NSMutableArray* results = [NSMutableArray array];

    if (!extractorBlock) {
        extractorBlock = ^NSString*(NSXMLElement* node) {
            return [node stringValue] ?: @"";
        };
    }

    for (NSXMLElement* child in children) {
        [results addObject:extractorBlock(child)];
    }

    return results;
}

+ (void)setMultiSubTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace value:(id)value builderBlock:(BuilderBlock)builderBlock {
    NSArray* children = [element elementsForLocalName:name URI:namespace];

    if (!builderBlock) {
        builderBlock = ^(NSString *value) {
            NSXMLElement* child = [NSXMLElement elementWithName:name];
            [child setStringValue:value];
            [element addChild:child];
        };
    }

    NSArray* values;
    if ([value isKindOfClass:[NSString class]]) {
        values = [(NSString*)value componentsSeparatedByString:@"\n"];
    } else {
        values = value;
    }

    for (NSXMLElement* child in children) {
        [child detach];
    }

    for (id value in values) {
        builderBlock(value);
    }
}

+ (NSArray*)multiSubAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute {
    return [[self class] multiSubTextForElement:element withName:name namespace:namespace extractorBlock:^NSString *(NSXMLElement *element) {
        return [[self class] attributeForXMLElement:element withName:attribute defaultValue:nil];
    }];
}

+ (void)setMultiSubAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute value:(NSString*)value {
    [[self class] setMultiSubTextForElement:element withName:name namespace:namespace value:value builderBlock:^(NSString *value) {
        NSXMLElement* child = [NSXMLElement elementWithName:name];
        [child addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:namespace]];
        [[self class] addToElement:child attributeWithName:attribute value:value];
        [element addChild:child];
    }];
}

+ (BOOL)childrenExistForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace {
    return ([[element elementsForLocalName:name URI:namespace] count] > 0);
}

+ (void)addToElement:(NSXMLElement*)element attributeWithName:(NSString*)name value:(NSString*)value {
    if (value) {
        [element addAttribute:[NSXMLNode attributeWithName:name stringValue:value]];
    }
}

@end
