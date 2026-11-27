//
//  OSETCustomToBidNativeAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidNativeAdapter.h"

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

#import "OSETNativeAdViewCreator.h"
#import <WindFoundation/WindFoundation.h>
#import "OSETCustomToBidNativeAdData.h"
#import <Adset/OSETSDK.h>
#import "OSETToBidBiddingHelper.h"
@interface OSETCustomToBidNativeAdapter ()<OSETNativeAdDelegate,OSETNativeDataAdDelegate,OSETNativeAdViewCreatorDelegate>
@property (nonatomic, weak) id<AWMCustomNativeAdapterBridge> bridge;
@property (atomic,strong) OSETNativeAd *nativeAd;
@property (atomic,strong) OSETNativeDataAd *nativeDataAd;
@property (atomic, strong) id biddingAd;
@property (nonatomic, assign) BOOL isExpressAd;

@end

@implementation OSETCustomToBidNativeAdapter
- (instancetype)initWithBridge:(id<AWMCustomNativeAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}

- (void)loadAdWithPlacementId:(NSString *)placementId adSize:(CGSize)size parameter:(AWMParameter *)parameter {
#if DEBUG
    NSLog(@"hh ToBid Native 原始加载 placementId=%@ channelPlacementId=%@ customInfo=%@ extra=%@", @"<redacted>", @"<redacted>", @"<redacted>", @"<redacted>");
#endif
    self.biddingAd = nil;
    NSDictionary *customInfo = [parameter.customInfo isKindOfClass:NSDictionary.class] ? parameter.customInfo : nil;
    id express = customInfo[@"isExpressAd"];
    self.isExpressAd = [express respondsToSelector:@selector(boolValue)] && [express boolValue];
#if DEBUG
    NSLog(@"hh ToBid Native isExpressAd=%d", self.isExpressAd);
#endif
    // 获取特定键的值
    if (self.isExpressAd) {
        if(!self.nativeAd){
            NSString *osetSlotId = placementId;
#if DEBUG
    NSLog(@"hh ToBid 下发 slotId=%@", @"<redacted>");
            NSLog(@"hh 开始加载 奇点广告 slotId=%@", @"<redacted>");
    [[NSUserDefaults standardUserDefaults] setObject:osetSlotId forKey:@"OSETToBidLastSlotId"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
#endif
            self.nativeAd = [[OSETNativeAd alloc] initWithSlotId:osetSlotId size:size rootViewController:nil];
            self.nativeAd.delegate = self;
            [self.nativeAd loadAdData];
        }else{
            self.nativeAd.delegate = self;
            [self.nativeAd loadAdData];
        }

    }else{
        if(!self.nativeDataAd){
            NSString *osetSlotId = placementId;
#if DEBUG
    NSLog(@"hh ToBid 下发 slotId=%@", @"<redacted>");
            NSLog(@"hh 开始加载 奇点广告 slotId=%@", @"<redacted>");
    [[NSUserDefaults standardUserDefaults] setObject:osetSlotId forKey:@"OSETToBidLastSlotId"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
#endif
            self.nativeDataAd = [[OSETNativeDataAd alloc]initWithSlotId:osetSlotId size:size rootViewController:nil];
            self.nativeDataAd.delegate = self;
            [self.nativeDataAd loadAdData];
        }else{
            self.nativeDataAd.delegate = self;
            [self.nativeDataAd loadAdData];
        }
    }
}

- (BOOL)mediatedAdStatus {
    return YES;
}

- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.biddingAd, result);
}


- (void)destory {
    self.nativeAd.delegate = nil;
    self.nativeDataAd.delegate = nil;
    self.nativeAd = nil;
    self.nativeDataAd = nil;
    self.biddingAd = nil;
}

/// 信息流加载成功
- (void)nativeDataAdLoadSuccessWithNative:(id)nativeDataAd nativeDataObjects:(NSArray<OSETNativeDataAdObject *> * _Nullable)nativeDataObjects{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    OSETNativeDataAd *loadedAd = self.nativeDataAd;
    if (self.isExpressAd || nativeDataAd != loadedAd || !loadedAd) {
        return;
    }
    OSETNativeDataAdObject *adData = [nativeDataObjects isKindOfClass:[NSArray class]]
        ? nativeDataObjects.firstObject : nil;
    if (![adData isKindOfClass:[OSETNativeDataAdObject class]]) {
#if DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
        [self.bridge nativeAd:self didLoadFailWithError:[NSError errorWithDomain:@"OSETToBidAdapter"
            code:-1 userInfo:@{NSLocalizedDescriptionKey: @"OSET 自渲染信息流返回空广告"}]];
        return;
    }
    self.biddingAd = loadedAd;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adData.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    if (self.biddingAd != loadedAd) {
        return;
    }
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    OSETNativeAdViewCreator * creator = [[OSETNativeAdViewCreator alloc] initWithNativeDataAdAd:loadedAd adData:adData];
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] initWithData:[[OSETCustomToBidNativeAdData alloc]initWithAd:adData] viewCreator:creator originAd:adData];
    creator.delegate = self;
    [adArray addObject:mNativeAd];
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge nativeAd:self didLoadWithNativeAds:adArray];
}
/// 加载失败
/// @param nativeDataAd 信息流实例
/// @param error 错误信息
- (void)nativeDataAdFailedToLoad:(id)nativeDataAd error:(NSError *)error{
#if DEBUG
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge nativeAd:self didLoadFailWithError:error];
}


