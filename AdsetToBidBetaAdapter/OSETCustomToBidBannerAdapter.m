//
//  OSETCustomToBidBannerAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidBannerAdapter.h"

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

@interface  OSETCustomToBidBannerAdapter()<OSETBannerAdDelegate>
@property (nonatomic, weak) id<AWMCustomBannerAdapterBridge> bridge;
@property (atomic,strong) OSETBannerAd *bannerAd;
@property (atomic,strong)OSETBaseView * view;
@property (nonatomic, assign) BOOL isReady;
@end

@implementation OSETCustomToBidBannerAdapter
- (instancetype)initWithBridge:(id<AWMCustomBannerAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}
- (void)loadAdWithPlacementId:(NSString *)placementId parameter:(AWMParameter *)parameter {
#if DEBUG
    NSLog(@"hh ToBid Banner 原始加载 placementId=%@ channelPlacementId=%@ customInfo=%@", @"<redacted>", @"<redacted>", @"<redacted>");
#endif
    self.isReady = NO;
    self.view = nil;
    NSString *sizeStr = [parameter.customInfo objectForKey:@"adSize"];
    CGSize adSize = CGSizeFromString(sizeStr);
    UIViewController *viewController = [self.bridge viewControllerForPresentingModalView];
    if (CGSizeEqualToSize(CGSizeZero, adSize)) {
        adSize = CGSizeMake(viewController.view.frame.size.width, 80);
    }else{
        if(adSize.width > viewController.view.frame.size.width){
            adSize.width = viewController.view.frame.size.width;
        }
        if(adSize.width < 100){
            adSize.width = 100;
        }
        if(adSize.height < 80){
            adSize.height = 80;
        }
    }
    NSString *osetSlotId = parameter.placementId;
#if DEBUG
    NSLog(@"hh ToBid 下发 slotId=%@", @"<redacted>");
    NSLog(@"hh ToBidBeta 开始加载 奇点 广告 slotId=%@", @"<redacted>");
#endif
    self.bannerAd = [[OSETBannerAd alloc]initWithSlotId:osetSlotId  rootViewController:viewController rect:CGRectMake(0, 0, adSize.width, adSize.height)];
    self.bannerAd.delegate = self;
    [self.bannerAd loadAdData];
}
- (BOOL)mediatedAdStatus {
    return self.isReady;
}
- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.view, result);
}
- (void)destory {
    self.isReady = NO;
    self.bannerAd.delegate = nil;
    self.bannerAd = nil;
    self.view = nil;
}

- (void)bannerDidReceiveSuccess:(id)bannerView slotId:(NSString *)slotId{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    if (![bannerView isKindOfClass:[OSETBaseView class]]) {
        return;
    }
    OSETBaseView * view = bannerView;
    if([bannerView isKindOfClass:[UIView class]]){
        view.frame = CGRectMake(0,0, view.frame.size.width,view.frame.size.height);
    }
    // bridge 可能同步触发竞价结果，必须先保存绑定当前请求的 View。
    self.view = view;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)view.eCPM];
    [self.bridge bannerAd:self didAdServerResponse:view ext:@{
        WindMillConstant.ECPM : price
    }];
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    if (self.view != view) {
        return;
    }
#if DEBUG
    NSLog(@"hh ToBid 广告加载成功 size:%@ subviews:%@", NSStringFromCGSize(view.bounds.size), @"<redacted>");
#endif
    self.isReady = YES;
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge bannerAd:self didLoad:view];
}
/// banner加载失败
- (void)bannerLoadToFailed:(id)bannerView error:(NSError *)error{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    self.isReady = NO;
#if DEBUG
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge bannerAd:self didLoadFailWithError:error ext:nil];
}
-(void)bannerDidClick:(id)bannerView{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    [self.bridge bannerAdDidClick:self bannerView:bannerView];

}
-(void)bannerDidClose:(id)bannerView{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    [self.bridge bannerAdDidClosed:self bannerView:bannerView];

}
- (void)bannerDidExposures:(id)banner{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%s", __func__);
#endif
    [self.bridge bannerAdDidBecomeVisible:self bannerView:banner];
}

@end
