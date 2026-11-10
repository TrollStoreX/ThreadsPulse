#import <Foundation/Foundation.h>

@interface TPURLCleaner : NSObject
/// 清除追蹤參數，並解開 l.threads.com / l.instagram.com / l.facebook.com 等跳轉包裝。
+ (NSURL *)cleanURL:(NSURL *)url;
/// 清除字串內所有 http(s) 連結的追蹤參數 (用於分享文字、剪貼簿)。
+ (NSString *)cleanString:(NSString *)string;
@end
