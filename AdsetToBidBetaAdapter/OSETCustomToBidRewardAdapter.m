//
//  OSETCustomToBidRewardAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidRewardAdapter.h"

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
    self.parameter = parameter;
    WindMillAdRequest *request = [self.bridge adRequest];
    NSString *osetSlotId = parameter.placementId;
    NSString *userId = [request.userId isKindOfClass:NSString.class] ? request.userId : @"";
    self.rewardAd = [[OSETRewardVideoAd alloc] initWithSlotId:osetSlotId withUserId:userId];
    self.rewardAd.delegate = self;
    [self.rewardAd loadRewardAdData];

}

/// 展示广告的方法
/// @param viewController 控制器对象
/// @param parameter 展示广告的参数，由ToBid接入媒体配置
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController parameter:(AWMParameter *)parameter{
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
    NSString *price = [NSString stringWithFormat:@"%ld",(long)self.rewardAd.eCPM];
    [self.bridge rewardedVideoAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    [self.bridge rewardedVideoAdDidLoad:self];
}

- (void)rewardVideoLoadToFailed:(nonnull id)rewardVideoAd error:(nonnull NSError *)error {
    [self.bridge rewardedVideoAd:self didLoadFailWithError:error ext:nil];
}

- (void)rewardVideoDidClick:(nonnull id)rewardVideoAd {
    [self.bridge rewardedVideoAdDidClick:self];
}
/// 激励视频关闭
- (void)rewardVideoDidClose:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
    [self.bridge rewardedVideoAdDidClose:self];
}
//激励视频播放结束
- (void)rewardVideoPlayEnd:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:nil];

}
//激励视频播放出错
- (void)rewardVideoPlayError:(id)rewardVideoAd error:(NSError *)error{
    [self.bridge rewardedVideoAd:self didPlayFinishWithError:error];
}
//激励视频开始播放
- (void)rewardVideoPlayStart:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
    [self.bridge rewardedVideoAdDidVisible:self];

}
/** 转发奖励回调。 */
- (void)rewardVideoOnReward:(OSETRewardVideoAd *)rewardVideoAd checkString:(NSString *)checkString {
    if (!rewardVideoAd.verify) { return; }
    WindMillRewardInfo *info = [[WindMillRewardInfo alloc] initWithIsCompeltedView:YES];
    [self.bridge rewardedVideoAd:self didRewardSuccessWithInfo:info];
}

@end
