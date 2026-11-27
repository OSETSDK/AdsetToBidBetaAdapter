# AdsetToBidBetaAdapter

Adset 的 ToBid Beta 适配器。版本 `8.0.0.0`，最低支持 iOS 13.0。

## Pod 接入

[Git 仓库](https://github.com/OSETSDK/AdsetToBidBetaAdapter) · [Podspec](https://github.com/OSETSDK/AdsetToBidBetaAdapter/blob/main/AdsetToBidBetaAdapter.podspec)

在 Podfile 中配置提供 Adset 正式版本的 Specs 源，并通过适配器 Git 地址和版本 tag 接入：

```ruby
source 'https://github.com/OSETSDK/Adset.git'
source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'
use_frameworks! :linkage => :static

target 'YourApp' do
  pod 'Adset', '>= 8.0.0.0'
  pod 'AdsetToBidBetaAdapter', :git => 'https://github.com/OSETSDK/AdsetToBidBetaAdapter.git', :tag => '8.0.0.0'
end
```

## 依赖

| Pod | 最低版本 |
| --- | --- |
| [Adset](https://github.com/OSETSDK/Adset) | `8.0.0.0` |
| `ToBid-iOS-Beta` | `5.2.0` |

## 自定义 ADN 配置

a01、在 ToBid 后台创建或选择 iOS 应用，进入聚合工具的自定义广告网络管理，添加“奇点”，按下表填写 iOS 适配器类名。

a02、广告网络 App ID 填奇点媒体 App ID；初始化 extra 支持 `appId` 和 `app_id`，两者同时存在时优先非空 `appId`。奇点初始化不需要 App Key。

a03、创建或选择聚合广告位，添加奇点广告源；渠道代码位 ID 填奇点对应格式的广告位 ID，适配器从 `AWMParameter.placementId` 读取。

a04、信息流模板在广告源自定义参数中配置 `isExpressAd: true`；自渲染设为 false 或不填。应用通过 ToBid 聚合广告位 ID 请求广告。

| 用途 | iOS 适配器类名 |
| --- | --- |
| 初始化 | `OSETCustomToBidInitAdapter` |
| 开屏 | `OSETCustomToBidSplashAdapter` |
| 插屏 | `OSETCustomToBidInterstitialAdapter` |
| 激励视频 | `OSETCustomToBidRewardAdapter` |
| Banner | `OSETCustomToBidBannerAdapter` |
| 信息流模板／自渲染 | `OSETCustomToBidNativeAdapter` |

类名不加 `.h`／`.m` 后缀。平台自身 App ID／App Key 用于初始化聚合平台，与奇点渠道参数分别配置。

模板广告源参数示例（自渲染设为 false 或省略该字段）：

```json
{ "isExpressAd": true }
```

后台操作参考 [第三方 ADN 接入说明](https://doc.shenshiads.com/IOS.html#tobid适配器接入)，Pod 名称和参数兼容规则以本文为准。

## 使用要求

- 宿主保留 `-ObjC` 链接参数，按平台文档完成聚合 SDK 初始化。
- 加载成功后再展示；在主线程传入有效的控制器或窗口。
- ToBid 正式版、Beta、RC 适配器仅选择与宿主 SDK 对应的一套。

许可证：[Apache 2.0](LICENSE)。
