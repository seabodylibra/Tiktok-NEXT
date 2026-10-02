import { webview } from '@kit.ArkWeb';
import { createWebAdapterScript } from '../common/WebAdapter';

const TIKTOK_URL: string = 'https://www.tiktok.com/';

PersistentStorage.persistProp('desktopMode', false);

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private controllerReady: boolean = false;

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
      const userAgent = engine ?
        `Mozilla/5.0 (${this.desktopMode ? 'Windows NT 10.0; Win64; x64' : 'Linux; Android 12'}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${engine}${this.desktopMode ? '' : ' Mobile'} Safari/537.36` :
        this.defaultUserAgent + (this.desktopMode ? '' : ' Mobile');
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
          this.isLoading = false;
          this.hasLoadedOnce = true;
          this.loadFailed = false;
          this.updateNavigationState();
          this.applyWebAppearance();
        })
        .onHttpErrorReceive((event) => {
          if (event && event.request.isMainFrame()) {
            this.httpError = event.response.getResponseCode();
            this.failedAddress = this.safeAddress(event.request.getRequestUrl());
            this.isLoading = false;
          }
        })
        .onErrorReceive((event) => {
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

      if (!this.isFullScreen) {
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
    }
    .padding({ top: this.windowTopInset })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM]);
  }
}