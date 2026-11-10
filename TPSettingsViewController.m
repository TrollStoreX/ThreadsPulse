#import "TPSettingsViewController.h"
#import "TPPrefs.h"
#import "TPDownloader.h"
#import "TPLocalization.h"
#import "TPHUD.h"
#import "TPUI.h"
#import <SafariServices/SafariServices.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "TPVersion.h"
static NSString *const kTPDonateURL = @"https://ko-fi.com/mumuisdog";

#pragma mark - 樣式（F：霧面卡片）

static UIColor *TPDyn(UIColor *light, UIColor *dark) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return t.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light;
    }];
}
/// 頁面底色：深色接近 Threads 的 #101010
static UIColor *TPPageColor(void) {
    return TPDyn([UIColor colorWithWhite:0.96 alpha:1], [UIColor colorWithWhite:0.063 alpha:1]);
}
/// 霧面卡片底色：半透明白（深色）／半透明黑（淺色）
static UIColor *TPCardColor(void) {
    return TPDyn([UIColor colorWithWhite:1 alpha:0.85], [UIColor colorWithWhite:1 alpha:0.08]);
}
static UIColor *TPHairlineColor(void) {
    return TPDyn([UIColor colorWithWhite:0 alpha:0.08], [UIColor colorWithWhite:1 alpha:0.10]);
}
static UIColor *TPKofiColor(void) {
    return [UIColor colorWithRed:1.00 green:0.37 blue:0.36 alpha:1];
}
/// 主題色：珊瑚色（開關、分段選中、完成按鈕、操作文字）
static UIColor *TPAccent(void) {
    return [UIColor colorWithRed:0xD8/255.0 green:0x5A/255.0 blue:0x30/255.0 alpha:1];
}
/// 圖示用的珊瑚色：深色模式稍亮，淺色模式稍深，兩邊都清楚
static UIColor *TPAccentIcon(void) {
    return TPDyn([UIColor colorWithRed:0xC4/255.0 green:0x4F/255.0 blue:0x28/255.0 alpha:1],
                 [UIColor colorWithRed:0xF0/255.0 green:0x99/255.0 blue:0x7B/255.0 alpha:1]);
}

/// 灰色細線條圖示（不再用彩色方塊）
static UIImage *TPLineIcon(NSString *symbol) {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
    return [UIImage systemImageNamed:symbol withConfiguration:cfg] ?: [UIImage systemImageNamed:@"circle" withConfiguration:cfg];
}

static void TPApplyIcon(UIListContentConfiguration *c, NSString *symbol, UIColor *tint) {
    c.image = TPLineIcon(symbol);
    c.imageProperties.tintColor = tint ?: TPAccentIcon();
    c.imageProperties.reservedLayoutSize = CGSizeMake(26, 26);
    c.imageToTextPadding = 12;
}

/// 卡片底：半透明霧面
static void TPApplyCardBackground(UITableViewCell *cell) {
    UIBackgroundConfiguration *bg = [UIBackgroundConfiguration listGroupedCellConfiguration];
    bg.backgroundColor = TPCardColor();
    cell.backgroundConfiguration = bg;
}

/// 「串文時間格式」的範例：以 3 小時前的時間示範三種顯示方式
static NSString *TPTimePreview(NSInteger mode) {
    NSDate *sample = [NSDate dateWithTimeIntervalSinceNow:-3 * 3600 - 17 * 60 - 42];
    NSString *text;
    if (mode == 0) {
        // 用 Threads 自己的相對時間方法（NSDate+RelativeDate），範例才會和串文上的寫法一致，例如「3小時」。
        // 此時設定已是「相對時間」，插件的精確時間 hook 會直接放行原本的結果。
        SEL sel = NSSelectorFromString(@"shortenedFormattedDateRelativeToNow");
        id r = nil;
        if ([sample respondsToSelector:sel]) {
            @try { r = [sample valueForKey:@"shortenedFormattedDateRelativeToNow"]; } @catch (__unused id e) {}
        }
        text = [r isKindOfClass:[NSString class]] && [(NSString *)r length] ? r : TPL(@"3h");
    } else {
        NSDateFormatter *f = [NSDateFormatter new];
        f.locale = NSLocale.autoupdatingCurrentLocale;
        [f setLocalizedDateFormatFromTemplate:(mode == 1 ? @"MMMd HHmm" : @"yMMMd HHmmss")];
        text = [f stringFromDate:sample];
    }
    return [NSString stringWithFormat:TPL(@"Example: %@"), text];
}

