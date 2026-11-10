#import "TPLocalization.h"
#import <dlfcn.h>

static NSBundle *TPBundle(void);   // 前置宣告，下面用 &TPBundle 取 dylib 位址

/// 從 dylib 自身位置推導越獄根目錄（jbroot）。
///   RootHide：/var/containers/.../jbroot-XXXX/Library/MobileSubstrate/DynamicLibraries/ThreadsPulse.dylib
///   無根越獄：/var/jb/Library/MobileSubstrate/DynamicLibraries/ThreadsPulse.dylib
/// 兩者都是「<jbroot>/Library/MobileSubstrate/DynamicLibraries」，截掉尾巴就是根目錄，
/// 不需要連結 libroothide，也不依賴寫死的 /var/jb。
static NSString *TPJailbreakRoot(void) {
    static NSString *root;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Dl_info info;
        if (!dladdr((const void *)&TPBundle, &info) || !info.dli_fname) return;
        NSString *dir = [NSString stringWithUTF8String:info.dli_fname].stringByDeletingLastPathComponent;
        NSRange r = [dir rangeOfString:@"/Library/MobileSubstrate/DynamicLibraries"];
        if (r.location != NSNotFound) {
            root = [dir substringToIndex:r.location];
        }
    });
    return root;
}

static NSBundle *TPBundle(void) {
    static NSBundle *bundle;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithArray:@[
            @"/var/jb/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle",  // 無根越獄
            @"/Library/Application Support/ThreadsPulse/ThreadsPulse.bundle",         // 有根越獄
        ]];

        // RootHide（jbroot 每次越獄都是隨機目錄名，只能從 dylib 位置推導）
        NSString *jbroot = TPJailbreakRoot();
        if (jbroot.length) {
            [paths insertObject:[jbroot stringByAppendingPathComponent:
                @"Library/Application Support/ThreadsPulse/ThreadsPulse.bundle"] atIndex:0];
        }

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
