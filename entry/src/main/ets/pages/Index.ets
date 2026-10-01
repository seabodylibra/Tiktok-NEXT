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

  build() {
    Navigation() {
      NavDestination() {
        Column() {
          if (this.isToolbarVisible) {
            Row({ space: 10 }) {
              Text('‹')
                .fontSize(32)
                .fontColor(this.canGoBack ? '#F5F5F7' : '#66666D')
                .width(46)
                .height(46)
                .textAlign(TextAlign.Center)
                .borderRadius(23)
                .backgroundColor('#202025')
                .onClick(() => this.goBack());

              Text('›')
                .fontSize(32)
                .fontColor(this.canGoForward ? '#F5F5F7' : '#66666D')
                .width(46)
                .height(46)
                .textAlign(TextAlign.Center)
                .borderRadius(23)
                .backgroundColor('#202025')
                .onClick(() => this.goForward());

              Row({ space: 10 }) {
                Text('♪')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FE2C55');

                Text('tiktok.com')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#F5F5F7')
                  .layoutWeight(1)
                  .maxLines(1);

                if (this.isLoading) {
                  Text(`${Math.floor(this.progress)}%`)
                    .fontSize(12)
                    .fontColor('#A8A8B0');
                }
              }
              .height(46)
              .padding({ left: 16, right: 16 })
              .layoutWeight(1)
              .borderRadius(23)
              .backgroundColor('#202025');

              Text('↻')
                .fontSize(26)
                .fontColor('#F5F5F7')
                .width(46)
                .height(46)
                .textAlign(TextAlign.Center)
                .borderRadius(23)
                .backgroundColor('#202025')
                .onClick(() => this.reload());
            }
            .width('100%')
            .height(64)
            .padding({ left: 16, right: 16 })
            .backgroundColor('#111114');
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
                  .fontColor('#F5F5F7');

                Text('网页加载失败，请检查网络后重试。')
                  .fontSize(15)
                  .fontColor('#A8A8B0')
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
              .backgroundColor('#111114');
            } else if (!this.hasLoadedOnce) {
              Column({ space: 14 }) {
                Text('♪')
                  .fontSize(36)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FE2C55');

                Text('正在连接 TikTok')
                  .fontSize(20)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#F5F5F7');

                Text('首次打开需要从网络加载网页内容')
                  .fontSize(14)
                  .fontColor('#A8A8B0')
                  .textAlign(TextAlign.Center);

                Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
                  .width(180)
                  .height(3)
                  .color('#FE2C55');

                Text(`${Math.floor(this.progress)}%`)
                  .fontSize(12)
                  .fontColor('#777780');
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .padding({ left: 24, right: 24 })
              .backgroundColor('#111114');
            }
          }
          .width('100%')
          .layoutWeight(1);
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#111114');
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        if (this.controller.accessBackward()) {
          this.controller.backward();
          return true;
        }
        return false;
      });
    }
    .hideTitleBar(true)
    .width('100%')
    .height('100%');
  }
}
