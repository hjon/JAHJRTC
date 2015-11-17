//
//  JAHConvertSDP.m
//
//  Copyright (c) 2015 Jon Hjelle. All rights reserved.
//

#import "JAHConvertSDP.h"
#import "JAHSenders.h"

@interface NSMutableArray (JAHConvenience)
- (id)jah_popFirstObject;
@end

@implementation NSMutableArray (JAHConvenience)

- (id)jah_popFirstObject {
    id firstObject = [self firstObject];
    if (firstObject) {
        [self removeObjectAtIndex:0];
    }
    return firstObject;
}

@end


@implementation JAHConvertSDP

+ (NSDictionary*)dictionaryForSDP:(NSString*)sdp options:(NSDictionary*)options {
//    NSString* creator = options[@"creator"] ?: @"initiator";
//    NSString* role = options[@"role"] ?: @"initiator";
//    NSString* direction = options[@"direction"] ?: @"outgoing";

    // Divide the SDP into session and media sections
    NSMutableArray* media = [[sdp componentsSeparatedByString:@"\r\nm="] mutableCopy];
    for (NSUInteger i = 1; i < [media count]; i++) {
        NSMutableString* mediaString = [NSMutableString stringWithFormat:@"m=%@", media[i]];
        if (i != [media count] - 1) {
            [mediaString appendString:@"\r\n"];
        }
        media[i] = mediaString;
    }

    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    NSString* session = [NSString stringWithFormat:@"%@%@", [media jah_popFirstObject], @"\r\n"];

    NSMutableArray* contents = [NSMutableArray array];
    for (NSString* m in media) {
        [contents addObject:[[self class] dictionaryForSDPMedia:m session:session options:options]];
    }
    parsed[@"contents"] = contents;

    NSArray* sessionLines = [[self class] linesForSDP:session];
    NSArray* groupLines = [[self class] linesForPrefix:@"a=group:" mediaLines:nil sessionLines:sessionLines];
    if ([groupLines count] > 0) {
        parsed[@"groups"] = [[self class] groupsForLines:groupLines];
    }

    return parsed;
}

