//
//  OSETCustomToBidSplashAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidSplashAdapter.h"

#if DEBUG
/** Demo 状态时间戳，保留六位小数。 */
static NSString *OSETToBidStatusTime(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"HH:mm:ss";
    });
    unsigned long long ticks = (unsigned long long)(NSDate.date.timeIntervalSince1970 * 1000000);
    NSDate *second = [NSDate dateWithTimeIntervalSince1970:ticks / 1000000];
    return [NSString stringWithFormat:@"%@.%06llu", [formatter stringFromDate:second], ticks % 1000000];
}
#endif

#import <WindFoundation/WindFoundation.h>
#import <Adset/OSETSDK.h>
#import "OSETToBidBiddingHelper.h"

@interface OSETCustomToBidSplashAdapter ()<OSETSplashAdDelegate>
@property (nonatomic, weak) id<AWMCustomSplashAdapterBridge> bridge;
@property (atomic, strong) OSETSplashAd *splashAd;
@property (nonatomic, strong) AWMParameter *parameter;
@property (nonatomic, assign) BOOL isReady;
@end

@implementation OSETCustomToBidSplashAdapter
- (instancetype)initWithBridge:(id<AWMCustomSplashAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}
- (BOOL)mediatedAdStatus {
    return self.isReady;
}
- (void)loadAdWithPlacementId:(NSString *)placementId parameter:(AWMParameter *)parameter {
#if DEBUG
    NSLog(@"hh ToBid Splash 原始加载 placementId=%@ channelPlacementId=%@ customInfo=%@", @"<redacted>", @"<redacted>", @"<redacted>");
#endif
    self.isReady = NO;
    self.parameter = parameter;
    NSString *osetSlotId = parameter.placementId;
#if DEBUG
    NSLog(@"hh ToBid 下发 slotId=%@", @"<redacted>");
    NSLog(@"hh 开始加载 奇点广告 slotId=%@", @"<redacted>");
    [[NSUserDefaults standardUserDefaults] setObject:osetSlotId forKey:@"OSETToBidLastSlotId"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
#endif
    self.splashAd = [[OSETSplashAd alloc] initWithSlotId:osetSlotId window:nil bottomView:parameter.extra[WindMillConstant.BottomView]];
    self.splashAd.delegate = self;
    [self.splashAd loadSplashAd];
}
- (void)showSplashAdInWindow:(UIWindow *)window parameter:(AWMParameter *)parameter {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    UIView *bottomView = [parameter.extra objectForKey: WindMillConstant.BottomView];
    self.splashAd.bottomView = bottomView;
    if(window){
        self.splashAd.window = window;
    }else{
        self.splashAd.window = [UIApplication sharedApplication].keyWindow;
    }
    [self.splashAd showSplashAd];


}
- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.splashAd, result);
}
- (void)destory {
    [self removeSplashAdView];
}
- (void)removeSplashAdView {
    self.isReady = NO;
    self.splashAd.delegate = nil;
    self.splashAd = nil;
}
#pragma mark - OSETSplashAdDelegate

- (void)splashDidReceiveSuccess:(id)splashAd slotId:(NSString *)slotId{
    NSString *price = [NSString stringWithFormat:@"%ld",(long)self.splashAd.eCPM];
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge splashAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    self.isReady = YES;
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge splashAdDidLoad:self];
}

- (void)splashLoadToFailed:(id)splashAd error:(NSError *)error{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    self.isReady = NO;
#if DEBUG
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge splashAd:self didLoadFailWithError:error ext:nil];
//    self.splashAd.delegate = nil;
//    self.splashAd = nil;
}

- (void)splashDidClick:(id)splashAd{
//    NSLog(@"OSETSDK click");
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge splashAdDidClick:self];
}

- (void)splashDidClose:(id)splashAd{
//    NSLog(@"OSETSDK close");
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@ ", NSStringFromSelector(_cmd));
#endif
    self.splashAd.delegate = nil;
    self.splashAd = nil;
    [self.bridge splashAdDidClose:self];

}
- (void)splashAdExposured:(id)splashAd{
    [self.bridge splashAdWillVisible:self];
}
- (void)splashWillClose:(id)splashAd{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
}

- (void)dealloc {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
}

@end
