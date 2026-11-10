#import <Foundation/Foundation.h>

/// 以英文原文當作 key，從 ThreadsPulse.bundle 取得對應語系的字串。
/// 找不到 bundle 或該 key 時，直接回傳 key 本身（英文）。
NSString *TPLocalized(NSString *key);
#define TPL(key) TPLocalized(key)