#pragma mark - 頂部標題區

@interface TPSettingsHeaderView : UIView
@end

@implementation TPSettingsHeaderView {
    UIView *_badge;
    UIImageView *_glyph;
    UILabel *_title;
    UILabel *_subtitle;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _badge = [UIView new];
        _badge.backgroundColor = UIColor.labelColor;
        _badge.layer.cornerRadius = 12;
        _badge.layer.cornerCurve = kCACornerCurveContinuous;
        [self addSubview:_badge];

        _glyph = [[UIImageView alloc] initWithImage:
                  [UIImage systemImageNamed:@"at"
                          withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightSemibold]]];
        _glyph.tintColor = UIColor.systemBackgroundColor;
        _glyph.contentMode = UIViewContentModeCenter;
        [_badge addSubview:_glyph];

        _title = [UILabel new];
        _title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
        _title.textColor = UIColor.labelColor;
        _title.text = @"ThreadsPulse";
        [self addSubview:_title];

        _subtitle = [UILabel new];
        _subtitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        _subtitle.textColor = UIColor.secondaryLabelColor;
        _subtitle.text = [NSString stringWithFormat:@"%@  ·  %@",
                          [NSString stringWithFormat:TPL(@"Version %@"), TP_VERSION], TPL(@"Enhancements for Threads")];
        [self addSubview:_subtitle];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, inset = 20, d = 44;
    CGFloat y = (self.bounds.size.height - d) / 2 + 4;
    _badge.frame = CGRectMake(inset, y, d, d);
    _glyph.frame = _badge.bounds;
    CGFloat x = CGRectGetMaxX(_badge.frame) + 12;
    _title.frame = CGRectMake(x, y - 1, w - x - inset, 26);
    _subtitle.frame = CGRectMake(x, CGRectGetMaxY(_title.frame) + 1, w - x - inset, 18);
}
@end

#pragma mark - 設定頁

@interface TPSettingsViewController () <UIDocumentPickerDelegate>
@end

@implementation TPSettingsViewController {
    NSArray<NSDictionary *> *_sections;
    CGFloat _headerWidth;
}

