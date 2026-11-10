#import "TPLocalization.h"
#import <dlfcn.h>

static NSBundle *TPBundle(void) {
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithArray:@[
            @"/var/jb/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle",  // 無根越獄
            @"/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle",         // 有根越獄
        ]];

        // 側載：bundle 放在 App 內（與 dylib 同層或 Frameworks 內）
        NSString *inApp = [NSBundle.mainBundle pathForResource:@"ThreadsPulse" ofType:@"bundle"];
        if (inApp) [paths addObject:inApp];
        [paths addObject:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Frameworks/ThreadsPulse.bundle"]];

        Dl_info info;
        if (dladdr((const void *)&TPBundle, &info) && info.dli_fname) {
            NSString *dir = [[NSString stringWithUTF8String:info.dli_fname] stringByDeletingLastPathComponent];
            [paths addObject:[dir stringByAppendingPathComponent:@"ThreadsPulse.bundle"]];
        }

        for (NSString *p in paths) {
            if ([NSFileManager.defaultManager fileExistsAtPath:p]) {
                bundle = [NSBundle bundleWithPath:p];
                if (bundle) break;
            }
        }
    });
    return bundle;
}

NSString *TPLocalized(NSString *key) {
    NSBundle *b = TPBundle();
    if (!b) return key;
    return [b localizedStringForKey:key value:key table:nil];
}