+ (NSDictionary*)dictionaryForSDPMedia:(NSString *)media session:(NSString*)session options:(NSDictionary*)options {
    NSString* creator = options[@"creator"] ?: @"initiator";
    NSString* role = options[@"role"] ?: @"initiator";
    NSString* direction = options[@"direction"] ?: @"outgoing";

    NSArray* mediaLines = [[self class] linesForSDP:media];
    NSArray* sessionLines = [[self class] linesForSDP:session];
    NSDictionary* mLine = [[self class] mLineForLine:[mediaLines firstObject]];

    NSMutableDictionary* content = [NSMutableDictionary dictionary];
    content[@"creator"] = creator;
    //-----------
    content[@"name"] = mLine[@"media"];
    content[@"description"] = [@{@"descType": @"rtp",
                                 @"media": mLine[@"media"],
                                 @"payloads": [NSMutableArray array],
                                 @"encryption": [NSMutableArray array],
                                 @"feedback": [NSMutableArray array],
                                 @"headerExtensions": [NSMutableArray array]} mutableCopy];
    content[@"transport"] = [@{@"transType": @"iceUdp",
                               @"candidates": [NSMutableArray array],
                               @"fingerprints": [NSMutableArray array]} mutableCopy];

    if ([mLine[@"media"] isEqualToString:@"application"]) {
//        FIXME: the description is most likely to be independent
//        of the SDP and should be processed by other parts of the library
        content[@"description"][@"descType"] = @"datachannel";

        content[@"transport"][@"sctp"] = [NSMutableArray array];
    }
    NSMutableDictionary* desc = content[@"description"];
    NSMutableDictionary* transport = content[@"transport"];

    // If we have a mid, use that for the content name instead
    NSString* mid = [[self class] lineForPrefix:@"a=mid:" mediaLines:mediaLines sessionLines:nil];
    if (mid) {
        content[@"name"] = [mid substringFromIndex:6];
    }

    if ([[self class] lineForPrefix:@"a=sendrecv" mediaLines:mediaLines sessionLines:sessionLines]) {
        content[@"senders"] = @"both";
    } else if ([[self class] lineForPrefix:@"a=sendonly" mediaLines:mediaLines sessionLines:sessionLines]) {
        NSDictionary* senders = [JAHSenders senders];
        content[@"senders"] = senders[role][direction][@"sendonly"];
    } else if ([[self class] lineForPrefix:@"a=recvonly" mediaLines:mediaLines sessionLines:sessionLines]) {
        NSDictionary* senders = [JAHSenders senders];
        content[@"senders"] = senders[role][direction][@"recvonly"];;
    } else if ([[self class] lineForPrefix:@"a=inactive" mediaLines:mediaLines sessionLines:sessionLines]) {
        content[@"senders"] = @"none";
    }

    if ([desc[@"descType"] isEqualToString:@"rtp"]) {
        NSString* bandwidth = [[self class] lineForPrefix:@"b=" mediaLines:mediaLines sessionLines:nil];
        if (bandwidth) {
            desc[@"bandwidth"] = [[self class] bandwidthForLine:bandwidth];
        }

        NSString* ssrc = [[self class] lineForPrefix:@"a=ssrc:" mediaLines:mediaLines sessionLines:nil];
        if (ssrc) {
            desc[@"ssrc"] = [[[ssrc substringFromIndex:7] componentsSeparatedByString:@" "] firstObject];
        }

        NSArray* rtpMapLines = [[self class] linesForPrefix:@"a=rtpmap:" mediaLines:mediaLines sessionLines:nil];
        for (NSString* line in rtpMapLines) {
            NSMutableDictionary* payload = [[self class] rtpMapForLine:line];
            payload[@"feedback"] = [NSMutableArray array];

            NSArray* fmtpLines = [[self class] linesForPrefix:[NSString stringWithFormat:@"a=fmtp:%@", payload[@"id"]] mediaLines:mediaLines sessionLines:nil];
            for (NSString* line in fmtpLines) {
                payload[@"parameters"] = [[self class] fmtpForLine:line];
            }

            NSArray* fbLines = [[self class] linesForPrefix:[NSString stringWithFormat:@"a=rtcp-fb:%@", payload[@"id"]] mediaLines:mediaLines sessionLines:nil];
            for (NSString* line in fbLines) {
                [payload[@"feedback"] addObject:[[self class] rtcpfbForLine:line]];
            }

            [desc[@"payloads"] addObject:payload];
        }

        NSArray* cryptoLines = [[self class] linesForPrefix:@"a=crypto:" mediaLines:mediaLines sessionLines:sessionLines];
        for (NSString* line in cryptoLines) {
            [desc[@"encryption"] addObject:[[self class] cryptoForLine:line]];
        }

        NSArray* muxLines = [[self class] linesForPrefix:@"a=rtcp-mux" mediaLines:mediaLines sessionLines:nil];
        if ([muxLines count] > 0) {
            desc[@"mux"] = @YES;
        }

        NSArray* fbLines = [[self class] linesForPrefix:@"a=rtcp-fb:*" mediaLines:mediaLines sessionLines:nil];
        for (NSString* line in fbLines) {
            [desc[@"feedback"] addObject:[[self class] rtcpfbForLine:line]];
        }

        NSArray* extLines = [[self class] linesForPrefix:@"a=extmap:" mediaLines:mediaLines sessionLines:nil];
        for (NSString* line in extLines) {
            NSMutableDictionary* ext = [[self class] extMapForLine:line];

            NSDictionary* senders = [JAHSenders senders];
            ext[@"senders"] = senders[role][direction][ext[@"senders"]];

            [desc[@"headerExtensions"] addObject:ext];
        }

        NSArray* ssrcGroupLines = [[self class] linesForPrefix:@"a=ssrc-group" mediaLines:mediaLines sessionLines:nil];
        desc[@"sourceGroups"] = [[self class] sourceGroupsForLines:ssrcGroupLines];

        NSArray* ssrcLines = [[self class] linesForPrefix:@"a=ssrc:" mediaLines:mediaLines sessionLines:nil];
        desc[@"sources"] = [[self class] sourcesForLines:ssrcLines];
    }

    // transport specific attributes
    NSArray* fingerprintLines = [[self class] linesForPrefix:@"a=fingerprint:" mediaLines:mediaLines sessionLines:sessionLines];
    NSString* setup = [[self class] lineForPrefix:@"a=setup:" mediaLines:mediaLines sessionLines:sessionLines];
    for (NSString* line in fingerprintLines) {
        NSMutableDictionary* fp = [[self class] fingerprintForLine:line];
        if (setup) {
            fp[@"setup"] = [setup substringFromIndex:8];
        }
        [transport[@"fingerprints"] addObject:fp];
    }

    NSString* ufragLine = [[self class] lineForPrefix:@"a=ice-ufrag:" mediaLines:mediaLines sessionLines:sessionLines];
    NSString* pwdLine = [[self class] lineForPrefix:@"a=ice-pwd:" mediaLines:mediaLines sessionLines:sessionLines];
    if (ufragLine && pwdLine) {
        transport[@"ufrag"] = [ufragLine substringFromIndex:12];
        transport[@"pwd"] = [pwdLine substringFromIndex:10];
        transport[@"candidates"] = [NSMutableArray array];

        NSArray* candidateLines = [[self class] linesForPrefix:@"a=candidate:" mediaLines:mediaLines sessionLines:sessionLines];
        for (NSString* line in candidateLines) {
            [transport[@"candidates"] addObject:[[self class] candidateForLine:line]];
        }
    }

    if ([desc[@"descType"] isEqualToString:@"datachannel"]) {
        NSArray* sctpMapLines = [[self class] linesForPrefix:@"a=sctpmap:" mediaLines:mediaLines sessionLines:nil];
        for (NSString* line in sctpMapLines) {
            [transport[@"sctp"] addObject:[[self class] sctpMapForLine:line]];
        }
    }
    
    return content;
}

