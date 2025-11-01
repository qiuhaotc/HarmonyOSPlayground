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

// 路由参数接口
interface RouteParams {
    category: string;
    year: string;
    month?: string;
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
    @State statisticsMode: 'month' | 'year' | 'all' = 'month'; // 统计模式：按月、按年或全部
    private billDb: BillDatabase = BillDatabase.getInstance();

    aboutToAppear() {
        this.loadStatistics();
    }

    // 页面每次显示时刷新数据
    onPageShow() {
        this.loadStatistics();
    }

    // 加载统计数据
    async loadStatistics() {
        try {
            if (this.statisticsMode === 'month') {
                this.bills = await this.billDb.queryBillsByYearMonth(this.selectedYear, this.selectedMonth);
            } else if (this.statisticsMode === 'year') {
                this.bills = await this.billDb.queryBillsByYear(this.selectedYear);
            } else {
                // 全部统计
                this.bills = await this.billDb.queryAllBills();
            }
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

            // 可滚动内容区域
            Scroll() {
                Column() {
                    // 日期选择器
                    this.buildDateSelector();

                    // 总览卡片
                    this.buildOverviewCard();

                    // 分类统计列表
                    this.buildCategoryStatsList();
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
        Column() {
            // 模式切换按钮
            Row() {
                Button(this.statisticsMode === 'month' ? '按月' : (this.statisticsMode === 'year' ? '按年' : '全部'))
                    .fontSize(14)
                    .fontColor('#007DFF')
                    .backgroundColor('#E6F2FF')
                    .height(32)
                    .onClick(() => {
                        if (this.statisticsMode === 'month') {
                            this.statisticsMode = 'year';
                        } else if (this.statisticsMode === 'year') {
                            this.statisticsMode = 'all';
                        } else {
                            this.statisticsMode = 'month';
                        }
                        this.loadStatistics();
                    })
            }
            .width('100%')
            .padding({
                left: 16,
                right: 16,
                top: 12,
                bottom: 8
            })
            .justifyContent(FlexAlign.End)

            // 日期选择器 (仅在按月或按年模式下显示)
            if (this.statisticsMode !== 'all') {
                Row() {
                    Button('<')
                        .fontSize(18)
                        .fontColor('#333333')
                        .backgroundColor('#F0F0F0')
                        .width(40)
                        .height(40)
                        .onClick(() => {
                            if (this.statisticsMode === 'month') {
                                this.previousMonth();
                            } else {
                                this.previousYear();
                            }
                        })

                    Text(this.statisticsMode === 'month'
                        ? DateUtil.formatYearMonth(`${this.selectedYear}-${this.selectedMonth}`)
                        : `${this.selectedYear}年`)
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
                        if (this.statisticsMode === 'month') {
                            this.nextMonth();
                        } else {
                            this.nextYear();
                        }
                    })
                }
                .width('100%')
                .padding({ left: 16, right: 16, bottom: 12 })
            } else {
                // 全部统计模式下显示提示文本
                Text('全部账单统计')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(12)
            }
        }
        .width('100%')
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
                Column() {
                    ForEach(this.categoryStats, (stat: CategoryStatItem) => {
                        this.buildCategoryItem(stat);
                    })
                }
                .width('100%')
            }
        }
        .width('100%')
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
            let params: RouteParams = {
                category: stat.category,
                year: this.selectedYear
            };
            if (this.statisticsMode === 'month') {
                // 按月统计时传递月份参数
                params.month = this.selectedMonth;
            } else if (this.statisticsMode === 'all') {
                // 全部统计时不传递年份,通过year为空字符串标识
                params.year = '';
            }
            // 按年统计时只传递年份
            router.pushUrl({
                url: 'pages/CategoryDetailPage',
                params: params
            } as router.RouterOptions);
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

    // 上一年
    previousYear() {
        let year = parseInt(this.selectedYear);
        year--;
        this.selectedYear = String(year);
        this.loadStatistics();
    }

    // 下一年
    nextYear() {
        let year = parseInt(this.selectedYear);
        year++;
        this.selectedYear = String(year);
        this.loadStatistics();
    }
}
