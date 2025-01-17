# IM Demo 介绍

## 使用 SDK 步骤

### iOS:
1. `git clone git@github.com:aopacloud/im-native-sdk.git`
2. 点击 Xcode 工程，设置签名，联系奥帕 IM 团队获取 appid，填入工程，具体见 [wiki](#)。
3. 在 **Build Settings** 中搜索 "Header Search Paths"，添加 framework 的 Headers 目录路径，例如：`$(SRCROOT)/../AopaIMSDK.framework/Headers`。
4. 在 **Build Settings** 中搜索 "Framework Search Paths"，添加正确的路径，例如：`/Users/olaola/Desktop/ola/im-native-sdkcopy/build/ios_arm64/Debug-iphoneos`。
5. 运行 demo 体验私聊、群聊、聊天室。

### Android:
1. `git clone git@github.com:aopacloud/im-native-sdk.git`
2. 打开 Android Studio 工程，联系奥帕 IM 团队获取 appid，填入工程，具体见 [wiki](#)。
3. 运行 demo 体验私聊、群聊、聊天室。

## 使用蒲公英直接安装 App 进行体验

- [iOS 体验版本](https://www.pgyer.com/2DLss9Nd)
- [Android 体验版本](https://www.pgyer.com/0iWuNuao)
