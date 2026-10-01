# TikTok Web for HarmonyOS

基于 HarmonyOS NEXT、ArkTS 和 ArkWeb 的非官方 TikTok 网页容器，默认打开 TikTok 官方网站。

## 导入与构建

1. 使用 DevEco Studio 打开项目目录。
2. 安装与 build-profile.json5 中兼容版本及目标版本匹配的 HarmonyOS SDK。
3. 同步项目后，选择 Build HAP 或运行 entry 模块。
4. 未配置签名时，HAP 位于 entry/build/default/outputs/default/entry-default-unsigned.hap，可使用 HoKit 签名后安装。

本机的 local.properties、签名文件、构建缓存和安装包不提交到 Git；安装包通过 GitHub Releases 提供。

## 当前功能

- 网页占满内容区，手机、平板和小窗使用同一窗口布局。
- 左下角悬浮菜单提供返回、前进、刷新，系统返回键优先回退网页历史。
- 原生界面与系统栏跟随系统深浅色；同步 TikTok 的 data-theme 和 data-tux-color-scheme 属性。
- 在不超过 600px 的网页视口内，调整主内容和视频卡片的最小宽度，为右侧操作按钮保留空间。
- 网页延伸到底部手势区域，菜单与系统栏保持避让。
- 加载进度和主页面加载失败重试。
- 开启 JavaScript 和 DOM 存储，关闭文件访问和地理位置访问。

## 网页适配与验证范围

WebAdapter.ets 中的脚本仅在 www.tiktok.com 和 tiktok.com 执行，使用网站现有主题属性和窄窗布局 CSS。适配不读取登录凭据、Cookie 或账户数据。

浏览器中已验证真实网页的深浅色切换与 390px 主内容宽度；按网站实际布局约束构造的页面已检查 320、390、540px 的视频/操作区边界。该检查不代表已验证真实视频流的全部页面。系统手势条、安全区、视频全屏和悬浮菜单仍需要 HarmonyOS 真机验证。

网页适配依赖 TikTok 当前的页面结构。登录、视频播放和加载速度由 TikTok 网站、网络及设备的 ArkWeb 能力共同决定。本项目不包含 TikTok 私有 API 或内容下载功能。