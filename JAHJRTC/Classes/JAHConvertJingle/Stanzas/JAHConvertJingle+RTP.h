//
//  JAHConvertJingle+RTP.h
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertJingle.h"

@interface JAHConvertJingle (RTP)

+ (void)registerDatachannelNamespaceAtRTPLevel:(NSString*)namespace;

@end