+ (void)present {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *top = TPTopViewController();
        if (!top) return;
        if ([top isKindOfClass:[UINavigationController class]] &&
            [[(UINavigationController *)top viewControllers].firstObject isKindOfClass:self]) return; // 已開啟
        TPSettingsViewController *vc = [[self alloc] initWithStyle:UITableViewStyleInsetGrouped];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
        nav.navigationBar.tintColor = TPAccent();
        nav.view.tintColor = TPAccent();
        if (@available(iOS 15.0, *)) {
            nav.sheetPresentationController.detents = @[UISheetPresentationControllerDetent.largeDetent];
            nav.sheetPresentationController.prefersGrabberVisible = YES;
        }
        [top presentViewController:nav animated:YES completion:nil];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = nil;
    // 完成按鈕：明確指定顏色，不沿用 Threads 的全域色調（深色模式下是黑色，看不清楚）
    // Threads 會用全域外觀改掉導覽列按鈕的顏色（淺色模式甚至看不見），所以自己畫：珊瑚色圓底＋白色勾勾，圖片固定顏色不受影響
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(0, 0, 32, 32);
    doneButton.backgroundColor = TPAccent();
    doneButton.layer.cornerRadius = 16;
    UIImage *check = [[UIImage systemImageNamed:@"checkmark"
                               withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold]]
                      imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [doneButton setImage:check forState:UIControlStateNormal];
    doneButton.accessibilityLabel = TPL(@"Done");
    [doneButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [doneButton.widthAnchor constraintEqualToConstant:32].active = YES;
    [doneButton.heightAnchor constraintEqualToConstant:32].active = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
    self.navigationController.navigationBar.tintColor = TPAccent();
    self.view.tintColor = TPAccent();
    self.tableView.backgroundColor = TPPageColor();
    self.tableView.separatorColor = TPHairlineColor();
    self.tableView.sectionHeaderTopPadding = 6;

    // TP_MODEL_BEGIN — 這裡的文字都是「英文 key」，顯示時才經 TPL() 轉成目前語系
    _sections = @[
        @{ @"header": @"Ads & Privacy",
           @"footer": @"Turning ad blocking on or off takes effect after refreshing the feed or restarting the app.",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyBlockAds, @"title": @"Block Ads",
                  @"detail": @"Hide sponsored posts in the feed",
                  @"icon": @"shield", @"color": UIColor.systemRedColor },
               @{ @"type": @"switch", @"key": TPKeyStripTracking, @"title": @"Remove URL Tracking",
                  @"detail": @"Automatically strip xmt, igshid, utm_* and more when copying, sharing or opening links",
                  @"icon": @"link", @"color": UIColor.systemBlueColor },
           ]},
        @{ @"header": @"Clipboard Links",
           @"footer": @"Auto-open reads the clipboard directly. If iOS asks to allow pasting every time, go to Settings › Threads › Paste from Other Apps and choose Allow.",
           @"footerIf": @[@[TPKeyClipboardLinks, @1], @[TPKeyClipboardMode, @1]],
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyClipboardLinks, @"title": @"Detect Copied Links",
                  @"detail": @"When you come back or switch accounts, detect a copied Threads link and open it",
                  @"icon": @"doc.on.clipboard", @"color": UIColor.labelColor },
               @{ @"type": @"segment", @"key": TPKeyClipboardMode, @"title": @"When a Link Is Found", @"detail": @"",
                  @"icon": @"hand.tap", @"color": UIColor.labelColor,
                  @"segments": @[@"Ask", @"Auto-open"], @"showIf": @[TPKeyClipboardLinks, @1] },
               @{ @"type": @"segment", @"key": TPKeyBannerPosition, @"title": @"Prompt Position", @"detail": @"",
                  @"icon": @"rectangle.topthird.inset.filled", @"color": UIColor.labelColor,
                  @"segments": @[@"Top", @"Middle", @"Bottom"], @"showIf": @[@[TPKeyClipboardLinks, @1], @[TPKeyClipboardMode, @0]] },
           ]},
        @{ @"header": @"Download",
           @"footer": @"If the original size isn't available, the regular size is downloaded.\nTo save a profile picture, long-press it on a profile, or open it full screen and tap ↓ in the bottom-right corner.",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyShowDownloadBtn, @"title": @"Download Button",
                  @"detail": @"Long-press: choose photos or videos only\nTap: download all photos and videos",
                  @"icon": @"arrow.down.circle", @"color": UIColor.systemGreenColor },
               @{ @"type": @"switch", @"key": TPKeyOriginalImage, @"title": @"Download Original Size",
                  @"icon": @"photo", @"color": UIColor.systemTealColor },
               @{ @"type": @"switch", @"key": TPKeyOriginalAvatar, @"title": @"Download Original Profile Pictures",
                  @"icon": @"person.crop.circle", @"color": UIColor.labelColor },
           ]},
        @{ @"header": @"Home Feed",
           @"footer": @"With everything here turned on, new posts only load after you fully close and reopen Threads.",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyKeepFeed, @"title": @"Keep Feed Position",
                  @"detail": @"Coming back from the background won't refresh the home feed, jump to the top or switch tabs",
                  @"icon": @"pin", @"color": UIColor.labelColor },
               @{ @"type": @"segment", @"key": TPKeyKeepFeedLimit, @"title": @"Keep For", @"detail": @"",
                  @"icon": @"timer", @"color": UIColor.labelColor,
                  @"segments": @[@"10 min", @"30 min", @"No Limit"], @"showIf": @[TPKeyKeepFeed, @1],
                  @"note": @"If you're away longer than this, the feed refreshes as usual" },
               @{ @"type": @"switch", @"key": TPKeyNoPullRefresh, @"title": @"Disable Pull to Refresh",
                  @"detail": @"Pulling down at the top of the home feed won't refresh it, and the feed stops at the top without bouncing",
                  @"icon": @"arrow.down.to.line", @"color": UIColor.labelColor },
               @{ @"type": @"switch", @"key": TPKeyTabNoScrollTop, @"title": @"Home Tab: Don't Scroll to Top",
                  @"detail": @"When you're scrolled down the home feed, tapping the Home tab won't jump back to the top, so you stay where you were",
                  @"icon": @"arrow.up.to.line", @"color": UIColor.labelColor },
               @{ @"type": @"switch", @"key": TPKeyTabNoRefresh, @"title": @"Home Tab: Don't Refresh",
                  @"detail": @"When you're already at the top of the home feed, tapping the Home tab won't refresh or load new posts",
                  @"icon": @"arrow.clockwise", @"color": UIColor.labelColor },
           ]},
        @{ @"header": @"Interface",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyPinTabBar, @"title": @"Keep Tab Bar Visible",
                  @"detail": @"Scrolling won't hide the tab bar at the bottom; it always stays on screen",
                  @"icon": @"dock.rectangle", @"color": UIColor.labelColor },
               @{ @"type": @"switch", @"key": TPKeyHideFollowSuggest, @"title": @"Hide Follow Suggestions",
                  @"detail": @"Stop the \"Suggested for you\" sheet from popping up",
                  @"icon": @"person.badge.plus", @"color": UIColor.labelColor },
               @{ @"type": @"switch", @"key": TPKeyCopyProfile, @"title": @"Copy Profile Info",
                  @"detail": @"On a profile, long-press the name, username, bio or profile picture to copy the name, username or bio",
                  @"icon": @"doc.on.doc", @"color": UIColor.labelColor },
           ]},
        @{ @"header": @"Video",
           @"footer": @"Videos play at this speed by default, and return to it after you let go of a long-press 2x.",
           @"rows": @[
               @{ @"type": @"segment", @"key": TPKeyPlaySpeed, @"title": @"Default Playback Speed", @"detail": @"",
                  @"icon": @"speedometer", @"color": UIColor.labelColor,
                  @"segments": @[@"1x", @"1.25x", @"1.5x", @"2x"] },
           ]},
        @{ @"header": @"Interactions",
           @"footer": @"Ask before a like is sent, to prevent accidental taps. Removing a like won't ask.",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeyConfirmLike, @"title": @"Like Confirmation", @"detail": @"",
                  @"icon": @"heart", @"color": UIColor.labelColor },
           ]},
        @{ @"header": @"Time",
           @"rows": @[
               @{ @"type": @"segment", @"key": TPKeyExactTime, @"title": @"Post Time Format", @"detail": @"",
                  @"icon": @"clock", @"color": UIColor.labelColor,
                  @"segments": @[@"Relative", @"Date & Time", @"With Seconds"], @"preview": @"time" },
           ]},
        @{ @"header": @"Backup",
           @"footer": @"Export your settings to a file, and import it after reinstalling or on another device.",
           @"rows": @[
               @{ @"type": @"action", @"action": @"export", @"title": @"Export Settings", @"detail": @"",
                  @"icon": @"square.and.arrow.up", @"color": UIColor.systemCyanColor },
               @{ @"type": @"action", @"action": @"import", @"title": @"Import Settings", @"detail": @"",
                  @"icon": @"square.and.arrow.down", @"color": UIColor.systemCyanColor },
           ]},
        @{ @"header": @"Advanced",
           @"footer": @"Turn on when a feature stops working. Hints show which features are active, to help report problems.",
           @"rows": @[
               @{ @"type": @"switch", @"key": TPKeySideloadFix, @"title": @"Sideload Compatibility Fix",
                  @"detail": @"Keeps you signed in and app group data working after re-signing. Only active on re-signed apps; takes effect after reopening Threads",
                  @"icon": @"key", @"color": UIColor.labelColor },
               @{ @"type": @"switch", @"key": TPKeyDebugToast, @"title": @"Debug Hints", @"detail": @"",
                  @"icon": @"ladybug", @"color": UIColor.systemGrayColor },
           ]},
        @{ @"header": @"Donate",
           @"footer": @"Your support keeps ThreadsPulse updated. Thank you!",
           @"rows": @[
               @{ @"type": @"link", @"url": kTPDonateURL, @"title": @"Buy Me a Coffee",
                  @"detail": @"Support ThreadsPulse on Ko-fi",
                  @"icon": @"cup.and.saucer.fill", @"color": UIColor.labelColor },
           ]},
    ];
    // TP_MODEL_END
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.tableView.bounds.size.width;
    if (w > 0 && w != _headerWidth) {          // 寬度改變才重設，避免無限重排
        _headerWidth = w;
        self.tableView.tableHeaderView = [[TPSettingsHeaderView alloc] initWithFrame:CGRectMake(0, 0, w, 84)];
    }
}

