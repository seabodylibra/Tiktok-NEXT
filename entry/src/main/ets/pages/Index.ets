import { webview } from '@kit.ArkWeb';
import { createWebAdapterScript } from '../common/WebAdapter';

const TIKTOK_URL: string = 'https://www.tiktok.com/';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private controllerReady: boolean = false;

  @StorageLink('systemDark') @Watch('onSystemThemeChanged') private isDark: boolean = false;
  @StorageLink('windowTopInset') private windowTopInset: number = 0;
  @State private progress: number = 0;
  @State private isLoading: boolean = true;
  @State private hasLoadedOnce: boolean = false;
  @State private loadFailed: boolean = false;
  @State private isFullScreen: boolean = false;
  @State private menuOpen: boolean = false;
  @State private canGoBack: boolean = false;
  @State private canGoForward: boolean = false;

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
        .onErrorReceive((event) => {
          if (event && event.request.isMainFrame()) {
            this.isLoading = false;
            this.loadFailed = true;
          }
        });

      if (this.loadFailed) {
        Column({ space: 14 }) {
          Text('暂时无法打开 TikTok')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.primary_text'));
          Text('网页加载失败，请检查网络后重试。')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .textAlign(TextAlign.Center);
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