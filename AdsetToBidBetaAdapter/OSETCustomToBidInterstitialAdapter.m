//
//  OSETCustomToBidInterstitialAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidInterstitialAdapter.h"

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

@interface OSETCustomToBidInterstitialAdapter ()<OSETInterstitialAdDelegate>
@property (nonatomic, weak) id<AWMCustomInterstitialAdapterBridge> bridge;
@property (atomic, strong) OSETInterstitialAd *interstitialAd;
@property (nonatomic, strong) AWMParameter *parameter;
@property (nonatomic, assign) BOOL isReady;
@end

@implementation OSETCustomToBidInterstitialAdapter
- (instancetype)initWithBridge:(id<AWMCustomInterstitialAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}
- (BOOL)mediatedAdStatus {
    if(self.interstitialAd && self.interstitialAd.isAdValid){
        return self.interstitialAd.isAdValid;
    }
    return NO;
}

- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.interstitialAd, result);
}
- (void)destory {
    [self removeInterstitialAd];
}
- (void)removeInterstitialAd {
    self.interstitialAd.delegate = nil;
    self.interstitialAd = nil;
}
- (void)loadAdWithPlacementId:(NSString *)placementId parameter:(AWMParameter *)parameter {
#if DEBUG
    NSLog(@"hh ToBid Interstitial 原始加载 placementId=%@ channelPlacementId=%@ customInfo=%@", @"<redacted>", @"<redacted>", @"<redacted>");
#endif
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
    self.interstitialAd = [[OSETInterstitialAd alloc] initWithSlotId:osetSlotId];
    self.interstitialAd.delegate = self;
    [self.interstitialAd loadInterstitialAdData];
#if DEBUG
    WindmillLogDebug(@"OSET-WindWill--loadInterstitialAdData",@"%@",NSStringFromSelector(_cmd));
#endif
}
/// 展示广告的方法
/// @param viewController 控制器对象
/// @param parameter 展示广告的参数，由ToBid接入媒体配置
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController parameter:(AWMParameter *)parameter{
#if DEBUG
    WindmillLogDebug(@"OSET-WindWill", @"%@", NSStringFromSelector(_cmd));
#endif
    if(self.interstitialAd.isAdValid && viewController){
        [self.interstitialAd showInterstitialFromRootViewController:viewController];
        return YES;
    }
    return NO;
}
- (void)interstitialDidReceiveSuccess:(nonnull id)interstitialAd slotId:(nonnull NSString *)slotId {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    NSString *price = [NSString stringWithFormat:@"%ld",(long)self.interstitialAd.eCPM];
    [self.bridge interstitialAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge interstitialAdDidLoad:self];
}

- (void)interstitialLoadToFailed:(nonnull id)interstitialAd error:(nonnull NSError *)error {
#if DEBUG
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge interstitialAd:self didLoadFailWithError:error ext:@{}];
}

- (void)interstitialDidClick:(nonnull id)interstitialAd {
    [self.bridge interstitialAdDidClick:self];
}

- (void)interstitialDidClose:(nonnull id)interstitialAd {
    [self.bridge interstitialAdDidClose:self];
}
- (void)interstitialExposured:(id)interstitialAd{
    [self.bridge interstitialAdDidVisible:self];
}
@end
