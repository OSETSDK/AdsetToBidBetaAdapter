//
//  OSETCustomToBidSplashAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidSplashAdapter.h"

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
    self.isReady = NO;
    self.parameter = parameter;
    NSString *osetSlotId = parameter.placementId;
    self.splashAd = [[OSETSplashAd alloc] initWithSlotId:osetSlotId window:nil bottomView:parameter.extra[WindMillConstant.BottomView]];
    self.splashAd.delegate = self;
    [self.splashAd loadSplashAd];
}
- (void)showSplashAdInWindow:(UIWindow *)window parameter:(AWMParameter *)parameter {
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
    [self.bridge splashAd:self didAdServerResponseWithExt:@{
        WindMillConstant.ECPM : price
    }];
    self.isReady = YES;
    [self.bridge splashAdDidLoad:self];
}

- (void)splashLoadToFailed:(id)splashAd error:(NSError *)error{
    self.isReady = NO;
    [self.bridge splashAd:self didLoadFailWithError:error ext:nil];
//    self.splashAd.delegate = nil;
//    self.splashAd = nil;
}

- (void)splashDidClick:(id)splashAd{
//    NSLog(@"OSETSDK click");
    [self.bridge splashAdDidClick:self];
}

- (void)splashDidClose:(id)splashAd{
//    NSLog(@"OSETSDK close");
    self.splashAd.delegate = nil;
    self.splashAd = nil;
    [self.bridge splashAdDidClose:self];

}
- (void)splashAdExposured:(id)splashAd{
    [self.bridge splashAdWillVisible:self];
}
- (void)splashWillClose:(id)splashAd{
}

- (void)dealloc {
}

@end