- (void)close { [self dismissViewControllerAnimated:YES completion:nil]; }

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return _sections.count + 1; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s < (NSInteger)_sections.count ? [self visibleRowsInSection:s].count : 2;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    return TPL(s < (NSInteger)_sections.count ? _sections[s][@"header"] : @"About");
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)s {
    if (s >= (NSInteger)_sections.count) return @"Made by h4x_0x30vm";
    NSString *f = _sections[s][@"footer"];
    if (!TPConditionMet(_sections[s][@"footerIf"])) return nil;
    return f.length ? TPL(f) : nil;
}

/// 條件格式：@[key, 值]，或多個條件 @[@[key, 值], @[key, 值]]（全部成立才算）
static NSArray<NSArray *> *TPConditions(NSArray *cond) {
    if (cond.count == 2 && [cond[0] isKindOfClass:[NSString class]]) return @[cond];
    return cond ?: @[];
}
static BOOL TPConditionMet(NSArray *cond) {
    for (NSArray *c in TPConditions(cond))
        if ([TPPrefs integerForKey:c[0]] != [c[1] integerValue]) return NO;
    return YES;
}
static BOOL TPConditionUsesKey(NSArray *cond, NSString *key) {
    for (NSArray *c in TPConditions(cond)) if ([c[0] isEqualToString:key]) return YES;
    return NO;
}