- (void)nativeExpressAdLoadSuccessWithNative:(id)native nativeExpressViews:(NSArray *)nativeExpressViews{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    OSETNativeAd *loadedAd = self.nativeAd;
    if (!self.isExpressAd || native != loadedAd || !loadedAd) {
        return;
    }
    OSETBaseView *adView = [nativeExpressViews isKindOfClass:[NSArray class]]
        ? nativeExpressViews.firstObject : nil;
    if (![adView isKindOfClass:[OSETBaseView class]]) {
#if DEBUG
        [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
        [self.bridge nativeAd:self didLoadFailWithError:[NSError errorWithDomain:@"OSETToBidAdapter"
            code:-1 userInfo:@{NSLocalizedDescriptionKey: @"OSET 模板信息流返回空广告或无效 View"}]];
        return;
    }
    // bridge 可能同步触发竞价结果，先保存当前广告 View。
    self.biddingAd = adView;
    NSString *price = [NSString stringWithFormat:@"%ld",(long)adView.eCPM];
    [self.bridge nativeAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    if (self.biddingAd != adView) {
        return;
    }
    NSMutableArray *adArray = [[NSMutableArray alloc] init];
    loadedAd.delegate = self;
    // 按 ToBid 官方示例明确回传模板类型，避免按普通图片处理。
    OSETCustomToBidNativeAdData *data = [OSETCustomToBidNativeAdData new];
    data.adMode = AWMMediatedNativeAdModeNativeExpress;
    data.adType = AWMNativeAdSlotAdTypeFeed;
    AWMMediatedNativeAd *mNativeAd = [[AWMMediatedNativeAd alloc] initWithData:data viewCreator:[[OSETNativeAdViewCreator alloc] initWithExpressAd:loadedAd adView:adView] originAd:adView];
    mNativeAd.view = adView;
    [adArray addObject:mNativeAd];
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge nativeAd:self didLoadWithNativeAds:adArray];
}

- (void)nativeExpressAdRenderSuccess:(id)nativeExpressView{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    if([nativeExpressView isKindOfClass:[UIView class]]){
        [self.bridge nativeAd:self renderSuccessWithExpressView:nativeExpressView];
    }else{
    }
}
- (void)nativeExpressAdFailedToLoad:(nonnull id)nativeExpressAd error:(nonnull NSError *)error {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge nativeAd:self didLoadFailWithError:error];

}
- (void)nativeExpressAdFailedToRender:(nonnull id)nativeExpressView {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge nativeAd:self renderFailWithExpressView:nativeExpressView andError:[NSError new]];

}
- (void)nativeExpressAdDidClick:(nonnull id)nativeExpressView {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:nativeExpressView];

}
- (void)nativeExpressAdDidClose:(nonnull id)nativeExpressView {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge nativeAd:self didClose:nativeExpressView closeReasons:@[]];
}

- (void)nativeExpressAdDidExposured:(id)nativeExpressView{
    if([nativeExpressView isKindOfClass:[UIView class]]){
        UIView * v = nativeExpressView;
        if(v.superview){
            CGRect r = v.superview.frame;
            v.superview.frame = CGRectMake(r.origin.x, r.origin.y, v.bounds.size.width, v.bounds.size.height);
        }
    }
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:nativeExpressView];
}
/**
 广告曝光回调
 */
- (void)OSETNativeAdViewCreatorWillExpose:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:renderer.dataObject];
}
/**
 广告点击回调
 */
- (void)OSETNativeAdViewCreatorDidClick:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:renderer.dataObject];
}

/**
 广告关闭回调
 */
- (void)OSETNativeAdViewCreatorDidClose:(OSETNativeAdRenderer *)renderer{
    [self.bridge nativeAd:self didClose:renderer.dataObject closeReasons:@[]];
}

/**
 广告详情页关闭回调
 */
- (void)OSETNativeAdViewCreatorDetailViewClosed:(OSETNativeAdRenderer *)renderer{

}
-(void)dealloc{
//    NSLog(@"dealloc ====  %@", @"<redacted>");
}
@end
