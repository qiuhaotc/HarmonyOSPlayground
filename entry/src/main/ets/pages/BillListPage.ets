import { BillModel, BillType } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { BillStatisticsUtil } from '../utils/BillStatisticsUtil';
import { DateUtil } from '../utils/DateUtil';
import router from '@ohos.router';

/**
 * 账单列表页面
 */
@Entry
@Component
struct BillListPage {
  @State bills: BillModel[] = []; // 账单列表
  @State selectedYear: string = DateUtil.getCurrentYear(); // 选中的年份
  @State selectedMonth: string = DateUtil.getCurrentMonth(); // 选中的月份
  @State totalIncome: number = 0; // 总收入
  @State totalExpense: number = 0; // 总支出
  @State balance: number = 0; // 结余

  private billDb: BillDatabase = BillDatabase.getInstance();

  aboutToAppear() {
    this.loadBills();
  }

  // 加载账单数据
  async loadBills() {
    try {
      this.bills = await this.billDb.queryBillsByYearMonth(this.selectedYear, this.selectedMonth);
      this.calculateStatistics();
    } catch (err) {
      console.error('加载账单失败', JSON.stringify(err));
    }
  }

  // 计算统计数据
  calculateStatistics() {
    const stats = BillStatisticsUtil.calculateStatistics(this.bills);
    this.totalIncome = stats.totalIncome;
    this.totalExpense = stats.totalExpense;
    this.balance = stats.balance;
  }

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar();

      // 日期选择器
      this.buildDateSelector();

      // 统计卡片
      this.buildStatisticsCard();

      // 账单列表（已支持滚动）
      this.buildBillList();

      // 添加按钮
      this.buildAddButton();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildTitleBar() {
    Row() {
      Text('返回')
        .fontSize(16)
        .fontColor('#333333')
        .onClick(() => {
          router.back();
        })

      Text('账单列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text('统计')
        .fontSize(16)
        .fontColor('#007DFF')
        .onClick(() => {
          router.pushUrl({ url: 'pages/StatisticsPage' });
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildDateSelector() {
    Row() {
      Button('<')
        .fontSize(18)
        .fontColor('#333333')
        .backgroundColor('#F0F0F0')
        .width(40)
        .height(40)
        .onClick(() => {
          this.previousMonth();
        })

      Text(DateUtil.formatYearMonth(`${this.selectedYear}-${this.selectedMonth}`))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('>')
        .fontSize(18)
        .fontColor('#333333')
        .backgroundColor('#F0F0F0')
        .width(40)
        .height(40)
        .onClick(() => {
          this.nextMonth();
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .margin({ top: 1 })
  }

  @Builder
  buildStatisticsCard() {
    Column() {
      Row() {
        Column() {
          Text('收入')
            .fontSize(14)
            .fontColor('#666666')
          Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00B894')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('支出')
            .fontSize(14)
            .fontColor('#666666')
          Text('¥' + BillStatisticsUtil.formatAmount(this.totalExpense))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B6B')
            .margin({ top: 4 })
        }
        .layoutWeight(1)

        Column() {
          Text('结余')
            .fontSize(14)
            .fontColor('#666666')
          Text('¥' + BillStatisticsUtil.formatAmount(this.balance))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.balance >= 0 ? '#333333' : '#FF6B6B')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
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
    .layoutWeight(1)
    .margin({ top: 12 })
  }

  @Builder
  buildBillItem(bill: BillModel) {
    Row() {
      Column() {
        Text(bill.category)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Text(DateUtil.formatDateChinese(bill.date) + ' ' + DateUtil.formatTimeShort(bill.time))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })

        if (bill.note) {
          Text(bill.note)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text((bill.type === BillType.INCOME ? '+' : '-') + '¥' + BillStatisticsUtil.formatAmount(bill.amount))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(bill.type === BillType.INCOME ? '#00B894' : '#FF6B6B')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ left: 12, right: 12, bottom: 8 })
  }

  @Builder
  buildDeleteButton(bill: BillModel) {
    Button('删除')
      .fontSize(16)
      .fontColor('#FFFFFF')
      .backgroundColor('#FF6B6B')
      .height('100%')
      .onClick(() => {
        this.deleteBill(bill);
      })
  }

  @Builder
  buildAddButton() {
    Button('+')
      .fontSize(32)
      .fontColor('#FFFFFF')
      .backgroundColor('#007DFF')
      .width(56)
      .height(56)
      .borderRadius(28)
      .position({ x: '85%', y: '85%' })
      .onClick(() => {
        router.pushUrl({ url: 'pages/AddBillPage' });
      })
  }

  // 上一个月
  previousMonth() {
    let year = parseInt(this.selectedYear);
    let month = parseInt(this.selectedMonth);

    month--;
    if (month < 1) {
      month = 12;
      year--;
    }

    this.selectedYear = String(year);
    this.selectedMonth = String(month).padStart(2, '0');
    this.loadBills();
  }

  // 下一个月
  nextMonth() {
    let year = parseInt(this.selectedYear);
    let month = parseInt(this.selectedMonth);

    month++;
    if (month > 12) {
      month = 1;
      year++;
    }

    this.selectedYear = String(year);
    this.selectedMonth = String(month).padStart(2, '0');
    this.loadBills();
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