/// 這個區塊目前要顯示的列（有 showIf 的列，只在條件成立時顯示）
- (NSArray<NSDictionary *> *)visibleRowsInSection:(NSInteger)s {
    NSMutableArray *out = [NSMutableArray array];
    for (NSDictionary *row in _sections[s][@"rows"]) {
        if (!TPConditionMet(row[@"showIf"])) continue;
        [out addObject:row];
    }
    return out;
}

- (NSDictionary *)rowAt:(NSIndexPath *)ip { return [self visibleRowsInSection:ip.section][ip.row]; }

/// 某個設定改變後，依賴它的列要顯示或隱藏（例如「提示位置」只在「詢問」時出現）
- (void)refreshConditionalRowsForKey:(NSString *)key {
    for (NSInteger sec = 0; sec < (NSInteger)_sections.count; sec++) {
        BOOL affected = TPConditionUsesKey(_sections[sec][@"footerIf"], key);
        for (NSDictionary *row in _sections[sec][@"rows"])
            if (TPConditionUsesKey(row[@"showIf"], key)) affected = YES;
        if (affected)
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sec]
                          withRowAnimation:UITableViewRowAnimationFade];
    }
}

/// F2 樣式：標題在上、分段按鈕在下，整列是一張霧面卡片
- (UITableViewCell *)segmentCellForRow:(NSDictionary *)row {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    TPApplyCardBackground(cell);
    UIView *cv = cell.contentView;

    UIImageView *icon = [[UIImageView alloc] initWithImage:TPLineIcon(row[@"icon"])];
    icon.tintColor = TPAccentIcon();
    icon.contentMode = UIViewContentModeCenter;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [cv addSubview:icon];

    UILabel *title = [UILabel new];
    title.text = TPL(row[@"title"]);
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    title.textColor = UIColor.labelColor;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [cv addSubview:title];

    NSArray<NSString *> *segs = row[@"segments"];
    NSMutableArray<NSString *> *labels = [NSMutableArray array];
    for (NSString *seg in segs) [labels addObject:TPL(seg)];
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:labels];
    NSInteger cur = MAX(0, MIN([TPPrefs integerForKey:row[@"key"]], (NSInteger)segs.count - 1));
    sc.selectedSegmentIndex = cur;
    sc.backgroundColor = TPDyn([UIColor colorWithWhite:0 alpha:0.05], [UIColor colorWithWhite:1 alpha:0.06]);
    sc.selectedSegmentTintColor = TPAccent();
    [sc setTitleTextAttributes:@{ NSForegroundColorAttributeName: UIColor.secondaryLabelColor,
                                  NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightMedium] }
                      forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{ NSForegroundColorAttributeName: UIColor.whiteColor,
                                  NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold] }
                      forState:UIControlStateSelected];
    NSString *key = row[@"key"];
    UILabel *preview = nil;
    if ([row[@"preview"] isEqualToString:@"time"]) {
        preview = [UILabel new];
        preview.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
        preview.textColor = UIColor.secondaryLabelColor;
        preview.text = TPTimePreview(cur);
        preview.translatesAutoresizingMaskIntoConstraints = NO;
        [cv addSubview:preview];
    }
    if (!preview && [row[@"note"] length]) {                 // 分段選項下方的固定說明
        preview = [UILabel new];
        preview.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        preview.textColor = UIColor.secondaryLabelColor;
        preview.numberOfLines = 0;
        preview.text = TPL(row[@"note"]);
        preview.translatesAutoresizingMaskIntoConstraints = NO;
        [cv addSubview:preview];
    }
    BOOL isTimePreview = [row[@"preview"] isEqualToString:@"time"];
    __weak UILabel *wp = isTimePreview ? preview : nil;
    __weak typeof(self) weakSelf = self;
    [sc addAction:[UIAction actionWithHandler:^(UIAction *a) {
        NSInteger idx = ((UISegmentedControl *)a.sender).selectedSegmentIndex;
        [TPPrefs setInteger:idx forKey:key];
        [TPUI hapticLight];
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf refreshConditionalRowsForKey:key]; });
        if (wp) {
            [UIView transitionWithView:wp duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{ wp.text = TPTimePreview(idx); } completion:nil];
        }
    }] forControlEvents:UIControlEventValueChanged];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [cv addSubview:sc];

    UILayoutGuide *m = cv.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [icon.widthAnchor constraintEqualToConstant:26],
        [icon.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:12],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:m.trailingAnchor],
        [title.topAnchor constraintEqualToAnchor:cv.topAnchor constant:14],
        [sc.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [sc.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [sc.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
        [sc.heightAnchor constraintEqualToConstant:32],
    ]];
    if (preview) {
        [NSLayoutConstraint activateConstraints:@[
            [preview.topAnchor constraintEqualToAnchor:sc.bottomAnchor constant:10],
            [preview.leadingAnchor constraintEqualToAnchor:m.leadingAnchor constant:2],
            [preview.trailingAnchor constraintLessThanOrEqualToAnchor:m.trailingAnchor],
            [preview.bottomAnchor constraintEqualToAnchor:cv.bottomAnchor constant:-14],
        ]];
    } else {
        [sc.bottomAnchor constraintEqualToAnchor:cv.bottomAnchor constant:-14].active = YES;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    // ---- 關於 ----
    if (ip.section >= (NSInteger)_sections.count) {
        if (ip.row == 0) {
            UIListContentConfiguration *c = [UIListContentConfiguration valueCellConfiguration];
            c.text = TPL(@"Version");
            c.secondaryText = TP_VERSION;
            TPApplyIcon(c, @"info.circle", nil);
            cell.contentConfiguration = c;
            TPApplyCardBackground(cell);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            UIListContentConfiguration *c = [UIListContentConfiguration cellConfiguration];
            c.text = TPL(@"Reset All Settings");
            c.textProperties.color = UIColor.systemRedColor;
            TPApplyIcon(c, @"arrow.counterclockwise", UIColor.systemRedColor);
            cell.contentConfiguration = c;
            TPApplyCardBackground(cell);
        }
        return cell;
    }

    NSDictionary *row = [self rowAt:ip];
    NSString *type = row[@"type"];
    if ([type isEqualToString:@"segment"]) return [self segmentCellForRow:row];
    NSString *detail = row[@"detail"];

    UIListContentConfiguration *c = detail.length ? [UIListContentConfiguration subtitleCellConfiguration]
                                                  : [UIListContentConfiguration cellConfiguration];
    c.text = TPL(row[@"title"]);
    if (detail.length) {
        c.secondaryText = TPL(detail);
        c.secondaryTextProperties.color = UIColor.secondaryLabelColor;
        c.secondaryTextProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        c.textToSecondaryTextVerticalPadding = 3;
    }
    TPApplyIcon(c, row[@"icon"], nil);
    TPApplyCardBackground(cell);

    if ([type isEqualToString:@"switch"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UISwitch *sw = [UISwitch new];
        sw.onTintColor = TPAccent();
        sw.on = [TPPrefs boolForKey:row[@"key"]];
        sw.tag = ip.section * 100 + ip.row;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
    } else if ([type isEqualToString:@"link"]) {
        UIBackgroundConfiguration *bg = [UIBackgroundConfiguration listGroupedCellConfiguration];
        bg.backgroundColor = [TPKofiColor() colorWithAlphaComponent:0.12];
        bg.strokeColor = [TPKofiColor() colorWithAlphaComponent:0.40];
        bg.strokeWidth = 0.5;
        cell.backgroundConfiguration = bg;
        c.imageProperties.tintColor = TPKofiColor();
        UIImageView *arrow = [[UIImageView alloc] initWithImage:
            [UIImage systemImageNamed:@"chevron.right"
                    withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightBold]]];
        arrow.tintColor = UIColor.tertiaryLabelColor;
        cell.accessoryView = arrow;
    }
    cell.contentConfiguration = c;
    return cell;
}

- (void)switchChanged:(UISwitch *)sw {
    NSInteger s = sw.tag / 100, r = sw.tag % 100;
    NSString *key = [self visibleRowsInSection:s][r][@"key"];
    [TPPrefs setBool:sw.on forKey:key];
    [TPUI hapticLight];
    dispatch_async(dispatch_get_main_queue(), ^{ [self refreshConditionalRowsForKey:key]; });
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    UITableViewCell *cell = [tv cellForRowAtIndexPath:ip];

    if (ip.section >= (NSInteger)_sections.count) {
        if (ip.row == 1) [self confirmReset];
        return;
    }
    NSDictionary *row = [self rowAt:ip];
    NSString *type = row[@"type"];
    if ([type isEqualToString:@"action"]) {
        if ([row[@"action"] isEqualToString:@"export"]) [self exportSettingsFrom:cell];
        else [self importSettings];
    } else if ([type isEqualToString:@"link"]) {
        [self openLink:row[@"url"]];
    }
}

#pragma mark - 贊助連結

- (void)openLink:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    SFSafariViewController *sf = [[SFSafariViewController alloc] initWithURL:url];
    sf.preferredControlTintColor = TPKofiColor();
    sf.dismissButtonStyle = SFSafariViewControllerDismissButtonStyleClose;
    [self presentViewController:sf animated:YES completion:nil];
}

