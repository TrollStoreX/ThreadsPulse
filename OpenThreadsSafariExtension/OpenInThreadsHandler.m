// Safari 網頁延伸功能的原生端。
// 實際工作（把 threads.com 網址轉成 barcelona:// 並開啟 Threads）都在 Resources/content.js；
// 這裡只負責回應 Safari 的訊息，讓延伸功能能被載入。
#import <Foundation/Foundation.h>

@interface OpenInThreadsHandler : NSObject <NSExtensionRequestHandling>
@end

@implementation OpenInThreadsHandler
- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    [context completeRequestReturningItems:@[] completionHandler:nil];
}
@end