+ (NSDictionary*)candidateForLine:(NSString*)line {
    NSArray* components = [line componentsSeparatedByString:@"\r\n"];
    NSMutableDictionary* candidate = [[self class] _candidateForLine:[components firstObject]];

    // TODO: Allow this id to be set by tests
    candidate[@"id"] = [[NSUUID UUID] UUIDString];
    return candidate;
}

#pragma mark - Parsing stuff

+ (NSArray*)linesForSDP:(NSString*)sdp {
    NSArray* lines = [sdp componentsSeparatedByString:@"\r\n"];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"length > 0"];
    return [lines filteredArrayUsingPredicate:predicate];
}

+ (NSString*)lineForPrefix:(NSString*)prefix mediaLines:(NSArray*)mediaLines sessionLines:(NSArray*)sessionLines {
    for (NSString* mediaLine in mediaLines) {
        if ([mediaLine hasPrefix:prefix]) {
            return mediaLine;
        }
    }

    for (NSString* sessionLine in sessionLines) {
        if ([sessionLine hasPrefix:prefix]) {
            return sessionLine;
        }
    }
    return nil;
}

+ (NSArray*)linesForPrefix:(NSString*)prefix mediaLines:(NSArray*)mediaLines sessionLines:(NSArray*)sessionLines {
    NSMutableArray* results = [NSMutableArray array];

    for (NSString* mediaLine in mediaLines) {
        if ([mediaLine hasPrefix:prefix]) {
            [results addObject:mediaLine];
        }
    }

    if ([results count]) {
        return results;
    }

    for (NSString* sessionLine in sessionLines) {
        if ([sessionLine hasPrefix:prefix]) {
            [results addObject:sessionLine];
        }
    }
    return results;
}

