# TikTok Web for HarmonyOS

一个基于 HarmonyOS NEXT、ArkTS 和 ArkWeb 的轻量网页容器示例，默认打开 TikTok 官方网站。

## 导入

1. 使用 DevEco Studio 打开本目录。
2. 安装与项目 `compatibleSdkVersion` 对应的 HarmonyOS SDK。
3. 等待项目同步后，在模拟器或 HarmonyOS 真机上运行 `entry`。

网页容器需要 `ohos.permission.INTERNET`。登录、视频播放以及站点功能由 TikTok 网站和设备上的 ArkWeb 能力决定。

## 当前功能

- 打开 `https://www.tiktok.com/`
- 原生返回、前进、刷新按钮
- 系统返回键优先回退网页历史
- 加载进度和主页面加载错误提示
- 开启 JavaScript 和 DOM 存储，关闭文件访问和地理位置访问

这是一个非官方网页容器示例，不包含 TikTok 私有 API、内容下载或网页脚本注入。
