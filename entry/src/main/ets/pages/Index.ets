import { connection } from '@kit.NetworkKit';
import { saveWebSession } from '../common/WebSession';
import { webview } from '@kit.ArkWeb';
import { createWebAdapterScript } from '../common/WebAdapter';

const TIKTOK_URL: string = 'https://www.tiktok.com/';
// Exact tablet browser UA supplied by the user on 2026-10-02.
// This is a compatibility profile, not a claim about other devices' engine versions.
const HARMONY_BROWSER_UA: string = 'Mozilla/5.0 (Tablet; OpenHarmony 7.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36  ArkWeb/7.0.0.107 HuaweiBrowser/6.1.8.301';

PersistentStorage.persistProp('desktopMode', false);

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private controllerReady: boolean = false;
  private popupController: webview.WebviewController = new webview.WebviewController();
  @State private popupOpen: boolean = false;
  @State private popupAddress: string = '';
  @State private popupFailed: boolean = false;
  @State private popupProgress: number = 0;
  @State private networkDetail: string = '';
  @State private diagnosticsOpen: boolean = false;
  private cookieTimer: number = -1;
  private networkTimer: number = -1;
  private popupReady: boolean = false;
  @State private networkState: string = '尚未读取';

  private syncNetworkState(): void {
    try {
      // navigator.onLine describes network availability, not reachability of TikTok.
      // Do not force online: real disconnections must still reach the page.
      const available = connection.hasDefaultNetSync();
      this.networkState = available ? '系统网络已连接' : '系统网络已断开';
      if (this.controllerReady) { this.controller.setNetworkAvailable(available); }
      if (this.popupOpen && this.popupReady) { this.popupController.setNetworkAvailable(available); }
    } catch { this.networkState = '无法读取系统网络状态'; }
  }


  onPageShow(): void {
    this.syncNetworkState();
    if (this.networkTimer < 0) {
      this.networkTimer = setInterval(() => this.syncNetworkState(), 2000);
    }
    if (this.cookieTimer < 0) {
      // SPA login can set cookies without a navigation/page-end event.
      this.cookieTimer = setInterval(() => saveWebSession(), 15000);
    }
  }

  onPageHide(): void {
    this.stopCookieTimer();
    saveWebSession();
  }

  aboutToDisappear(): void {
    this.stopCookieTimer();
    saveWebSession();
  }

  private stopCookieTimer(): void {
    if (this.networkTimer >= 0) { clearInterval(this.networkTimer); }
    this.networkTimer = -1;
    if (this.cookieTimer >= 0) { clearInterval(this.cookieTimer); }
    this.cookieTimer = -1;
  }

  private recordNetworkError(address: string, code: number, source: string): void {
    // Keep only the host: URLs can contain OAuth codes or account information.
    const host = address.match(/^https?:\/\/([^/?#]+)/);
    if (!host) { return; }
    const detail = source + ' · ' + code + ' · ' + host[1];
    this.networkDetail = (detail + '\n' + this.networkDetail).split('\n').slice(0, 6).join('\n');
  }


  private closePopup(): void {
    saveWebSession();
    this.popupOpen = false;
    this.popupReady = false;
    this.menuOpen = false;
    // Keep the opener alive: the callback can notify it via postMessage.
    this.updateNavigationState();
  }

  private popupBack(): void {
    try {
      if (this.popupController.accessBackward()) {
        this.popupController.backward();
        return;
      }
    } catch {}
    this.closePopup();
  }


  @StorageLink('systemDark') @Watch('onSystemThemeChanged') private isDark: boolean = false;
  @StorageLink('windowTopInset') private windowTopInset: number = 0;
  @StorageLink('desktopMode') private desktopMode: boolean = false;
  private defaultUserAgent: string = '';
  @State private progress: number = 0;
  @State private isLoading: boolean = true;
  @State private hasLoadedOnce: boolean = false;
  @State private loadFailed: boolean = false;
  @State private httpError: number = 0;
  @State private failedAddress: string = '';
  @State private isFullScreen: boolean = false;
  @State private menuOpen: boolean = false;
  @State private canGoBack: boolean = false;
  @State private canGoForward: boolean = false;

  private applyUserAgent(): void {
    if (!this.controllerReady) { return; }
    try {
      if (!this.defaultUserAgent) { this.defaultUserAgent = this.controller.getUserAgent(); }
      const version = this.defaultUserAgent.match(/Chrome\/([0-9.]+)/);
      const engine = version ? version[1] : '';
      const userAgent = this.desktopMode ? (engine ?
        `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${engine} Safari/537.36` :
        this.defaultUserAgent) : HARMONY_BROWSER_UA;
      this.controller.setCustomUserAgent(userAgent);
    } catch { console.warn('Unable to set the browsing mode.'); }
  }

  private toggleBrowsingMode(): void {
    this.desktopMode = !this.desktopMode;
    this.applyUserAgent();
    this.reload();
  }

  private onSystemThemeChanged(): void {
    this.applyWebAppearance();
  }

  private applyWebAppearance(): void {
    if (!this.controllerReady) {
      return;
    }
    try {
      this.controller.runJavaScript(createWebAdapterScript(this.isDark))
        .catch(() => {
          console.warn('Unable to apply the website appearance.');
        });
    } catch {
      console.warn('The web controller is not available yet.');
    }
  }

  private updateNavigationState(): void {
    try {
      this.canGoBack = this.controller.accessBackward();
      this.canGoForward = this.controller.accessForward();
    } catch {
      this.canGoBack = false;
      this.canGoForward = false;
    }
  }

  private goBack(): void {
    this.menuOpen = false;
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
      }
    } catch {
      this.updateNavigationState();
    }
  }

  private goForward(): void {
    this.menuOpen = false;
    try {
      if (this.controller.accessForward()) {
        this.controller.forward();
      }
    } catch {
      this.updateNavigationState();
    }
  }

  private returnHome(): void {
    this.menuOpen = false;
    try { this.controller.loadUrl(TIKTOK_URL); }
    catch { this.loadFailed = true; }
  }

  private safeAddress(address: string): string {
    return address.split('?')[0].split('#')[0].replace(/^https?:\/\//, '').slice(0, 180);
  }

  private reload(): void {
    this.menuOpen = false;
    this.loadFailed = false;
    this.isLoading = true;
    this.progress = 0;
    try {
      this.controller.refresh();
    } catch {
      this.isLoading = false;
      this.loadFailed = true;
    }
  }

  onBackPress(): boolean {
    if (this.diagnosticsOpen) { this.diagnosticsOpen = false; return true; }
    if (this.popupOpen) {
      this.popupBack();
      return true;
    }
    if (this.menuOpen) {
      this.menuOpen = false;
      return true;
    }
    try {
      if (this.controller.accessBackward()) {
        this.controller.backward();
        return true;
      }
    } catch {
      return false;
    }
    return false;
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Web({ src: TIKTOK_URL, controller: this.controller })
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .multiWindowAccess(true)
        .onWindowNew((event) => {
          if (!event) { return; }
          if (this.popupOpen) {
            event.handler.setWebController(null);
            return;
          }
          this.popupReady = false;
          this.popupController = new webview.WebviewController();
          this.popupFailed = false;
          this.popupProgress = 0;
          this.popupAddress = this.safeAddress(event.targetUrl);
          this.menuOpen = false;
          this.popupOpen = true;
          // Bind the actual child window; loading targetUrl loses window.opener.
          event.handler.setWebController(this.popupController);
        })
        .fileAccess(false)
        .geolocationAccess(false)
        .darkMode(WebDarkMode.Auto)
        .forceDarkAccess(false)
        .javaScriptOnDocumentStart([{
          script: createWebAdapterScript(this.isDark),
          scriptRules: ['https://www.tiktok.com', 'https://tiktok.com']
        }])
        .backgroundColor($r('app.color.page_background'))
        .onControllerAttached(() => {
          this.controllerReady = true;
          this.syncNetworkState();
          this.applyUserAgent();
          this.applyWebAppearance();
        })
        .onTouch(() => {
          this.menuOpen = false;
        })
        .onFullScreenEnter(() => {
          this.isFullScreen = true;
          this.menuOpen = false;
        })
        .onFullScreenExit(() => {
          this.isFullScreen = false;
        })
        .onPageBegin(() => {
          this.httpError = 0;
          this.failedAddress = '';
          this.isLoading = true;
          this.loadFailed = false;
          this.progress = 0;
          this.menuOpen = false;
        })
        .onProgressChange((event) => {
          this.progress = event.newProgress;
        })
        .onPageEnd(() => {
          saveWebSession();
          this.isLoading = false;
          this.hasLoadedOnce = true;
          this.loadFailed = false;
          this.updateNavigationState();
          this.applyWebAppearance();
        })
        .onHttpErrorReceive((event) => {
          if (event && event.response.getResponseCode() >= 400) {
            this.recordNetworkError(event.request.getRequestUrl(), event.response.getResponseCode(), 'HTTP');
          }
          if (event && event.request.isMainFrame()) {
            this.httpError = event.response.getResponseCode();
            this.failedAddress = this.safeAddress(event.request.getRequestUrl());
            this.isLoading = false;
          }
        })
        .onErrorReceive((event) => {
          if (event) {
            this.recordNetworkError(event.request.getRequestUrl(), event.error.getErrorCode(), '网络');
          }
          if (event && event.request.isMainFrame()) {
            this.isLoading = false;
            this.loadFailed = true;
          }
        });

      if (this.loadFailed || this.httpError >= 400) {
        Column({ space: 14 }) {
          Text(this.httpError >= 400 ? '网页请求失败 · ' + this.httpError : '暂时无法打开 TikTok')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.primary_text'));
          Text(this.httpError >= 400 ? this.failedAddress + '\n登录未完成，请返回 TikTok。' : '网页加载失败，请检查网络后重试。')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .textAlign(TextAlign.Center);
          Button('返回 TikTok')
            .fontColor(Color.White)
            .backgroundColor('#FE2C55')
            .onClick(() => this.returnHome());
          Button('重新加载')
            .fontColor(Color.White)
            .backgroundColor('#FE2C55')
            .onClick(() => this.reload());
        }
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .padding({ left: 24, right: 24 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.page_background'));
      } else if (!this.hasLoadedOnce) {
        Column({ space: 14 }) {
          Text('TikTok')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary_text'));
          Text('正在连接')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'));
          Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
            .width(160)
            .height(3)
            .color('#FE2C55');
        }
        .width('100%')
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor($r('app.color.page_background'));
      }

      if (this.isLoading && this.hasLoadedOnce && !this.loadFailed && !this.isFullScreen) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#FE2C55')
          .align(Alignment.Top);
      }

      if (!this.isFullScreen && !this.popupOpen) {
        Column({ space: 8 }) {
          if (this.menuOpen) {
            Column({ space: 4 }) {
              Button('返回')
                .width(136)
                .height(44)
                .enabled(this.canGoBack)
                .fontColor(this.canGoBack ? $r('app.color.primary_text') : $r('app.color.disabled_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => this.goBack());
              Button('前进')
                .width(136)
                .height(44)
                .enabled(this.canGoForward)
                .fontColor(this.canGoForward ? $r('app.color.primary_text') : $r('app.color.disabled_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => this.goForward());
              Button(this.desktopMode ? '切换移动模式' : '切换桌面模式')
                .width(136)
                .height(44)
                .fontColor($r('app.color.primary_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => this.toggleBrowsingMode());
              Button('返回 TikTok 首页')
                .width(136)
                .height(44)
                .fontColor($r('app.color.primary_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => this.returnHome());
              Button('网络诊断')
                .width(136).height(44)
                .fontColor($r('app.color.primary_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => { this.diagnosticsOpen = true; this.menuOpen = false; });
              Button('刷新')
                .width(136)
                .height(44)
                .fontColor($r('app.color.primary_text'))
                .backgroundColor(Color.Transparent)
                .onClick(() => this.reload());
            }
            .padding(6)
            .borderRadius(16)
            .backgroundColor($r('app.color.control_background'));
          }
          Button(this.menuOpen ? '×' : '⋯', { type: ButtonType.Circle })
            .width(44)
            .height(44)
            .fontSize(26)
            .fontColor($r('app.color.primary_text'))
            .backgroundColor($r('app.color.control_background'))
            .accessibilityText('网页操作菜单')
            .onClick(() => {
              this.updateNavigationState();
              this.menuOpen = !this.menuOpen;
            });
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12, bottom: 12 });
      }
      if (this.popupOpen) {
        Column() {
          Row({ space: 12 }) {
            Button('返回').onClick(() => this.popupBack());
            Text(this.popupAddress || '正在打开登录页面')
              .fontSize(12)
              .fontColor($r('app.color.primary_text'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1);
            Button('关闭').onClick(() => this.closePopup());
          }
          .width('100%')
          .padding(8);
          Progress({ value: this.popupProgress, total: 100, type: ProgressType.Linear })
            .width('100%').height(2).color('#FE2C55');
          Stack() {
            // An empty src lets ArkWeb populate the child from onWindowNew.
            Web({ src: '', controller: this.popupController })
              .width('100%').height('100%')
              .javaScriptAccess(true)
              .domStorageAccess(true)
              .fileAccess(false)
              .geolocationAccess(false)
              .multiWindowAccess(true)
              .onWindowNew((event) => {
                if (event) { event.handler.setWebController(null); }
              })
              .onControllerAttached(() => {
                this.popupReady = true;
                this.syncNetworkState();
                try {
                  this.popupController.setCustomUserAgent(this.controller.getCustomUserAgent() || this.controller.getUserAgent());
                } catch {}
              })
              .onWindowExit(() => this.closePopup())
              .onPageBegin((event) => {
                this.popupFailed = false;
                this.popupProgress = 0;
                if (event) { this.popupAddress = this.safeAddress(event.url); }
              })
              .onPageEnd((event) => {
                saveWebSession();
                if (event) { this.popupAddress = this.safeAddress(event.url); }
              })
              .onProgressChange((event) => { this.popupProgress = event.newProgress; })
              .onErrorReceive((event) => {
          if (event) {
            this.recordNetworkError(event.request.getRequestUrl(), event.error.getErrorCode(), '网络');
          }
                if (event && event.request.isMainFrame()) { this.popupFailed = true; }
              })
              .onHttpErrorReceive((event) => {
          if (event && event.response.getResponseCode() >= 400) {
            this.recordNetworkError(event.request.getRequestUrl(), event.response.getResponseCode(), 'HTTP');
          }
                if (event && event.request.isMainFrame() && event.response.getResponseCode() >= 400) {
                  this.popupFailed = true;
                }
              });
            if (this.popupFailed) {
              Column({ space: 14 }) {
                Text('登录页面加载失败').fontColor($r('app.color.primary_text'));
                Button('重试').onClick(() => {
                  this.popupFailed = false;
                  try { this.popupController.refresh(); } catch { this.popupFailed = true; }
                });
                Button('返回 TikTok').onClick(() => this.closePopup());
              }
              .width('100%').height('100%')
              .justifyContent(FlexAlign.Center)
              .backgroundColor($r('app.color.page_background'));
            }
          }.layoutWeight(1).width('100%');
        }
        .width('100%').height('100%')
        .backgroundColor($r('app.color.page_background'));
      }
      if (this.diagnosticsOpen) {
        Column({ space: 16 }) {
          Text(this.networkState).fontColor($r('app.color.primary_text'));
          Text('最近的请求错误').fontSize(20).fontColor($r('app.color.primary_text'));
          Text(this.networkDetail || '尚未捕获请求错误。网站提示的 network error 也可能来自业务接口返回。')
            .fontSize(14).fontColor($r('app.color.primary_text'));
          Text('记录仅含错误码和域名；部分资源失败不一定影响登录。')
            .fontSize(12).fontColor($r('app.color.secondary_text'));
          Button('关闭').onClick(() => { this.diagnosticsOpen = false; });
        }
        .padding(24).width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.page_background'));
      }
    }
    .padding({ top: this.windowTopInset })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }
}