#pragma mark -

+ (NSDictionary*)mLineForLine:(NSString*)line {
    NSArray* parts = [[line substringFromIndex:2] componentsSeparatedByString:@" "];
    NSDictionary* parsed = @{@"media": parts[0],
                             @"port": parts[1],
                             @"proto": parts[2],
                             @"formats": [NSMutableArray array]};

    for (NSUInteger i = 3; i < [parts count]; i++) {
        if (parts[i]) {
            [parsed[@"format"] addObject:parts[i]];
        }
    }

    return parsed;
}

+ (NSMutableDictionary*)rtpMapForLine:(NSString*)line {
    NSMutableArray* parts = [[[line substringFromIndex:9] componentsSeparatedByString:@" "] mutableCopy];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    parsed[@"id"] = [parts jah_popFirstObject];

    parts = [[parts[0] componentsSeparatedByString:@"/"] mutableCopy];

    parsed[@"name"] = parts[0];
    parsed[@"clockrate"] = parts[1];
    parsed[@"channels"] = ([parts count] == 3 ? parts[2] : @"1");
    return parsed;
}

+ (NSDictionary*)sctpMapForLine:(NSString*)line {
    // based on -05 draft
    NSArray* parts = [[line substringFromIndex:10] componentsSeparatedByString:@" "];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    parsed[@"number"] = parts[0];
    parsed[@"protocol"] = parts[1];
    parsed[@"streams"] = parts[2];
    return parsed;
}

