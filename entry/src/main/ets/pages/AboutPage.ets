import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';

/**
 * 关于页面
 */
@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      // 标题栏
      this.buildTitleBar();

      // 内容区域
      Scroll() {
        Column() {
          // 应用图标和名称
          Column() {
            Text('💰')
              .fontSize(64)
              .margin({ top: 40 })

            Text('记账本')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 16 })

            Text('Version 1.0.0')
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 8 })
          }
          .width('100%')
          .margin({ bottom: 40 })

          // 应用简介
          Column() {
            Text('应用简介')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ bottom: 12 })

            Text('一款简洁实用的记账应用，帮助您轻松管理日常收支，清晰掌握财务状况。')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(22)
              .width('100%')
              .padding({ left: 16, right: 16 })
              .borderRadius(8)
              .padding(16)
              .margin({ left: 12, right: 12 })
          }
          .width('100%')
          .margin({ bottom: 24 })

          // 功能特性
          Column() {
            Text('功能特性')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ bottom: 12 })

            Column({ space: 8 }) {
              this.buildFeatureItem('✅', '支持收入和支出记录')
              this.buildFeatureItem('📊', '多维度统计分析')
              this.buildFeatureItem('🏷️', '多种分类标签')
              this.buildFeatureItem('📅', '按年月筛选账单')
              this.buildFeatureItem('💾', '本地数据存储')
            }
            .width('100%')
            .borderRadius(8)
            .padding(16)
            .margin({ left: 12, right: 12 })
          }
          .width('100%')
          .margin({ bottom: 24 })

          // GitHub 仓库
          Column() {
            Text('开源项目')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ bottom: 12 })

            Row() {
              Column({ space: 4 }) {
                Row() {
                  Text('🔗 ')
                    .fontSize(16)
                  Text('GitHub 仓库')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                }

                Text('https://github.com/qiuhaotc/HarmonyOSPlayground')
                  .fontSize(12)
                  .maxLines(2)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('访问')
                .fontSize(14)
                .borderRadius(4)
                .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            }
            .width('100%')
            .padding(16)
            .borderRadius(8)
            .margin({ left: 12, right: 12 })
            .onClick(() => {
              const wantInfo: Want = {
                action: 'ohos.want.action.viewData',
                uri: 'https://github.com/qiuhaotc/HarmonyOSPlayground' // 替换为实际链接
              };

              const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

              context.startAbility(wantInfo)
                .catch((err: BusinessError) => {
                    console.error('打开链接失败:', err);
                    // 如果失败，显示提示
                    this.getUIContext().getPromptAction().showToast({
                      message: "请手动访问 GitHub 仓库",
                      duration: 2000
                    });
                });
            })
          }
          .width('100%')
          .margin({ bottom: 24 })

          // 技术栈
          Column() {
            Text('技术栈')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .padding({ left: 16, right: 16 })
              .margin({ bottom: 12 })

            Column({ space: 8 }) {
              this.buildTechItem('ArkTS', '开发语言')
              this.buildTechItem('ArkUI', 'UI框架')
              this.buildTechItem('RelationalStore', '数据存储')
            }
            .width('100%')
            .borderRadius(8)
            .padding(16)
            .margin({ left: 12, right: 12 })
          }
          .width('100%')
          .margin({ bottom: 40 })

          // 版权信息
          Text('© 2025 记账本应用')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ bottom: 20 })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  buildTitleBar() {
    Row() {
      Text('返回')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .onClick(() => {
          router.back();
        })

      Text('关于')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('   ')
        .fontSize(16)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildFeatureItem(icon: string, text: string) {
    Row() {
      Text(icon)
        .fontSize(16)
        .margin({ right: 8 })

      Text(text)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  @Builder
  buildTechItem(name: string, description: string) {
    Row() {
      Column({ space: 2 }) {
        Text(name)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Text(description)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}