#pragma mark - 重設

- (void)confirmReset {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:TPL(@"Reset All Settings?") message:nil
                                                        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:TPL(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:TPL(@"Reset") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
        [TPPrefs resetAll];
        [self.tableView reloadData];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - 匯出／匯入

- (void)exportSettingsFrom:(UIView *)source {
    NSData *data = [TPPrefs exportJSONData];
    NSURL *file = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"ThreadsPulse-Settings.json"]];
    if (!data || ![data writeToURL:file atomically:YES]) {
        [TPHUD toast:TPL(@"Export failed")];
        return;
    }
    UIActivityViewController *av = [[UIActivityViewController alloc] initWithActivityItems:@[file] applicationActivities:nil];
    av.popoverPresentationController.sourceView = source;
    av.popoverPresentationController.sourceRect = source.bounds;
    [self presentViewController:av animated:YES completion:nil];
}

- (void)importSettings {
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON] asCopy:YES];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSData *data = urls.firstObject ? [NSData dataWithContentsOfURL:urls.firstObject] : nil;
    NSInteger n = [TPPrefs importJSONData:data];
    [self.tableView reloadData];
    if (n < 0) { [TPUI hapticError];   [TPHUD toast:TPL(@"Invalid settings file")]; }
    else       { [TPUI hapticSuccess]; [TPHUD toast:[NSString stringWithFormat:TPL(@"Imported %ld settings"), (long)n]]; }
}
@end