+ (NSArray*)fmtpForLine:(NSString*)line {
    NSRange range = [line rangeOfString:@" "];
    NSArray* parts = [[line substringFromIndex:(range.location + 1)] componentsSeparatedByString:@";"];

    NSArray* keyValue;
    NSMutableArray* parsed = [NSMutableArray array];
    for (NSString* part in parts) {
        keyValue = [part componentsSeparatedByString:@"="];
        NSString* key = [keyValue[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString* value = keyValue[1];
        if (key && value) {
            [parsed addObject:@{@"key": key, @"value": value}];
        } else if (key) {
            [parsed addObject:@{@"key": @"", @"value": value}];
        }
    }

    return parsed;
}

+ (NSDictionary*)cryptoForLine:(NSString*)line {
    NSArray* parts = [[line substringFromIndex:9] componentsSeparatedByString:@" "];
    //This line could be just a bit off...
    NSArray* subarray = [parts subarrayWithRange:NSMakeRange(3, [parts count] - 3)];
    NSDictionary* parsed = @{@"tag": parts[0],
                             @"cipherSuite": parts[1],
                             @"keyParams": parts[2],
                             @"sessionParams": [subarray componentsJoinedByString:@" "]};
    return parsed;
}

+ (NSMutableDictionary*)fingerprintForLine:(NSString*)line {
    NSArray* parts = [[line substringFromIndex:14] componentsSeparatedByString:@" "];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    parsed[@"hash"] = parts[0];
    parsed[@"value"] = parts[1];
    return parsed;
}

+ (NSMutableDictionary*)extMapForLine:(NSString*)line {
    NSMutableArray* parts = [[[line substringFromIndex:9] componentsSeparatedByString:@" "] mutableCopy];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];

    NSString* idPart = [parts jah_popFirstObject];
    NSRange sp = [idPart rangeOfString:@"/"];
    if (sp.location != NSNotFound) {
        parsed[@"id"] = [idPart substringWithRange:NSMakeRange(0, sp.location)];
        parsed[@"senders"] = [idPart substringFromIndex:(sp.location + 1)];
    } else {
        parsed[@"id"] = idPart;
        parsed[@"senders"] = @"sendrecv";
    }

    parsed[@"uri"] = [parts jah_popFirstObject] ?: @"";

    return parsed;
}

+ (NSDictionary*)rtcpfbForLine:(NSString*)line {
    NSMutableArray* parts = [[[line substringFromIndex:10] componentsSeparatedByString:@" "] mutableCopy];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    parsed[@"id"] = [parts jah_popFirstObject];
    parsed[@"type"] = [parts jah_popFirstObject];
    if ([parsed[@"type"] isEqualToString:@"trr-int"]) {
        parsed[@"value"] = [parts jah_popFirstObject];
    } else {
        NSString* subtype = [parts jah_popFirstObject];
        if (subtype) {
            parsed[@"subtype"] = subtype;
        }
    }

    parsed[@"parameters"] = parts;
    return parsed;
}

+ (NSMutableDictionary*)_candidateForLine:(NSString*)line {
    NSArray* parts;
    if ([line hasPrefix:@"a=candidate:"]) {
        parts = [[line substringFromIndex:12] componentsSeparatedByString:@" "];
    } else {
        parts = [[line substringFromIndex:10] componentsSeparatedByString:@" "];
    }

    NSMutableDictionary* candidate = [@{@"foundation": parts[0],
                                        @"component": parts[1],
                                        @"protocol": [parts[2] lowercaseString],
                                        @"priority": parts[3],
                                        @"ip": parts[4],
                                        @"port": parts[5],
                                        // skip parts[6] == 'typ';
                                        @"type": parts[7],
                                        @"generation": @"0"} mutableCopy];

    for (NSUInteger i = 8; i < [parts count]; i = i + 2) {
        if ([parts[i] isEqualToString:@"raddr"]) {
            candidate[@"relAddr"] = parts[i + 1];
        } else if ([parts[i] isEqualToString:@"rport"]) {
            candidate[@"relPort"] = parts[i + 1];
        } else if ([parts[i] isEqualToString:@"generation"]) {
            candidate[@"generation"] = parts[i + 1];
        } else if ([parts[i] isEqualToString:@"tcptype"]) {
            candidate[@"tcpType"] = parts[i + 1];
        }
    }

    candidate[@"network"] = @"1";

    return candidate;
}

+ (NSArray*)sourceGroupsForLines:(NSArray*)lines {
    NSMutableArray* parsed = [NSMutableArray array];
    NSMutableArray* parts;
    for (NSString* line in lines) {
        parts = [[[line substringFromIndex:13] componentsSeparatedByString:@" "] mutableCopy];
        [parsed addObject:@{@"semantics": [parts jah_popFirstObject],
                            @"sources": parts}];
    }
    return parsed;
}

+ (NSArray*)sourcesForLines:(NSArray*)lines {
    // http://tools.ietf.org/html/rfc5576
    NSMutableArray* parsed = [NSMutableArray array];
    NSMutableDictionary* sources = [NSMutableDictionary dictionary];

    for (NSString* line in lines) {
        NSMutableArray* parts = [[[line substringFromIndex:7] componentsSeparatedByString:@" "] mutableCopy];
        NSString* ssrc = [parts jah_popFirstObject];

        if (!sources[ssrc]) {
            NSDictionary* source = @{@"ssrc": ssrc, @"parameters": [NSMutableArray array]};
            [parsed addObject:source];

            // Keep an index
            sources[ssrc] = source;
        }

        parts = [[[parts componentsJoinedByString:@" "] componentsSeparatedByString:@":"] mutableCopy];
        NSString* attribute = [parts jah_popFirstObject];
        NSString* value = [parts componentsJoinedByString:@":"] ?: @"";

        [sources[ssrc][@"parameters"] addObject:@{@"key": attribute,
                                                  @"value": value}];
    }

    return parsed;
}

+ (NSArray*)groupsForLines:(NSArray*)lines {
    // http://tools.ietf.org/html/rfc5888
    NSMutableArray* parsed = [NSMutableArray array];
    NSMutableArray* parts;
    for (NSString* line in lines) {
        parts = [[[line substringFromIndex:8] componentsSeparatedByString:@" "] mutableCopy];
        NSDictionary* group = @{@"semantics":[parts jah_popFirstObject],
                                @"contents": parts};
        [parsed addObject:[group mutableCopy]];
    }
    return parsed;
}

+ (NSDictionary*)bandwidthForLine:(NSString*)line {
    NSMutableArray* parts = [[[line substringFromIndex:2] componentsSeparatedByString:@" "] mutableCopy];
    NSMutableDictionary* parsed = [NSMutableDictionary dictionary];
    parsed[@"type"] = [parts jah_popFirstObject];
    parsed[@"bandwidth"] = [parts jah_popFirstObject];
    return parsed;
}

#pragma mark - Objects -> SDP

+ (NSString*)SDPForSession:(NSDictionary*)session options:(NSDictionary*)options {
    NSString* sid = options[@"sid"];
    if (!sid) {
        sid = session[@"sid"];
    }
    if (!sid) {
        sid = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] * 10];
    }

    NSString* time = options[@"time"];
    if (!time) {
        time = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] * 10];
    }
    NSString* format = [NSString stringWithFormat:@"o=- %@ %@ IN IP4 0.0.0.0", sid, time];

    NSMutableArray* sdp = [NSMutableArray array];
    [sdp addObject:@"v=0"];
    [sdp addObject:format];
    [sdp addObject:@"s=-"];
    [sdp addObject:@"t=0 0"];

    for (NSDictionary* group in session[@"groups"]) {
        [sdp addObject:[NSString stringWithFormat:@"a=group:%@ %@", group[@"semantics"], [group[@"contents"] componentsJoinedByString:@" "]]];
    }

    for (NSDictionary* content in session[@"contents"]) {
        [sdp addObject:[[self class] mediaSDPForContent:content options:options]];
    }

    return [[sdp componentsJoinedByString:@"\r\n"] stringByAppendingString:@"\r\n"];
}

