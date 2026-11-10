#import <UIKit/UIKit.h>

UIWindow *TPKeyWindow(void);
UIViewController *TPTopViewController(void);

/// 長按選單的一個項目（自己畫的底部選單，不用系統 UIMenu，避免按鈕被系統動畫隱藏後只剩外框）
@interface TPMenuItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, copy) void (^handler)(void);
+ (instancetype)itemWithTitle:(NSString *)title symbol:(NSString *)symbol handler:(void (^)(void))handler;
@end

@interface TPUI : NSObject
/// 毛玻璃圓形按鈕（影片／圖片上的下載鈕）。tap 為點一下的動作；menuItems 不為空時，長按會跳出底部選單。
+ (UIButton *)circleButtonWithSymbol:(NSString *)symbol
                            diameter:(CGFloat)d
                             onTap:(void (^)(void))tap
                         menuItems:(NSArray<TPMenuItem *> *)menuItems;
+ (void)hapticLight;
+ (void)hapticSuccess;
+ (void)hapticError;
@end
