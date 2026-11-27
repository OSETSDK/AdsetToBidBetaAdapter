//
//  OSETCustomToBidInitAdapter.m
//  YhsADSProject
//
//  Created by Shens on 9/7/2025.
//

#import "OSETCustomToBidInitAdapter.h"

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
#if DEBUG
    NSLog(@"hh ToBidBeta 桥接成功");
#endif
    NSDictionary *extra = [initConfig.extra isKindOfClass:NSDictionary.class] ? initConfig.extra : nil;
    NSString *appId = [extra[@"appId"] isKindOfClass:NSString.class] ? extra[@"appId"] : nil;
    // 兼容平台后台两种字段名；优先使用非空 appId。
    if (!appId.length) {
        appId = [extra[@"app_id"] isKindOfClass:NSString.class] ? extra[@"app_id"] : nil;
    }
#if DEBUG
    NSLog(@"hh ToBid 初始化原始 extra=%@", @"<redacted>");
    NSLog(@"hh ToBid 下发 appId=%@", @"<redacted>");
    NSLog(@"hh 开始初始化 奇点 appId=%@", @"<redacted>");
#endif
    if (!appId.length) {
        NSError *error = [NSError errorWithDomain:@"OSETToBidAdapter" code:70001
                                        userInfo:@{NSLocalizedDescriptionKey: @"初始化 appId 为空"}];
        [self.bridge initializeAdapterFailed:self error:error];
        return;
    }

    [OSETManager configureWithAppId:appId completion:^(BOOL success, NSError *error) {
        if (success) {
#if DEBUG
            NSLog(@"hh 奇点初始化 成功");
            [[NSUserDefaults standardUserDefaults] setObject:@"成功" forKey:@"OSETToBidInitStatus"];
            [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidInitTime"];
            [[NSUserDefaults standardUserDefaults] setObject:appId forKey:@"OSETToBidAppKey"];
#endif
            [self.bridge initializeAdapterSuccess:self];
        } else {
#if DEBUG
            NSLog(@"hh 奇点初始化 失败：errorCode=%ld", (long)error.code);
            [[NSUserDefaults standardUserDefaults] setObject:@"失败" forKey:@"OSETToBidInitStatus"];
            [[NSUserDefaults standardUserDefaults] setObject:OSETToBidStatusTime() forKey:@"OSETToBidInitTime"];
            [[NSUserDefaults standardUserDefaults] setObject:appId forKey:@"OSETToBidAppKey"];
#endif
            NSError *failure = error ?: [NSError errorWithDomain:@"OSETToBidAdapter" code:70001
                                                        userInfo:@{NSLocalizedDescriptionKey: @"SDK 初始化失败"}];
            [self.bridge initializeAdapterFailed:self error:failure];
        }
    }];
}

- (void)didRequestAdPrivacyConfigUpdate:(NSDictionary *)config {
    WindMillPersonalizedAdvertisingState personalizedAdvertisingState = [WindMillAds getPersonalizedAdvertisingState];
}
@end
