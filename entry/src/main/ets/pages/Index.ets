import { webview } from '@kit.ArkWeb';

const TIKTOK_URL: string = 'https://www.tiktok.com/';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();

  @State private progress: number = 0;
  @State private isLoading: boolean = true;
  @State private hasLoadedOnce: boolean = false;
  @State private loadFailed: boolean = false;
  @State private isToolbarVisible: boolean = true;
  @State private canGoBack: boolean = false;
  @State private canGoForward: boolean = false;

  private updateNavigationState(): void {
    this.canGoBack = this.controller.accessBackward();
    this.canGoForward = this.controller.accessForward();
  }

  private goBack(): void {
    if (this.canGoBack) {
      this.controller.backward();
    }
  }

  private goForward(): void {
    if (this.canGoForward) {
      this.controller.forward();
    }
  }

  private reload(): void {
    this.loadFailed = false;
    this.isLoading = true;
    this.progress = 0;
    this.controller.refresh();
  }

  onBackPress(): boolean {
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
    Column() {
      if (this.isToolbarVisible) {
        Row({ space: 10 }) {
          Text('‹')
            .fontSize(32)
            .fontColor(this.canGoBack ? $r('app.color.primary_text') : $r('app.color.disabled_text'))
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(23)
            .backgroundColor($r('app.color.control_background'))
            .onClick(() => this.goBack());

          Text('›')
            .fontSize(32)
            .fontColor(this.canGoForward ? $r('app.color.primary_text') : $r('app.color.disabled_text'))
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(23)
            .backgroundColor($r('app.color.control_background'))
            .onClick(() => this.goForward());

          Row({ space: 10 }) {
            Text('♪')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FE2C55');

            Text('tiktok.com')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.primary_text'))
              .layoutWeight(1)
              .maxLines(1);

            if (this.isLoading) {
              Text(`${Math.floor(this.progress)}%`)
                .fontSize(12)
                .fontColor($r('app.color.secondary_text'));
            }
          }
          .height(46)
          .padding({ left: 16, right: 16 })
          .layoutWeight(1)
          .borderRadius(23)
          .backgroundColor($r('app.color.control_background'));

          Text('↻')
            .fontSize(26)
            .fontColor($r('app.color.primary_text'))
            .width(46)
            .height(46)
            .textAlign(TextAlign.Center)
            .borderRadius(23)
            .backgroundColor($r('app.color.control_background'))
            .onClick(() => this.reload());
        }
        .width('100%')
        .height(64)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.page_background'));
      }

      if (this.isLoading && this.isToolbarVisible && this.hasLoadedOnce && !this.loadFailed) {
        Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .color('#FE2C55');
      }

      Stack() {
        Web({ src: TIKTOK_URL, controller: this.controller })
          .width('100%')
          .height('100%')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .fileAccess(false)
          .geolocationAccess(false)
          .darkMode(WebDarkMode.Auto)
          .forceDarkAccess(true)
          .backgroundColor($r('app.color.page_background'))
          .onFullScreenEnter(() => {
            this.isToolbarVisible = false;
          })
          .onFullScreenExit(() => {
            this.isToolbarVisible = true;
          })
          .onPageBegin(() => {
            this.isLoading = true;
            this.loadFailed = false;
            this.progress = 0;
          })
          .onProgressChange((event) => {
            this.progress = event.newProgress;
          })
          .onPageEnd(() => {
            this.isLoading = false;
            this.hasLoadedOnce = true;
            this.loadFailed = false;
            this.updateNavigationState();
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
              .fontSize(15)
              .fontColor($r('app.color.secondary_text'))
              .textAlign(TextAlign.Center);

            Text('重新加载')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .padding({ left: 22, right: 22, top: 12, bottom: 12 })
              .borderRadius(22)
              .backgroundColor('#FE2C55')
              .onClick(() => this.reload());
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 24, right: 24 })
          .backgroundColor($r('app.color.page_background'));
        } else if (!this.hasLoadedOnce) {
          Column({ space: 14 }) {
            Text('♪')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FE2C55');

            Text('正在连接 TikTok')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.primary_text'));

            Text('首次打开需要从网络加载网页内容')
              .fontSize(14)
              .fontColor($r('app.color.secondary_text'))
              .textAlign(TextAlign.Center);

            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width(180)
              .height(3)
              .color('#FE2C55');

            Text(`${Math.floor(this.progress)}%`)
              .fontSize(12)
              .fontColor($r('app.color.muted_text'));
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ left: 24, right: 24 })
          .backgroundColor($r('app.color.page_background'));
        }
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
