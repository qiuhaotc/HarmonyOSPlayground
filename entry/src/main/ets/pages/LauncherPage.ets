import { BusinessError } from '@kit.BasicServicesKit';

const LAUNCHER_DELAY_TIME: number = 800;

/**
 * 应用启动页（启动屏）
 */
@Entry
@Component
struct LauncherPage {
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  onPageShow(): void {
    this.jumpToIndexPage();
  }

  jumpToIndexPage(): void {
    this.timerId = setTimeout(() => {
      this.getUIContext().getRouter().replaceUrl({
        url: 'pages/Index'
      }).catch((error: Error) => {
        console.error('[LauncherPage] Jump to index error: ' + JSON.stringify(error));
      });
    }, LAUNCHER_DELAY_TIME);
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#FFF8E1', 0.0],
            ['#FFE082', 1.0]
          ]
        })

      Column() {
        // App图标
        Text('💰')
          .fontSize(96)
          .margin({ top: 160 })

        // 应用名称
        Text('轻松来记账')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#5D4037')
          .margin({ top: 24 })

        // 应用介绍
        Text('简单记账，清晰理财')
          .fontSize(16)
          .fontColor('#8D6E63')
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
