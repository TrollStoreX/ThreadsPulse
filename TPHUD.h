#import <UIKit/UIKit.h>

/// 下載進度視窗：毛玻璃卡片 + 圓形進度環，成功／失敗會變成 ✓ / ✕ 並自動消失。
@interface TPHUD : NSObject
+ (instancetype)showWithTitle:(NSString *)title cancel:(void (^)(void))cancel;
- (void)setTitle:(NSString *)title;
- (void)setProgress:(CGFloat)progress subtitle:(NSString *)subtitle;   // progress 0~1
- (void)finishSuccess:(NSString *)message;
- (void)finishFailure:(NSString *)message;
- (void)dismiss;

/// 底部浮出的小提示（毛玻璃膠囊）
+ (void)toast:(NSString *)text;
/// 頂部提示條：文字＋右側動作（點整條都會觸發），5 秒後自動消失；往上滑可關閉
+ (void)bannerWithText:(NSString *)text symbol:(NSString *)symbol action:(NSString *)actionTitle handler:(void (^)(void))handler;
/// position：0 上方、1 中間、2 下方（避開底部分頁列）
+ (void)bannerWithText:(NSString *)text symbol:(NSString *)symbol action:(NSString *)actionTitle
              position:(NSInteger)position handler:(void (^)(void))handler;
@end