+ (NSString*)mediaSDPForContent:(NSDictionary*)content options:(NSDictionary*)options {
    NSMutableArray* sdp = [NSMutableArray array];

    NSString* role = options[@"role"] ?: @"initiator";
    NSString* direction = options[@"direction"] ?: @"outgoing";

    NSDictionary* desc = content[@"description"];
    NSDictionary* transport = content[@"transport"];

    NSMutableArray* mline = [NSMutableArray array];
    if ([desc[@"descType"] isEqualToString:@"datachannel"]) {
        [mline addObject:@"application"];
        [mline addObject:@"1"];
        [mline addObject:@"DTLS/SCTP"];
        for (NSDictionary* map in transport[@"sctp"]) {
            [mline addObject:map[@"number"]];
        }
    } else {
        [mline addObject:desc[@"media"]];
        [mline addObject:@"1"];
        if (([desc[@"encryption"] count] > 0) || ([transport[@"fingerprints"] count] > 0)) {
            [mline addObject:@"RTP/SAVPF"];
        } else {
            [mline addObject:@"RTP/AVPF"];
        }
        for (NSDictionary* payload in desc[@"payloads"]) {
            [mline addObject:payload[@"id"]];
        }
    }

    [sdp addObject:[NSString stringWithFormat:@"m=%@", [mline componentsJoinedByString:@" "]]];

    [sdp addObject:@"c=IN IP4 0.0.0.0"];
    if (desc[@"bandwidth"][@"type"] && desc[@"bandwidth"][@"bandwidth"]) {
        [sdp addObject:[NSString stringWithFormat:@"b=%@:%@", desc[@"bandwidth"][@"type"], desc[@"bandwidth"][@"bandwidth"]]];
    }
    if ([desc[@"descType"] isEqualToString:@"rtp"]) {
        [sdp addObject:@"a=rtcp:1 IN IP4 0.0.0.0"];
    }

    if (transport) {
        if (transport[@"ufrag"]) {
            [sdp addObject:[NSString stringWithFormat:@"a=ice-ufrag:%@", transport[@"ufrag"]]];
        }
        if (transport[@"pwd"]) {
            [sdp addObject:[NSString stringWithFormat:@"a=ice-pwd:%@", transport[@"pwd"]]];
        }

        BOOL pushedSetup = NO;
        for (NSDictionary* fingerprint in transport[@"fingerprints"]) {
            [sdp addObject:[NSString stringWithFormat:@"a=fingerprint:%@ %@", fingerprint[@"hash"], fingerprint[@"value"]]];
            if (fingerprint[@"setup"] && !pushedSetup) {
                [sdp addObject:[NSString stringWithFormat:@"a=setup:%@", fingerprint[@"setup"]]];
            }
        }

        for (NSDictionary* map in transport[@"sctp"]) {
            [sdp addObject:[NSString stringWithFormat:@"a=sctpmap:%@ %@ %@", map[@"number"], map[@"protocol"], map[@"streams"]]];
        }
    }

    if ([desc[@"descType"] isEqualToString:@"rtp"]) {
        NSDictionary* senders = [JAHSenders senders];
        NSString* sender = senders[role][direction][content[@"senders"]];
        [sdp addObject:[NSString stringWithFormat:@"a=%@", sender]];
    }
    [sdp addObject:[NSString stringWithFormat:@"a=mid:%@", content[@"name"]]];

    if ([(NSNumber*)desc[@"mux"] boolValue]) {
        [sdp addObject:@"a=rtcp-mux"];
    }

    for (NSDictionary* crypto in desc[@"encryption"]) {
        NSString* params = [crypto[@"sessionParams"] length] ? [NSString stringWithFormat:@" %@", crypto[@"sessionsParams"]] : @"";
        [sdp addObject:[NSString stringWithFormat:@"a=crypto:%@ %@ %@%@", crypto[@"tag"], crypto[@"cipherSuite"], crypto[@"keyParams"], params]];
    }

    for (NSDictionary* payload in desc[@"payloads"]) {
        NSString* rtpMap = [NSString stringWithFormat:@"a=rtpmap:%@ %@/%@", payload[@"id"], payload[@"name"], payload[@"clockrate"]];
        if (([payload[@"channels"] length] > 0) && ![payload[@"channels"] isEqualToString:@"1"]) {
            rtpMap = [rtpMap stringByAppendingFormat:@"/%@", payload[@"channels"]];
        }
        [sdp addObject:rtpMap];

        if ([payload[@"parameters"] count]) {
            NSMutableArray* fmtp = [NSMutableArray array];
            [fmtp addObject:[@"a=fmtp:" stringByAppendingString:payload[@"id"]]];
            NSMutableArray* parameters = [NSMutableArray array];
            for (NSDictionary* param in payload[@"parameters"]) {
                NSString* key = param[@"key"] ? [param[@"key"] stringByAppendingString:@"="] : @"";
                [parameters addObject:[key stringByAppendingString:param[@"value"]]];
            }
            [fmtp addObject:[parameters componentsJoinedByString:@";"]];
            [sdp addObject:[fmtp componentsJoinedByString:@" "]];
        }

        for (NSDictionary* fb in payload[@"feedback"]) {
            NSMutableString* rtcp = [NSMutableString stringWithFormat:@"a=rtcp-fb:%@", payload[@"id"]];
            if ([fb[@"type"] isEqualToString:@"trr-int"]) {
                [rtcp appendFormat:@" trr-int %@", fb[@"value"] ?: @"0"];
            } else {
                [rtcp appendFormat:@" %@%@", fb[@"type"], [fb[@"subtype"] length] ? [@" " stringByAppendingString:fb[@"subtype"]] : @""];

            }
            [sdp addObject:rtcp];
        }
    }

    for (NSDictionary* fb in desc[@"feedback"]) {
        NSMutableString* rtcp = [NSMutableString stringWithString:@"a=rtcp-fb:* "];
        if ([fb[@"type"] isEqualToString:@"trr-int"]) {
            [rtcp appendFormat:@"trr-int %@", fb[@"value"] ?: @"0"];
        } else {
            [rtcp appendFormat:@"%@%@", fb[@"type"], [fb[@"subtype"] length] ? [@" " stringByAppendingString:fb[@"subtype"]] : @""];
        }
        [sdp addObject:rtcp];
    }

    for (NSDictionary* hdr in desc[@"headerExtensions"]) {
        NSDictionary* senders = [JAHSenders senders];
        NSMutableString* extMap = [NSMutableString stringWithFormat:@"a=extmap:%@%@ %@", hdr[@"id"], [hdr[@"senders"] length] ? [@"/" stringByAppendingString:senders[role][direction][hdr[@"senders"]]] : @"", hdr[@"uri"]];
        [sdp addObject:extMap];
    }

    for (NSDictionary* ssrcGroup in desc[@"sourceGroups"]) {
        NSMutableString* group = [NSMutableString stringWithFormat:@"a=ssrc-group:%@ %@", ssrcGroup[@"semantics"], [ssrcGroup[@"sources"] componentsJoinedByString:@" "]];
        [sdp addObject:group];
    }

    for (NSDictionary* ssrc in desc[@"sources"]) {
        for (NSDictionary* parameter in ssrc[@"parameters"]) {
            NSMutableString* ssrcString = [NSMutableString stringWithFormat:@"a=ssrc:%@ %@%@", ssrc[@"ssrc"] ?: desc[@"ssrc"], parameter[@"key"], parameter[@"value"] ? [@":" stringByAppendingString:parameter[@"value"]] : @""];
            [sdp addObject:ssrcString];
        }
    }

    for (NSDictionary* candidate in transport[@"candidates"]) {
        [sdp addObject:[[self class] sdpForCandidate:candidate]];
    }

    return [sdp componentsJoinedByString:@"\r\n"];
}

