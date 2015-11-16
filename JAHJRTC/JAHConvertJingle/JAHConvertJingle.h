//
//  JAHConvertJingle.h
//  JAHConvertJingle
//
//  Created by Jon Hjelle on 7/16/14.
//  Copyright (c) 2014 Jon Hjelle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework/DDXML.h>

typedef id (^XMLToObjectBlock)(NSXMLElement* element);
typedef id (^ObjectToXMLBlock)(id object);
typedef NSString* (^ExtractorBlock)(NSXMLElement* element);
typedef void (^BuilderBlock)(NSString* value);

@interface JAHConvertJingle : NSObject

+ (id)objectForElement:(NSXMLNode*)parentElement;

+ (void)registerElementName:(NSString*)name namespace:(NSString*)namespace withDictionary:(NSDictionary*)dictionary;
+ (XMLToObjectBlock)blockForElement:(NSXMLElement*)element;
+ (ObjectToXMLBlock)blockForName:(NSString*)name namespace:(NSString*)namespace;

+ (NSString*)attributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name defaultValue:(NSString*)defaultValue;
+ (NSArray*)childrenOfElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace;

+ (NSString*)subAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute defaultValue:(NSString*)defaultValue;
+ (NSString*)subTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace defaultValue:(NSString*)defaultValue;
+ (NSArray*)multiSubTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace extractorBlock:(ExtractorBlock)extractorBlock;
+ (void)setMultiSubTextForElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace value:(id)value builderBlock:(BuilderBlock)builderBlock;
+ (NSArray*)multiSubAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute;
+ (void)setMultiSubAttributeForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace attributeName:(NSString*)attribute value:(NSString*)value;
+ (BOOL)childrenExistForXMLElement:(NSXMLElement*)element withName:(NSString*)name namespace:(NSString*)namespace;
+ (void)addToElement:(NSXMLElement*)element attributeWithName:(NSString*)name value:(NSString*)value;

@end
