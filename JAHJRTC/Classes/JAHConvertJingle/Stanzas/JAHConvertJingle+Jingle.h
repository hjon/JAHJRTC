//
//  JAHConvertJingle+Jingle.h
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle.h"

@interface JAHConvertJingle (Jingle)

+ (void)registerDatachannelNamespaceAtJingleLevel:(NSString*)namespace;

@end