+ (NSString*)sdpForCandidate:(NSDictionary*)candidate {
    NSMutableArray* sdp = [NSMutableArray array];

    [sdp addObject:candidate[@"foundation"]];
    [sdp addObject:candidate[@"component"]];
    [sdp addObject:[candidate[@"protocol"] uppercaseString]];
    [sdp addObject:candidate[@"priority"]];
    [sdp addObject:candidate[@"ip"]];
    [sdp addObject:candidate[@"port"]];

    NSString* type = candidate[@"type"];
    [sdp addObject:@"typ"];
    [sdp addObject:type];
    if ([type isEqualToString:@"srflx"] || [type isEqualToString:@"prflx"] || [type isEqualToString:@"relay"]) {
        if (candidate[@"relAddr"] && candidate[@"relPort"]) {
            [sdp addObject:@"raddr"];
            [sdp addObject:candidate[@"relAddr"]];
            [sdp addObject:@"rport"];
            [sdp addObject:candidate[@"relPort"]];
        }
    }
    if (candidate[@"tcpType"] && [[candidate[@"protocol"] uppercaseString] isEqualToString:@"TCP"]) {
        [sdp addObject:@"tcptype"];
        [sdp addObject:candidate[@"tcpType"]];
    }

    [sdp addObject:@"generation"];
    [sdp addObject:candidate[@"generation"] ?: @"0"];

//    via https://github.com/otalk/sdp-jingle-json/blob/master/lib/tosdp.js#L206
//    FIXME: apparently this is wrong per spec
//    but then, we need this when actually putting this into
//    SDP so it's going to stay.
//    decision needs to be revisited when browsers dont
//    accept this any longer
    return [@"a=candidate:" stringByAppendingString:[sdp componentsJoinedByString:@" "]];
}

@end
