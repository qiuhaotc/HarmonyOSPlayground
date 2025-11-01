import router from '@ohos.router';
import { BillDatabase } from '../database/BillDatabase';
import { PreferencesUtil } from '../utils/PreferencesUtil';

/**
 * 主页面 - 记账APP
 */
@Entry
@Component
struct Index {
  @State isInitialized: boolean = false;

  private billDb: BillDatabase = BillDatabase.getInstance();
  private prefsUtil: PreferencesUtil = PreferencesUtil.getInstance();

  async aboutToAppear() {
    try {
      const context = getContext(this);
      // 初始化数据库
      await this.billDb.init(context);
      // 初始化偏好设置
      await this.prefsUtil.init(context);
      this.isInitialized = true;
    } catch (err) {
      console.error('初始化失败', JSON.stringify(err));
    }
  }

  build() {
    Column() {
      // 标题
      Text('记账本')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 60, bottom: 40 })

      // 功能按钮
      Column({ space: 16 }) {
        Button('记一笔')
          .fontSize(20)
          .backgroundColor($r('app.color.primary_color'))
          .width('80%')
          .height(56)
          .onClick(() => {
            router.pushUrl({ url: 'pages/AddBillPage' });
          })

        Button('账单列表')
          .fontSize(20)
          .backgroundColor($r('app.color.success_color'))
          .width('80%')
          .height(56)
          .onClick(() => {
            router.pushUrl({ url: 'pages/BillListPage' });
          })

        Button('统计分析')
          .fontSize(20)
          .backgroundColor($r('app.color.info_color'))
          .width('80%')
          .height(56)
          .onClick(() => {
            router.pushUrl({ url: 'pages/StatisticsPage' });
          })

        Button('关于')
          .fontSize(20)
          .backgroundColor($r('app.color.text_secondary'))
          .width('80%')
          .height(56)
          .onClick(() => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
      }
      .width('100%')
      .margin({ top: 40 })

      // 底部说明
      Text('简单记账，清晰理财')
        .fontSize(14)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ top: 40 })

      if (!this.isInitialized) {
        Text('正在初始化...')
          .fontSize(12)
          .fontColor($r('app.color.danger_color'))
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}