//
//  OSETCustomToBidRewardAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidRewardAdapter.h"

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
@interface OSETCustomToBidRewardAdapter ()<OSETRewardVideoAdDelegate>
@property (nonatomic, weak) id<AWMCustomRewardedVideoAdapterBridge> bridge;
@property (atomic, strong) OSETRewardVideoAd *rewardAd;
@property (nonatomic, strong) AWMParameter *parameter;
@property (nonatomic, assign) BOOL isReady;
@end

@implementation OSETCustomToBidRewardAdapter
- (instancetype)initWithBridge:(id<AWMCustomRewardedVideoAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}
- (BOOL)mediatedAdStatus {
    if(self.rewardAd && self.rewardAd.isAdValid){
        return self.rewardAd.isAdValid;
    }
    return NO;
}
- (void)loadAdWithPlacementId:(NSString *)placementId parameter:(AWMParameter *)parameter {
#if DEBUG
    NSLog(@"hh ToBid Reward 原始加载 placementId=%@ channelPlacementId=%@ customInfo=%@", @"<redacted>", @"<redacted>", @"<redacted>");
#endif
    self.parameter = parameter;
    WindMillAdRequest *request = [self.bridge adRequest];
    NSString *osetSlotId = parameter.placementId;
#if DEBUG
    NSLog(@"hh ToBid 下发 slotId=%@", @"<redacted>");
    NSLog(@"hh 开始加载 奇点广告 slotId=%@", @"<redacted>");
    [[NSUserDefaults standardUserDefaults] setObject:osetSlotId forKey:@"OSETToBidLastSlotId"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"加载中" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
#endif
    NSString *userId = [request.userId isKindOfClass:NSString.class] ? request.userId : @"";
    self.rewardAd = [[OSETRewardVideoAd alloc] initWithSlotId:osetSlotId withUserId:userId];
    self.rewardAd.delegate = self;
    [self.rewardAd loadRewardAdData];

}

/// 展示广告的方法
/// @param viewController 控制器对象
/// @param parameter 展示广告的参数，由ToBid接入媒体配置
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController parameter:(AWMParameter *)parameter{
#if DEBUG
    WindmillLogDebug(@"OSET-WindWill", @"%@", NSStringFromSelector(_cmd));
#endif
    if(self.rewardAd.isAdValid  && viewController){
        [self.rewardAd showRewardFromRootViewController:viewController];
        return YES;
    }
    return NO;
}

- (void)didReceiveBidResult:(AWMMediaBidResult *)result {
    OSETToBidReportBidResult(self.rewardAd, result);
}
- (void)destory {
    [self removeRewardAd];
}
- (void)removeRewardAd {
    self.rewardAd.delegate = nil;
    self.rewardAd = nil;
}

- (void)rewardVideoDidReceiveSuccess:(nonnull id)rewardVideoAd slotId:(nonnull NSString *)slotId {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    NSString *price = [NSString stringWithFormat:@"%ld",(long)self.rewardAd.eCPM];
    [self.bridge rewardedVideoAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge rewardedVideoAdDidLoad:self];
}


- (void)rewardVideoLoadToFailed:(nonnull id)rewardVideoAd error:(nonnull NSError *)error {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
    NSLog(@"hh 奇点广告 加载失败：errorCode=%ld", (long)error.code);
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidPlatformLoadStatus"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidPlatformLoadTime"];
    [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidLoadTime"];
#endif
    [self.bridge rewardedVideoAd:self didLoadFailWithError:error ext:nil];
}

- (void)rewardVideoDidClick:(nonnull id)rewardVideoAd {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge rewardedVideoAdDidClick:self];
}
/// 激励视频关闭
- (void)rewardVideoDidClose:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge rewardedVideoAdDidClose:self];
}
//激励视频播放结束
- (void)rewardVideoPlayEnd:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:nil];

}
//激励视频播放出错
- (void)rewardVideoPlayError:(id)rewardVideoAd error:(NSError *)error{
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:error];
}
//激励视频开始播放
- (void)rewardVideoPlayStart:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    [self.bridge rewardedVideoAdDidVisible:self];

}
/** 转发奖励回调。 */
- (void)rewardVideoOnReward:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
    if (!rewardVideoAd.verify) { return; }
#if DEBUG
    WindmillLogDebug(@"OSET", @"%@", NSStringFromSelector(_cmd));
#endif
    WindMillRewardInfo *info = [[WindMillRewardInfo alloc] initWithIsCompeltedView:YES];
    [self.bridge rewardedVideoAd:self didRewardSuccessWithInfo:info];
}


@end
