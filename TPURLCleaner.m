#import "TPURLCleaner.h"
#import "TPPrefs.h"

@implementation TPURLCleaner

+ (NSSet<NSString *> *)exactParams {
    static NSSet *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [NSSet setWithArray:@[
            // Threads / Instagram / Meta
            @"xmt", @"slof", @"igshid", @"igsh", @"ig_rid", @"ig_mid", @"ig_cache_key",
            @"fbclid", @"mibextid", @"__tn__", @"__cft__", @"__xts__", @"fb_action_ids",
            @"fb_source", @"ref_src", @"ref_url",
            // 常見第三方
            @"gclid", @"gclsrc", @"dclid", @"msclkid", @"twclid", @"yclid", @"_hsenc", @"_hsmi",
            @"mc_cid", @"mc_eid", @"si"
        ]];
    });
    return s;
}

+ (BOOL)isTrackingParam:(NSString *)name {
    NSString *n = name.lowercaseString;
    if ([[self exactParams] containsObject:n]) return YES;
    if ([n hasPrefix:@"utm_"]) return YES;
    return NO;
}

+ (BOOL)isRedirectHost:(NSString *)host {
    static NSSet *hosts;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        hosts = [NSSet setWithArray:@[
            @"l.threads.com", @"l.threads.net", @"l.instagram.com",
            @"l.facebook.com", @"lm.facebook.com"
        ]];
    });
    return [hosts containsObject:host.lowercaseString];
}

+ (NSURL *)cleanURL:(NSURL *)url {
    if (![TPPrefs boolForKey:TPKeyStripTracking]) return url;
    if (![url isKindOfClass:[NSURL class]]) return url;

    NSString *scheme = url.scheme.lowercaseString;
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) return url;

    NSURLComponents *c = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if (!c) return url;

    // 1) 解開跳轉包裝 (https://l.threads.com/?u=<真正網址>&e=<追蹤碼>)
    if ([self isRedirectHost:c.host]) {
        for (NSURLQueryItem *item in c.queryItems) {
            if ([item.name isEqualToString:@"u"] && item.value.length) {
                NSURL *inner = [NSURL URLWithString:item.value];
                if (inner) return [self cleanURL:inner];   // 內層網址也要清一次
            }
        }
        return url;
    }

    // 2) 移除追蹤參數
    if (c.queryItems.count) {
        NSMutableArray<NSURLQueryItem *> *kept = [NSMutableArray array];
        BOOL changed = NO;
        for (NSURLQueryItem *item in c.queryItems) {
            if ([self isTrackingParam:item.name]) { changed = YES; continue; }
            [kept addObject:item];
        }
        if (!changed) return url;
        c.queryItems = kept.count ? kept : nil;   // 全部移除時連 "?" 也不留
    }
    return c.URL ?: url;
}

+ (NSString *)cleanString:(NSString *)string {
    if (![TPPrefs boolForKey:TPKeyStripTracking]) return string;
    if (![string isKindOfClass:[NSString class]] || string.length < 8) return string;
    if ([string rangeOfString:@"http"].location == NSNotFound) return string;

    static NSDataDetector *det;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        det = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    });

    NSMutableString *out = [string mutableCopy];
    NSArray *matches = [det matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *m in [matches reverseObjectEnumerator]) {   // 由後往前替換，range 不會位移
        NSURL *u = m.URL;
        if (!u) continue;
        NSURL *cleaned = [self cleanURL:u];
        if (cleaned && ![cleaned isEqual:u]) {
            [out replaceCharactersInRange:m.range withString:cleaned.absoluteString];
        }
    }
    return out;
}
@end
