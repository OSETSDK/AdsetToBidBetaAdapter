//
//  OSETCustomToBidInitAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidInitAdapter.h"

#import <Adset/OSETSDK.h>

@interface OSETCustomToBidInitAdapter ()
@property (nonatomic, weak) id<AWMCustomConfigAdapterBridge> bridge;
@end

@implementation OSETCustomToBidInitAdapter
- (instancetype)initWithBridge:(id<AWMCustomConfigAdapterBridge>)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}
- (AWMCustomAdapterVersion *)basedOnCustomAdapterVersion {
    return  [AWMCustomAdapterVersion V2_0];
}
- (NSString *)adapterVersion {
    return @"8.0.0.0";
}
- (NSString *)networkSdkVersion {
    return [OSETManager version];
}
/** 初始化 OSET SDK，配置就绪后把结果交给 ToBid。 */
- (void)initializeAdapterWithConfiguration:(AWMSdkInitConfig *)initConfig {
    NSDictionary *extra = [initConfig.extra isKindOfClass:NSDictionary.class] ? initConfig.extra : nil;
    NSString *appId = [extra[@"appId"] isKindOfClass:NSString.class] ? extra[@"appId"] : nil;
    // 兼容平台后台两种字段名；优先使用非空 appId。
    if (!appId.length) {
        appId = [extra[@"app_id"] isKindOfClass:NSString.class] ? extra[@"app_id"] : nil;
    }
    if (!appId.length) {
        NSError *error = [NSError errorWithDomain:@"OSETToBidAdapter" code:70001
                                        userInfo:@{NSLocalizedDescriptionKey: @"初始化 appId 为空"}];
        [self.bridge initializeAdapterFailed:self error:error];
        return;
    }

    [OSETManager configureWithAppId:appId completion:^(BOOL success, NSError *error) {
        if (success) {
            [self.bridge initializeAdapterSuccess:self];
        } else {
            NSError *failure = error ?: [NSError errorWithDomain:@"OSETToBidAdapter" code:70001
                                                        userInfo:@{NSLocalizedDescriptionKey: @"SDK 初始化失败"}];
            [self.bridge initializeAdapterFailed:self error:failure];
        }
    }];
}

- (void)didRequestAdPrivacyConfigUpdate:(NSDictionary *)config {
    WindMillPersonalizedAdvertisingState state = [WindMillAds getPersonalizedAdvertisingState];
    [OSETManager shareInstance].isEnablePersonalAds = (state == WindMillPersonalizedAdvertisingStateOn);
}
@end
