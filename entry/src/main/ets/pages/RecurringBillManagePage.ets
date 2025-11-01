import { RecurringBillConfig, RecurringType } from '../models/RecurringBillModel';
import { BillType } from '../models/BillModel';
import { RecurringBillDatabase } from '../database/RecurringBillDatabase';
import { BillDatabase } from '../database/BillDatabase';
import router from '@ohos.router';

/**
 * 定期记账管理页面
 */
@Entry
@Component
struct RecurringBillManagePage {
  @State configs: RecurringBillConfig[] = [];
  @State loading: boolean = false;
  private recurringDb: RecurringBillDatabase = RecurringBillDatabase.getInstance();

  async aboutToAppear() {
    // 初始化数据库
    try {
      await this.recurringDb.init(getContext(this));
    } catch (err) {
      console.error('初始化定期记账数据库失败', JSON.stringify(err));
    }

    // 加载配置列表
    await this.loadConfigs();
  }

  // 加载配置列表
  async loadConfigs() {
    this.loading = true;
    try {
      this.configs = await this.recurringDb.queryAllConfigs();
    } catch (err) {
      console.error('加载定期配置失败', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({
        message: "加载失败",
        duration: 1000
      });
    }
    this.loading = false;
  }

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar();

      if (this.loading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary_color'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.configs.length === 0) {
        // 空状态
        Column() {
          Text('📅')
            .fontSize(64)
            .margin({ bottom: 16 })

          Text('暂无定期记账配置')
            .fontSize(16)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ bottom: 8 })

          Text('点击右上角"添加"创建定期记账')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 配置列表
        List({ space: 1 }) {
          ForEach(this.configs, (config: RecurringBillConfig) => {
            ListItem() {
              this.buildConfigItem(config);
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor($r('app.color.page_background'))
      }
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

      Text('定期记账')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('添加')
        .fontSize(16)
        .fontColor($r('app.color.primary_color'))
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddBillPage' });
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder
  buildConfigItem(config: RecurringBillConfig) {
    Row() {
      Column() {
        // 金额和分类
        Row() {
          Text(config.type === BillType.EXPENSE ? '-' : '+')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(config.type === BillType.EXPENSE ? $r('app.color.danger_color') : $r('app.color.success_color'))

          Text(`¥${config.amount.toFixed(2)}`)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(config.type === BillType.EXPENSE ? $r('app.color.danger_color') : $r('app.color.success_color'))
            .margin({ left: 4 })

          Text(config.category)
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ left: 12 })
        }
        .width('100%')
        .margin({ bottom: 8 })

        // 重复规则
        Text(`${config.getRecurringTypeText()} • ${config.getEndConditionText()}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 4 })

        // 开始日期和状态
        Row() {
          Text(`开始: ${config.startDate}`)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))

          Text(config.isActive ? '启用中' : '已停用')
            .fontSize(12)
            .fontColor(config.isActive ? $r('app.color.success_color') : $r('app.color.text_tertiary'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(config.isActive ? '#E8F5E9' : $r('app.color.page_background'))
            .borderRadius(4)
            .margin({ left: 12 })
        }

        // 备注
        if (config.note) {
          Text(config.note)
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Column({ space: 8 }) {
        Button(config.isActive ? '停用' : '启用')
          .fontSize(12)
          .fontColor(config.isActive ? $r('app.color.danger_color') : $r('app.color.success_color'))
          .backgroundColor($r('app.color.page_background'))
          .height(32)
          .width(60)
          .onClick(() => {
            this.toggleConfigStatus(config);
          })

        Button('删除')
          .fontSize(12)
          .fontColor($r('app.color.danger_color'))
          .backgroundColor($r('app.color.page_background'))
          .height(32)
          .width(60)
          .onClick(() => {
            this.showDeleteConfirmDialog(config);
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
  }

  // 切换配置状态
  async toggleConfigStatus(config: RecurringBillConfig) {
    try {
      config.isActive = !config.isActive;
      await this.recurringDb.updateConfig(config);
      await this.loadConfigs();
      this.getUIContext().getPromptAction().showToast({
        message: config.isActive ? "已启用" : "已停用",
        duration: 1000
      });
    } catch (err) {
      console.error('更新配置状态失败', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({
        message: "操作失败",
        duration: 1000
      });
    }
  }

  // 显示删除确认对话框
  showDeleteConfirmDialog(config: RecurringBillConfig) {
    this.getUIContext().showAlertDialog({
      title: '确认删除',
      message: `确定要删除这个定期记账配置吗？\n\n是否同时删除关联的自动生成账单？`,
      buttons: [
        {
          value: '取消',
          fontColor: $r('app.color.text_primary'),
          action: () => {}
        },
        {
          value: '仅删除配置',
          fontColor: $r('app.color.primary_color'),
          action: () => {
            this.deleteConfig(config, false);
          }
        },
        {
          value: '删除配置和账单',
          fontColor: $r('app.color.danger_color'),
          action: () => {
            this.deleteConfig(config, true);
          }
        }
      ]
    });
  }

  // 删除配置
  async deleteConfig(config: RecurringBillConfig, deleteRelatedBills: boolean) {
    if (!config.id) {
      return;
    }

    try {
      const records = await this.recurringDb.queryRecordsByConfigId(config.id);
      
      // 如果需要删除关联账单
      if (deleteRelatedBills) {
        const billDb = BillDatabase.getInstance();
        
        // 删除所有关联的账单
        for (const record of records) {
          try {
            await billDb.deleteBill(record.billId);
          } catch (err) {
            console.error(`删除账单${record.billId}失败`, JSON.stringify(err));
          }
        }
      }
      
      // 无论是否删除账单，都要删除生成记录
      if (records.length > 0) {
        await this.recurringDb.deleteRecordsByConfigId(config.id);
      }
      
      // 删除配置
      await this.recurringDb.deleteConfig(config.id);
      await this.loadConfigs();
      
      this.getUIContext().getPromptAction().showToast({
        message: deleteRelatedBills ? "配置和账单已删除" : "配置已删除",
        duration: 1500
      });
    } catch (err) {
      console.error('删除配置失败', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({
        message: "删除失败",
        duration: 1000
      });
    }
  }
}
