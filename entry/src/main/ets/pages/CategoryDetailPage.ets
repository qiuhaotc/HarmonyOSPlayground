import { BillModel, BillType } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { BillStatisticsUtil } from '../utils/BillStatisticsUtil';
import { DateUtil } from '../utils/DateUtil';
import router from '@ohos.router';

/**
 * 分类详情页面
 */
@Entry
@Component
struct CategoryDetailPage {
  @State bills: BillModel[] = [];
  @State category: string = '';
  @State year: string = '';
  @State month: string = '';
  @State totalAmount: number = 0;

  private billDb: BillDatabase = BillDatabase.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, string>;
    this.category = params.category || '';
    this.year = params.year || '';
    this.month = params.month || ''; // 月份可能为空,表示按年查询

    this.loadBills();
  }

  // 加载账单数据
  async loadBills() {
    try {
      if (this.year && this.month) {
        // 按年月查询
        this.bills = await this.billDb.queryBillsByYearMonthAndCategory(this.year, this.month, this.category);
      } else if (this.year) {
        // 按年查询
        this.bills = await this.billDb.queryBillsByYearAndCategory(this.year, this.category);
      } else {
        // 查询所有该分类的账单
        this.bills = await this.billDb.queryBillsByCategory(this.category);
      }
      this.calculateTotal();
    } catch (err) {
      console.error('加载账单失败', JSON.stringify(err));
    }
  }

  // 计算总金额
  calculateTotal() {
    this.totalAmount = this.bills.reduce((sum, bill) => sum + bill.amount, 0);
  }

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar();

      // 可滚动内容区域
      Scroll() {
        Column() {
          // 统计卡片
          this.buildStatisticsCard();

          // 账单列表
          this.buildBillList();
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .alignItems(HorizontalAlign.Start)
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

      Text(this.category + ' 详情')
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
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder
  buildStatisticsCard() {
    Column() {
      Text(this.year && this.month 
        ? DateUtil.formatYearMonth(`${this.year}-${this.month}`)
        : (this.year ? `${this.year}年` : '全部账单'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      Text('¥' + BillStatisticsUtil.formatAmount(this.totalAmount))
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 8 })

      Text('共 ' + this.bills.length + ' 笔')
        .fontSize(14)
        .fontColor($r('app.color.text_tertiary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(24)
    .backgroundColor($r('app.color.card_background'))
    .margin({ top: 12 })
    .borderRadius(8)
  }

  @Builder
  buildBillList() {
    List() {
      ForEach(this.bills, (bill: BillModel) => {
        ListItem() {
          this.buildBillItem(bill);
        }
        .swipeAction({ end: this.buildDeleteButton(bill) })
      })
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder
  buildBillItem(bill: BillModel) {
    Row() {
      Column() {
        Text(DateUtil.formatDateChinese(bill.date))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        if (bill.note) {
          Text(bill.note)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text((bill.type === BillType.INCOME ? '+' : '-') + '¥' + BillStatisticsUtil.formatAmount(bill.amount))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(bill.type === BillType.INCOME ? $r('app.color.success_color') : $r('app.color.danger_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
    .margin({ left: 12, right: 12, bottom: 8 })
  }

  @Builder
  buildDeleteButton(bill: BillModel) {
    Button('删除')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor($r('app.color.danger_color'))
      .height('100%')
      .onClick(() => {
        this.deleteBill(bill);
      })
  }

  // 删除账单
  async deleteBill(bill: BillModel) {
    if (!bill.id) {
      return;
    }

    try {
      await this.billDb.deleteBill(bill.id);
      await this.loadBills();
    } catch (err) {
      console.error('删除账单失败', JSON.stringify(err));
    }
  }
}
