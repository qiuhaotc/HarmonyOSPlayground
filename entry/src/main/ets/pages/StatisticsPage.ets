import { BillModel, BillType, DEFAULT_CATEGORIES } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { BillStatisticsUtil } from '../utils/BillStatisticsUtil';
import { DateUtil } from '../utils/DateUtil';
import router from '@ohos.router';

// 分类统计项接口
interface CategoryStatItem {
    category: string;
    amount: number;
    percentage: string;
    type: BillType;
}

/**
 * 统计页面
 */
@Entry
@Component
struct StatisticsPage {
    @State bills: BillModel[] = []; // 所有账单
    @State selectedYear: string = DateUtil.getCurrentYear(); // 选中的年份
    @State selectedMonth: string = DateUtil.getCurrentMonth(); // 选中的月份
    @State categoryStats: CategoryStatItem[] = [];
    @State totalIncome: number = 0;
    @State totalExpense: number = 0;
    private billDb: BillDatabase = BillDatabase.getInstance();

    aboutToAppear() {
        this.loadStatistics();
    }

    // 加载统计数据
    async loadStatistics() {
        try {
            this.bills = await this.billDb.queryBillsByYearMonth(this.selectedYear, this.selectedMonth);
            this.calculateCategoryStatistics();
        } catch (err) {
            console.error('加载统计数据失败', JSON.stringify(err));
        }
    }

    // 计算分类统计
    calculateCategoryStatistics() {
        const stats = BillStatisticsUtil.calculateStatistics(this.bills);
        this.totalIncome = stats.totalIncome;
        this.totalExpense = stats.totalExpense;

        // 构建分类统计数组
        this.categoryStats = [];

        // 支出分类统计
        const expenseCategories = DEFAULT_CATEGORIES.filter(cat => cat.type === BillType.EXPENSE);
        expenseCategories.forEach(cat => {
            const amount = stats.categoryStats.get(cat.name) || 0;
            if (amount > 0) {
                const statItem: CategoryStatItem = {
                    category: cat.name,
                    amount: amount,
                    percentage: BillStatisticsUtil.getCategoryPercentage(amount, this.totalExpense),
                    type: BillType.EXPENSE
                };
                this.categoryStats.push(statItem);
            }
        });

        // 收入分类统计
        const incomeCategories = DEFAULT_CATEGORIES.filter(cat => cat.type === BillType.INCOME);
        incomeCategories.forEach(cat => {
            const amount = stats.categoryStats.get(cat.name) || 0;
            if (amount > 0) {
                const statItem: CategoryStatItem = {
                    category: cat.name,
                    amount: amount,
                    percentage: BillStatisticsUtil.getCategoryPercentage(amount, this.totalIncome),
                    type: BillType.INCOME
                };
                this.categoryStats.push(statItem);
            }
        });

        // 按金额降序排序
        this.categoryStats.sort((a, b) => b.amount - a.amount);
    }

    build() {
        Column() {
            // 标题栏
            this.buildTitleBar();

            // 日期选择器
            this.buildDateSelector();

            // 总览卡片
            this.buildOverviewCard();

            // 分类统计列表
            this.buildCategoryStatsList();
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
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

            Text('账单统计')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

            Text('   ')
                .fontSize(16)
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
    buildOverviewCard() {
        Column() {
            Row() {
                Column() {
                    Text('收入')
                        .fontSize(14)
                        .fontColor('#666666')
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome))
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#00B894')
                        .margin({ top: 8 })
                }
                .layoutWeight(1)

                Column() {
                    Text('支出')
                        .fontSize(14)
                        .fontColor('#666666')
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalExpense))
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FF6B6B')
                        .margin({ top: 8 })
                }
                .layoutWeight(1)
            }
            .width('100%')

            Divider()
                .margin({ top: 16, bottom: 16 })

            Row() {
                Text('结余')
                    .fontSize(14)
                    .fontColor('#666666')

                Blank()

                Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome - this.totalExpense))
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor((this.totalIncome - this.totalExpense) >= 0 ? '#00B894' : '#FF6B6B')
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
    buildCategoryStatsList() {
        Column() {
            Text('分类统计')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width('100%')
                .padding({ left: 16, top: 16, bottom: 8 })

            if (this.categoryStats.length === 0) {
                Text('暂无数据')
                    .fontSize(14)
                    .fontColor('#999999')
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(32)
            } else {
                List() {
                    ForEach(this.categoryStats, (stat: CategoryStatItem) => {
                        ListItem() {
                            this.buildCategoryItem(stat);
                        }
                    })
                }
                .width('100%')
                .layoutWeight(1)
            }
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
    }

    @Builder
    buildCategoryItem(stat: CategoryStatItem) {
        Column() {
            Row() {
                // 获取分类图标
                Text(this.getCategoryIcon(stat.category, stat.type))
                    .fontSize(24)
                    .margin({ right: 12 })

                Column() {
                    Text(stat.category)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#333333')

                    Text(stat.percentage + '%')
                        .fontSize(12)
                        .fontColor('#999999')
                        .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('¥' + BillStatisticsUtil.formatAmount(stat.amount))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(stat.type === BillType.INCOME ? '#00B894' : '#FF6B6B')
            }
            .width('100%')
            .padding(16)

            // 进度条
            Row()
                .width(stat.percentage + '%')
                .height(4)
                .backgroundColor(stat.type === BillType.INCOME ? '#00B894' : '#FF6B6B')
                .borderRadius(2)

            Divider()
                .margin({ top: 8 })
        }
        .width('100%')
        .onClick(() => {
            // 跳转到分类详情
            router.pushUrl({
                url: 'pages/CategoryDetailPage',
                params: {
                    category: stat.category,
                    year: this.selectedYear,
                    month: this.selectedMonth
                }
            });
        })
    }

    // 获取分类图标
    getCategoryIcon(categoryName: string, type: BillType): string {
        const category = DEFAULT_CATEGORIES.find(cat => cat.name === categoryName && cat.type === type);
        return category ? category.icon : '📝';
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
        this.loadStatistics();
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
        this.loadStatistics();
    }
}
