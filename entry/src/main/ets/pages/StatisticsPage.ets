import { BillModel, BillType, DEFAULT_CATEGORIES } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { BillStatisticsUtil, DailyStats, MonthlyTrend, CumulativeStats } from '../utils/BillStatisticsUtil';
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

// 图表类型
enum ChartType {
    BAR = 'bar',          // 柱状图
    LINE = 'line',        // 折线图
    CUMULATIVE = 'cumulative' // 累积图
}

// 趋势数据项接口
interface TrendDataItem {
    label: string;
    income: number;
    expense: number;
    balance: number;
}

// 年度统计数据接口
interface YearlyStats {
    income: number;
    expense: number;
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
    @State currentChart: ChartType = ChartType.BAR; // 当前图表类型
    @State showChart: boolean = true; // 是否显示图表
    private billDb: BillDatabase = BillDatabase.getInstance();
    
    // 图表数据缓存
    @State barChartDates: string[] = [];
    @State barChartStats: DailyStats[] = [];
    @State barChartMonthly: MonthlyTrend[] = [];
    @State barChartMaxAmount: number = 1;
    
    @State lineChartData: TrendDataItem[] = [];
    @State lineChartMaxAmount: number = 1;
    @State lineChartWidth: number = 300;
    @State lineChartIncomeData: number[] = [];
    @State lineChartExpenseData: number[] = [];
    
    @State cumulativeData: CumulativeStats[] = [];
    @State cumulativeMaxAmount: number = 1;
    @State cumulativeMinAmount: number = 0;
    @State cumulativeChartWidth: number = 300;
    @State cumulativeIncomeData: number[] = [];
    @State cumulativeExpenseData: number[] = [];
    @State cumulativeBalanceData: number[] = [];
    
    // 悬浮提示相关
    @State showTooltip: boolean = false;
    @State tooltipX: number = 0;
    @State tooltipY: number = 0;
    @State tooltipDate: string = '';
    @State tooltipIncome: number = 0;
    @State tooltipExpense: number = 0;
    @State tooltipBalance: number = 0;

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
            this.prepareChartData();
        } catch (err) {
            console.error('加载统计数据失败', JSON.stringify(err));
        }
    }

    // 准备图表数据
    prepareChartData() {
        // 准备柱状图数据
        if (this.statisticsMode === 'month') {
            // 按月：固定显示当月所有天数
            const daysInMonth = this.getDaysInMonth(parseInt(this.selectedYear), parseInt(this.selectedMonth));
            const dailyStatsMap = BillStatisticsUtil.getDailyStatistics(this.bills);
            
            this.barChartDates = [];
            this.barChartStats = [];
            
            for (let day = 1; day <= daysInMonth; day++) {
                const dateStr = `${this.selectedYear}-${this.selectedMonth.padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
                this.barChartDates.push(dateStr);
                
                const stat = dailyStatsMap.get(dateStr);
                if (stat) {
                    this.barChartStats.push(stat);
                } else {
                    // 没有数据的日期，填充0
                    this.barChartStats.push({ income: 0, expense: 0 });
                }
            }
            
            this.barChartMaxAmount = 1;
            this.barChartStats.forEach((stat: DailyStats) => {
                const max = Math.max(stat.income, stat.expense);
                if (max > this.barChartMaxAmount) {
                    this.barChartMaxAmount = max;
                }
            });
        } else if (this.statisticsMode === 'year') {
            // 按年：固定显示1-12月
            const monthlyMap = new Map<string, MonthlyTrend>();
            const trends = BillStatisticsUtil.getMonthlyTrend(this.bills, 12);
            trends.forEach((trend: MonthlyTrend) => {
                monthlyMap.set(trend.yearMonth, trend);
            });
            
            this.barChartMonthly = [];
            for (let month = 1; month <= 12; month++) {
                const yearMonth = `${this.selectedYear}-${month.toString().padStart(2, '0')}`;
                const trend = monthlyMap.get(yearMonth);
                if (trend) {
                    this.barChartMonthly.push(trend);
                } else {
                    // 没有数据的月份，填充0
                    this.barChartMonthly.push({
                        yearMonth: yearMonth,
                        income: 0,
                        expense: 0,
                        balance: 0
                    });
                }
            }
            
            this.barChartMaxAmount = 1;
            this.barChartMonthly.forEach((data: MonthlyTrend) => {
                const max = Math.max(data.income, data.expense);
                if (max > this.barChartMaxAmount) {
                    this.barChartMaxAmount = max;
                }
            });
        } else {
            // 全部：显示所有年份
            const yearlyMap = new Map<string, YearlyStats>();
            this.bills.forEach((bill: BillModel) => {
                const year = bill.date.substring(0, 4);
                if (!yearlyMap.has(year)) {
                    const stats: YearlyStats = { income: 0, expense: 0 };
                    yearlyMap.set(year, stats);
                }
                const data = yearlyMap.get(year)!;
                if (bill.type === BillType.INCOME) {
                    data.income += bill.amount;
                } else {
                    data.expense += bill.amount;
                }
            });
            
            // 找出最早和最晚年份
            const years = Array.from(yearlyMap.keys()).sort();
            if (years.length > 0) {
                const startYear = parseInt(years[0]);
                const endYear = new Date().getFullYear();
                
                this.barChartMonthly = [];
                for (let year = startYear; year <= endYear; year++) {
                    const yearStr = year.toString();
                    const data = yearlyMap.get(yearStr);
                    if (data) {
                        this.barChartMonthly.push({
                            yearMonth: yearStr,
                            income: data.income,
                            expense: data.expense,
                            balance: data.income - data.expense
                        });
                    } else {
                        this.barChartMonthly.push({
                            yearMonth: yearStr,
                            income: 0,
                            expense: 0,
                            balance: 0
                        });
                    }
                }
            }
            
            this.barChartMaxAmount = 1;
            this.barChartMonthly.forEach((data: MonthlyTrend) => {
                const max = Math.max(data.income, data.expense);
                if (max > this.barChartMaxAmount) {
                    this.barChartMaxAmount = max;
                }
            });
        }
        
        // 准备折线图数据 (使用与柱状图相同的数据)
        this.lineChartData = [];
        if (this.statisticsMode === 'month') {
            // 按月：使用固定天数数据
            this.barChartDates.forEach((date: string, index: number) => {
                const stats = this.barChartStats[index];
                const item: TrendDataItem = {
                    label: date.split('-')[2] + '日',
                    income: stats.income,
                    expense: stats.expense,
                    balance: stats.income - stats.expense
                };
                this.lineChartData.push(item);
            });
        } else {
            // 按年或全部：使用固定月份/年份数据
            this.barChartMonthly.forEach((data: MonthlyTrend) => {
                const item: TrendDataItem = {
                    label: this.statisticsMode === 'year' ? data.yearMonth.split('-')[1] + '月' : data.yearMonth,
                    income: data.income,
                    expense: data.expense,
                    balance: data.balance
                };
                this.lineChartData.push(item);
            });
        }
        
        this.lineChartMaxAmount = 1;
        this.lineChartData.forEach((d: TrendDataItem) => {
            const max = Math.max(d.income, d.expense);
            if (max > this.lineChartMaxAmount) {
                this.lineChartMaxAmount = max;
            }
        });
        
        // 使用统一的精度调整最大值(与累积图相同的逻辑)
        if (this.lineChartMaxAmount < 10) {
            this.lineChartMaxAmount = Math.ceil(this.lineChartMaxAmount);
        } else {
            const magnitude = Math.pow(10, Math.floor(Math.log10(this.lineChartMaxAmount)));
            const normalized = this.lineChartMaxAmount / magnitude;
            let nice: number;
            if (normalized <= 1) nice = 1;
            else if (normalized <= 2) nice = 2;
            else if (normalized <= 3) nice = 3;
            else if (normalized <= 4) nice = 4;
            else if (normalized <= 5) nice = 5;
            else nice = 10;
            this.lineChartMaxAmount = nice * magnitude;
        }
        
        this.lineChartWidth = Math.max(300, this.lineChartData.length * 40);
        
        // 准备折线图绘制数据
        this.lineChartIncomeData = [];
        this.lineChartExpenseData = [];
        this.lineChartData.forEach((item: TrendDataItem) => {
            this.lineChartIncomeData.push(item.income);
            this.lineChartExpenseData.push(item.expense);
        });
        
        // 准备累积图数据（与柱状图横坐标一致）
        const allCumulativeData = BillStatisticsUtil.getCumulativeStatistics(this.bills);
        const cumulativeMap = new Map<string, CumulativeStats>();
        allCumulativeData.forEach((item: CumulativeStats) => {
            cumulativeMap.set(item.date, item);
        });
        
        this.cumulativeData = [];
        if (this.statisticsMode === 'month') {
            // 按月：与固定天数对应
            let cumulativeIncome = 0;
            let cumulativeExpense = 0;
            this.barChartDates.forEach((date: string) => {
                const data = cumulativeMap.get(date);
                if (data) {
                    cumulativeIncome = data.cumulativeIncome;
                    cumulativeExpense = data.cumulativeExpense;
                }
                this.cumulativeData.push({
                    date: date,
                    cumulativeIncome: cumulativeIncome,
                    cumulativeExpense: cumulativeExpense,
                    cumulativeBalance: cumulativeIncome - cumulativeExpense
                });
            });
        } else {
            // 按年或全部：与固定月份/年份对应
            let cumulativeIncome = 0;
            let cumulativeExpense = 0;
            this.barChartMonthly.forEach((monthData: MonthlyTrend) => {
                // 找到该时间段的最后累积值
                let lastCumulativeIncome = cumulativeIncome;
                let lastCumulativeExpense = cumulativeExpense;
                
                allCumulativeData.forEach((cumData: CumulativeStats) => {
                    if (this.statisticsMode === 'year') {
                        // 按年：比较月份
                        if (cumData.date.substring(0, 7) === monthData.yearMonth) {
                            lastCumulativeIncome = cumData.cumulativeIncome;
                            lastCumulativeExpense = cumData.cumulativeExpense;
                        }
                    } else {
                        // 全部：比较年份
                        if (cumData.date.substring(0, 4) === monthData.yearMonth) {
                            lastCumulativeIncome = cumData.cumulativeIncome;
                            lastCumulativeExpense = cumData.cumulativeExpense;
                        }
                    }
                });
                
                cumulativeIncome = lastCumulativeIncome;
                cumulativeExpense = lastCumulativeExpense;
                
                this.cumulativeData.push({
                    date: monthData.yearMonth,
                    cumulativeIncome: cumulativeIncome,
                    cumulativeExpense: cumulativeExpense,
                    cumulativeBalance: cumulativeIncome - cumulativeExpense
                });
            });
        }
        
        // 准备累积图绘制数据（先转换数据）
        this.cumulativeIncomeData = [];
        this.cumulativeExpenseData = [];
        this.cumulativeBalanceData = [];
        
        this.cumulativeData.forEach((item: CumulativeStats) => {
            // 收入保持正值
            this.cumulativeIncomeData.push(item.cumulativeIncome);
            // 支出转为负值显示
            this.cumulativeExpenseData.push(-item.cumulativeExpense);
            // 结余 = 收入 - 支出（可正可负）
            this.cumulativeBalanceData.push(item.cumulativeBalance);
        });
        
        // 计算累积图的Y轴范围（对称范围）
        // 找出累积收入的最大值和累积支出的最大绝对值
        let maxIncome = 0;
        let maxExpense = 0;
        
        this.cumulativeData.forEach((item: CumulativeStats) => {
            if (item.cumulativeIncome > maxIncome) {
                maxIncome = item.cumulativeIncome;
            }
            if (item.cumulativeExpense > maxExpense) {
                maxExpense = item.cumulativeExpense;
            }
        });
        
        // 取收入和支出的最大值作为对称范围的基准
        const maxValue = Math.max(maxIncome, maxExpense);
        
        if (maxValue === 0) {
            // 没有数据
            this.cumulativeMaxAmount = 100;
            this.cumulativeMinAmount = -100;
        } else {
            // 将最大值向上取整,确保能被2整除(因为要显示max/2的刻度)
            let niceMax: number;
            if (maxValue < 10) {
                // 小于10,向上取到偶数
                niceMax = Math.ceil(maxValue / 2) * 2;
            } else {
                // 找到合适的数量级
                const magnitude = Math.pow(10, Math.floor(Math.log10(maxValue)));
                const normalized = maxValue / magnitude;
                let nice: number;
                if (normalized <= 1) nice = 1;
                else if (normalized <= 2) nice = 2;
                else if (normalized <= 3) nice = 3;
                else if (normalized <= 4) nice = 4;
                else if (normalized <= 5) nice = 5;
                else nice = 10;
                niceMax = nice * magnitude;
            }
            
            // 设置对称的Y轴范围
            this.cumulativeMaxAmount = niceMax;
            this.cumulativeMinAmount = -niceMax;
        }
        
        this.cumulativeChartWidth = Math.max(300, this.cumulativeData.length * 40);
    }
    
    // 将数值向上取整到合适的刻度值（用于正数最大值）
    roundUpToNiceNumber(value: number): number {
        if (value <= 0) return 0;
        
        if (value < 10) {
            // 小于10的值，向上取整到整数
            return Math.ceil(value);
        }
        
        // 找到合适的刻度单位
        const magnitude = Math.pow(10, Math.floor(Math.log10(value)));
        const normalized = value / magnitude;
        
        let nice: number;
        if (normalized <= 1) nice = 1;
        else if (normalized <= 2) nice = 2;
        else if (normalized <= 5) nice = 5;
        else nice = 10;
        
        return nice * magnitude;
    }
    
    // 将数值向下取整到合适的刻度值（用于负数最小值）
    roundDownToNiceNumber(value: number): number {
        if (value >= 0) return 0;
        
        if (value > -10) {
            // 大于-10的值，向下取整到整数
            return Math.floor(value);
        }
        
        // 找到合适的刻度单位
        const magnitude = Math.pow(10, Math.floor(Math.log10(Math.abs(value))));
        const normalized = Math.abs(value) / magnitude;
        
        let nice: number;
        if (normalized <= 1) nice = 1;
        else if (normalized <= 2) nice = 2;
        else if (normalized <= 5) nice = 5;
        else nice = 10;
        
        return -nice * magnitude;
    }

    // 获取指定年月的天数
    getDaysInMonth(year: number, month: number): number {
        return new Date(year, month, 0).getDate();
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

                    // 图表切换按钮
                    this.buildChartTypeSelector();

                    // 图表展示区域
                    if (this.showChart) {
                        if (this.currentChart === ChartType.BAR) {
                            this.buildBarChart();
                        } else if (this.currentChart === ChartType.LINE) {
                            this.buildLineChart();
                        } else if (this.currentChart === ChartType.CUMULATIVE) {
                            this.buildCumulativeChart();
                        }
                    }
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

            Text('账单统计')
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
    buildDateSelector() {
        Column() {
            // 模式切换按钮
            Row() {
                Button(this.statisticsMode === 'month' ? '按月' : (this.statisticsMode === 'year' ? '按年' : '全部'))
                    .fontSize(14)
                    .fontColor($r('app.color.primary_color'))
                    .backgroundColor($r('app.color.page_background'))
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
                        .fontColor($r('app.color.text_primary'))
                        .backgroundColor($r('app.color.page_background'))
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
                        .fontColor($r('app.color.text_primary'))
                        .layoutWeight(1)
                        .textAlign(TextAlign.Center)

                Button('>')
                    .fontSize(18)
                    .fontColor($r('app.color.text_primary'))
                    .backgroundColor($r('app.color.page_background'))
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
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(12)
            }
        }
        .width('100%')
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildOverviewCard() {
        Column() {
            Row() {
                Column() {
                    Text('收入')
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome))
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.success_color'))
                        .margin({ top: 8 })
                }
                .layoutWeight(1)

                Column() {
                    Text('支出')
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalExpense))
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.danger_color'))
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
                    .fontColor($r('app.color.text_secondary'))

                Blank()

                Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome - this.totalExpense))
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor((this.totalIncome - this.totalExpense) >= 0 ? $r('app.color.success_color') : $r('app.color.danger_color'))
            }
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 12 })
        .borderRadius(8)
    }

    @Builder
    buildChartTypeSelector() {
        Column() {
            Row() {
                Text('数据可视化')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                
                Blank()
                
                Row() {
                    Button('柱状图')
                        .fontSize(12)
                        .height(32)
                        .fontColor(this.currentChart === ChartType.BAR ? '#FFFFFF' : $r('app.color.text_primary'))
                        .backgroundColor(this.currentChart === ChartType.BAR ? $r('app.color.primary_color') : $r('app.color.page_background'))
                        .onClick(() => {
                            this.currentChart = ChartType.BAR;
                        })
                    
                    Button('趋势图')
                        .fontSize(12)
                        .height(32)
                        .margin({ left: 8 })
                        .fontColor(this.currentChart === ChartType.LINE ? '#FFFFFF' : $r('app.color.text_primary'))
                        .backgroundColor(this.currentChart === ChartType.LINE ? $r('app.color.primary_color') : $r('app.color.page_background'))
                        .onClick(() => {
                            this.currentChart = ChartType.LINE;
                        })
                    
                    Button('累积图')
                        .fontSize(12)
                        .height(32)
                        .margin({ left: 8 })
                        .fontColor(this.currentChart === ChartType.CUMULATIVE ? '#FFFFFF' : $r('app.color.text_primary'))
                        .backgroundColor(this.currentChart === ChartType.CUMULATIVE ? $r('app.color.primary_color') : $r('app.color.page_background'))
                        .onClick(() => {
                            this.currentChart = ChartType.CUMULATIVE;
                        })
                }
            }
            .width('100%')
            .padding(16)
        }
        .width('100%')
        .margin({ top: 12 })
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
    }

    @Builder
    buildBarChart() {
        Column() {
            Text('收支对比柱状图')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 16 })
            
            if (this.bills.length === 0) {
                Text('暂无数据')
                    .fontSize(14)
                    .fontColor($r('app.color.text_tertiary'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(32)
            } else {
                this.buildBarChartContent();
            }
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12 })
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
    }

    @Builder
    buildBarChartContent() {
        if (this.statisticsMode === 'month') {
            // 每日柱状图
            this.buildDailyBarChart();
        } else {
            // 月度柱状图
            this.buildMonthlyBarChart();
        }
    }

    @Builder
    buildDailyBarChart() {
        Stack() {
            Scroll() {
                Row() {
                    ForEach(this.barChartDates, (date: string, index: number) => {
                        Column() {
                            // 收入区域 (固定高度100px)
                            Column() {
                                // 收入金额文本
                                Text('¥' + this.barChartStats[index].income.toFixed(0))
                                    .fontSize(10)
                                    .fontColor($r('app.color.success_color'))
                                    .margin({ bottom: 4 })
                                
                                Blank()
                                
                                // 收入柱 (从底部向上)
                                Column()
                                    .width(20)
                                    .height((this.barChartStats[index].income / this.barChartMaxAmount * 90) + 10)
                                    .backgroundColor($r('app.color.success_color'))
                                    .borderRadius(4)
                            }
                            .height(100)
                            .justifyContent(FlexAlign.End)
                            
                            // 横坐标日期 (固定位置)
                            Text(date.split('-')[2] + '日')
                                .fontSize(10)
                                .fontWeight(FontWeight.Medium)
                                .fontColor($r('app.color.text_primary'))
                                .margin({ top: 4, bottom: 4 })
                            
                            // 支出区域 (固定高度100px)
                            Column() {
                                // 支出柱 (从顶部向下)
                                Column()
                                    .width(20)
                                    .height((this.barChartStats[index].expense / this.barChartMaxAmount * 90) + 10)
                                    .backgroundColor($r('app.color.danger_color'))
                                    .borderRadius(4)
                                
                                Blank()
                                
                                // 支出金额文本
                                Text('¥' + this.barChartStats[index].expense.toFixed(0))
                                    .fontSize(10)
                                    .fontColor($r('app.color.danger_color'))
                                    .margin({ top: 4 })
                            }
                            .height(100)
                            .justifyContent(FlexAlign.Start)
                        }
                        .height(220)
                        .margin({ right: 12 })
                        .onClick(() => {
                            this.showDataTooltip(
                                date,
                                this.barChartStats[index].income,
                                this.barChartStats[index].expense
                            );
                        })
                    })
                }
                .padding(16)
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Auto)
            .width('100%')
            
            // 悬浮提示
            if (this.showTooltip) {
                this.buildTooltip();
            }
        }
    }

    @Builder
    buildMonthlyBarChart() {
        Stack() {
            Scroll() {
                Row() {
                    ForEach(this.barChartMonthly, (data: MonthlyTrend) => {
                        Column() {
                            // 收入区域 (固定高度130px)
                            Column() {
                                // 收入金额文本
                                Text('¥' + data.income.toFixed(0))
                                    .fontSize(10)
                                    .fontColor($r('app.color.success_color'))
                                    .margin({ bottom: 4 })
                                
                                Blank()
                                
                                // 收入柱 (从底部向上)
                                Column()
                                    .width(24)
                                    .height((data.income / this.barChartMaxAmount * 110) + 20)
                                    .backgroundColor($r('app.color.success_color'))
                                    .borderRadius(4)
                            }
                            .height(130)
                            .justifyContent(FlexAlign.End)
                            
                            // 横坐标标签 (固定位置)
                            Text(this.statisticsMode === 'year' ? (data.yearMonth.split('-')[1] + '月') : data.yearMonth)
                                .fontSize(10)
                                .fontWeight(FontWeight.Medium)
                                .fontColor($r('app.color.text_primary'))
                                .margin({ top: 4, bottom: 4 })
                            
                            // 支出区域 (固定高度130px)
                            Column() {
                                // 支出柱 (从顶部向下)
                                Column()
                                    .width(24)
                                    .height((data.expense / this.barChartMaxAmount * 110) + 20)
                                    .backgroundColor($r('app.color.danger_color'))
                                    .borderRadius(4)
                                
                                Blank()
                                
                                // 支出金额文本
                                Text('¥' + data.expense.toFixed(0))
                                    .fontSize(10)
                                    .fontColor($r('app.color.danger_color'))
                                    .margin({ top: 4 })
                            }
                            .height(130)
                            .justifyContent(FlexAlign.Start)
                        }
                        .height(280)
                        .margin({ right: 12 })
                        .onClick(() => {
                            this.showDataTooltip(
                                data.yearMonth,
                                data.income,
                                data.expense
                            );
                        })
                    })
                }
                .padding(16)
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Auto)
            .width('100%')
            
            // 悬浮提示
            if (this.showTooltip) {
                this.buildTooltip();
            }
        }
        
        // 图例
        Row() {
            Row() {
                Column()
                    .width(12)
                    .height(12)
                    .backgroundColor($r('app.color.success_color'))
                    .borderRadius(2)
                    .margin({ right: 4 })
                Text('收入')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
            .margin({ right: 16 })
            
            Row() {
                Column()
                    .width(12)
                    .height(12)
                    .backgroundColor($r('app.color.danger_color'))
                    .borderRadius(2)
                    .margin({ right: 4 })
                Text('支出')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 16 })
    }

    @Builder
    buildLineChart() {
        Column() {
            Text('收支趋势折线图')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 16 })
            
            if (this.bills.length === 0) {
                Text('暂无数据')
                    .fontSize(14)
                    .fontColor($r('app.color.text_tertiary'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(32)
            } else {
                this.buildLineChartContent();
            }
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12 })
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
    }

    @Builder
    buildLineChartContent() {
        Stack() {
            Row() {
                // Y轴刻度
                Column() {
                    Text(this.formatYAxisLabel(this.lineChartMaxAmount))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text(this.formatYAxisLabel(this.lineChartMaxAmount * 0.75))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text(this.formatYAxisLabel(this.lineChartMaxAmount * 0.5))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text(this.formatYAxisLabel(this.lineChartMaxAmount * 0.25))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text('0')
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                }
                .width(40)
                .height(150)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.End)
                .padding({ right: 8, top: 5, bottom: 5 })
                
                // 图表区域
                Scroll() {
                    Column() {
                        // 折线图区域
                        Stack() {
                            // 绘制水平虚线网格
                            Column() {
                                // 最大值线
                                Row().width('100%').height(1).backgroundColor('#E0E0E0')
                                Blank()
                                // 75%线
                                Row().width('100%').height(1).backgroundColor('#F0F0F0')
                                Blank()
                                // 50%线
                                Row().width('100%').height(1).backgroundColor('#E0E0E0')
                                Blank()
                                // 25%线
                                Row().width('100%').height(1).backgroundColor('#F0F0F0')
                                Blank()
                                // 0线
                                Row().width('100%').height(1).backgroundColor('#E0E0E0')
                            }
                            .width(this.lineChartWidth)
                            .height(150)
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ top: 5, bottom: 5 })
                            
                            // 收入折线
                            this.buildIncomePolyline();
                            
                            // 支出折线
                            this.buildExpensePolyline();
                            
                            // 交互区域
                            Row() {
                                ForEach(this.lineChartData, (data: TrendDataItem, index: number) => {
                                    Column()
                                        .width(40)
                                        .height(150)
                                        .onClick(() => {
                                            const dateStr = this.statisticsMode === 'month' 
                                                ? this.barChartDates[index]
                                                : (this.statisticsMode === 'year' 
                                                    ? this.barChartMonthly[index].yearMonth
                                                    : this.barChartMonthly[index].yearMonth);
                                            this.showDataTooltip(
                                                dateStr,
                                                data.income,
                                                data.expense
                                            );
                                        })
                                })
                            }
                            .width(this.lineChartWidth)
                            .height(150)
                        }
                        .width(this.lineChartWidth)
                        .height(150)
                        .margin({ bottom: 8 })
                        
                        // X轴标签
                        Row() {
                            ForEach(this.lineChartData, (data: TrendDataItem) => {
                                Text(data.label)
                                    .fontSize(10)
                                    .fontColor($r('app.color.text_tertiary'))
                                    .width(40)
                                    .textAlign(TextAlign.Center)
                            })
                        }
                        .width(this.lineChartWidth)
                    }
                    .padding({ left: 8, right: 16, top: 16, bottom: 16 })
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Auto)
                .layoutWeight(1)
            }
            .width('100%')
            
            // 悬浮提示
            if (this.showTooltip) {
                this.buildTooltip();
            }
        }
        
        // 图例
        Row() {
            Row() {
                Column()
                    .width(20)
                    .height(2)
                    .backgroundColor($r('app.color.success_color'))
                    .margin({ right: 4 })
                Text('收入')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
            .margin({ right: 16 })
            
            Row() {
                Column()
                    .width(20)
                    .height(2)
                    .backgroundColor($r('app.color.danger_color'))
                    .margin({ right: 4 })
                Text('支出')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 16 })
    }

    // 显示数据提示
    showDataTooltip(date: string, income: number, expense: number) {
        this.tooltipDate = date;
        this.tooltipIncome = income;
        this.tooltipExpense = expense;
        this.tooltipBalance = income - expense;
        this.showTooltip = true;
        
        // 3秒后自动隐藏
        setTimeout(() => {
            this.showTooltip = false;
        }, 3000);
    }

    // 悬浮提示框
    @Builder
    buildTooltip() {
        Column() {
            Text(this.tooltipDate)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })
            
            Row() {
                Text('收入: ')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                Text('¥' + this.tooltipIncome.toFixed(2))
                    .fontSize(12)
                    .fontColor($r('app.color.success_color'))
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ bottom: 4 })
            
            Row() {
                Text('支出: ')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                Text('¥' + this.tooltipExpense.toFixed(2))
                    .fontSize(12)
                    .fontColor($r('app.color.danger_color'))
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .margin({ bottom: 4 })
            
            Row() {
                Text('结余: ')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                Text('¥' + this.tooltipBalance.toFixed(2))
                    .fontSize(12)
                    .fontColor(this.tooltipBalance >= 0 ? $r('app.color.success_color') : $r('app.color.danger_color'))
                    .fontWeight(FontWeight.Medium)
            }
            .width('100%')
        }
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 2 })
        .position({ x: '50%', y: 20 })
        .translate({ x: '-50%', y: 0 })
        .zIndex(999)
        .onClick(() => {
            this.showTooltip = false;
        })
    }

    // 计算折线图坐标点（仅用于趋势图，值都是正数）
    calculatePolylinePoints(data: number[], maxAmount: number, width: number, height: number): Array<[number, number]> {
        const points: Array<[number, number]> = [];
        
        if (data.length < 2) {
            return points;
        }
        
        const stepX = width / (data.length - 1);
        const padding = 5; // 上下留5px边距
        const availableHeight = height - padding * 2;
        
        for (let index = 0; index < data.length; index++) {
            const value = data[index];
            const x = index * stepX;
            // 使用绝对值计算位置，确保在可用高度内
            const ratio = Math.abs(value) / maxAmount;
            const y = padding + availableHeight * (1 - ratio);
            points.push([x, y]);
        }
        
        return points;
    }

    // 计算累积图坐标点（支持正负值）
    calculateCumulativePolylinePoints(data: number[], maxAmount: number, minAmount: number, width: number, height: number): Array<[number, number]> {
        const points: Array<[number, number]> = [];
        
        if (data.length < 2) {
            return points;
        }
        
        const stepX = width / (data.length - 1);
        const padding = 5; // 上下留5px边距
        const availableHeight = height - padding * 2;
        const range = maxAmount - minAmount; // 总范围
        
        for (let index = 0; index < data.length; index++) {
            const value = data[index];
            const x = index * stepX;
            // 计算值在总范围内的相对位置
            // maxAmount在顶部，minAmount在底部，0在中间
            const ratio = (maxAmount - value) / range;
            const y = padding + availableHeight * ratio;
            points.push([x, y]);
        }
        
        return points;
    }

    @Builder
    buildIncomePolyline() {
        if (this.lineChartIncomeData.length > 1) {
            Polyline({ width: this.lineChartWidth, height: 150 })
                .points(this.calculatePolylinePoints(this.lineChartIncomeData, this.lineChartMaxAmount, this.lineChartWidth, 150))
                .stroke($r('app.color.success_color'))
                .strokeWidth(2)
                .fill('transparent')
        }
    }

    @Builder
    buildExpensePolyline() {
        if (this.lineChartExpenseData.length > 1) {
            Polyline({ width: this.lineChartWidth, height: 150 })
                .points(this.calculatePolylinePoints(this.lineChartExpenseData, this.lineChartMaxAmount, this.lineChartWidth, 150))
                .stroke($r('app.color.danger_color'))
                .strokeWidth(2)
                .fill('transparent')
        }
    }

    @Builder
    buildCumulativeIncomePolyline() {
        if (this.cumulativeIncomeData.length > 1) {
            Polyline({ width: this.cumulativeChartWidth, height: 180 })
                .points(this.calculateCumulativePolylinePoints(this.cumulativeIncomeData, this.cumulativeMaxAmount, this.cumulativeMinAmount, this.cumulativeChartWidth, 180))
                .stroke($r('app.color.success_color'))
                .strokeWidth(2)
                .fill('transparent')
        }
    }

    @Builder
    buildCumulativeExpensePolyline() {
        if (this.cumulativeExpenseData.length > 1) {
            Polyline({ width: this.cumulativeChartWidth, height: 180 })
                .points(this.calculateCumulativePolylinePoints(this.cumulativeExpenseData, this.cumulativeMaxAmount, this.cumulativeMinAmount, this.cumulativeChartWidth, 180))
                .stroke($r('app.color.danger_color'))
                .strokeWidth(2)
                .fill('transparent')
        }
    }

    @Builder
    buildCumulativeBalancePolyline() {
        if (this.cumulativeBalanceData.length > 1) {
            Polyline({ width: this.cumulativeChartWidth, height: 180 })
                .points(this.calculateCumulativePolylinePoints(this.cumulativeBalanceData, this.cumulativeMaxAmount, this.cumulativeMinAmount, this.cumulativeChartWidth, 180))
                .stroke($r('app.color.primary_color'))
                .strokeWidth(2)
                .fill('transparent')
        }
    }

    @Builder
    buildCumulativeChart() {
        Column() {
            Text('累积收支曲线')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ bottom: 16 })
            
            if (this.bills.length === 0) {
                Text('暂无数据')
                    .fontSize(14)
                    .fontColor($r('app.color.text_tertiary'))
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding(32)
            } else {
                this.buildCumulativeChartContent();
            }
        }
        .width('100%')
        .padding(16)
        .margin({ top: 12 })
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
    }

    @Builder
    buildCumulativeChartContent() {
        Stack() {
            Row() {
                // Y轴刻度（从上到下：最大值→0→最小值）
                Column() {
                    Text(this.formatYAxisLabel(this.cumulativeMaxAmount))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text(this.formatYAxisLabel(this.cumulativeMaxAmount * 0.5))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text('0')
                        .fontSize(11)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.text_primary'))

                    Blank()
                    
                    Text(this.formatYAxisLabel(this.cumulativeMinAmount * 0.5))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    
                    Blank()
                    
                    Text(this.formatYAxisLabel(this.cumulativeMinAmount))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                }
                .width(40)
                .height(180)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(HorizontalAlign.End)
                .padding({ right: 8, top: 5, bottom: 5 })
                
                // 图表区域
                Scroll() {
                    Column() {
                        // 累积图区域
                        Stack() {
                            // 绘制水平虚线网格
                            Column() {
                                Row().width('100%').height(1).backgroundColor('#E0E0E0')
                                Blank()
                                Row().width('100%').height(1).backgroundColor('#F0F0F0')
                                Blank()
                                Row().width('100%').height(2).backgroundColor('#CCCCCC') // 0轴加粗
                                Blank()
                                Row().width('100%').height(1).backgroundColor('#F0F0F0')
                                Blank()
                                Row().width('100%').height(1).backgroundColor('#E0E0E0')
                            }
                            .width(this.cumulativeChartWidth)
                            .height(180)
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ top: 5, bottom: 5 })
                            
                            // 累积收入线（正值）
                            this.buildCumulativeIncomePolyline();
                            
                            // 累积支出线（负值）
                            this.buildCumulativeExpensePolyline();
                            
                            // 累积结余线
                            this.buildCumulativeBalancePolyline();
                            
                            // 交互区域
                            Row() {
                                ForEach(this.cumulativeData, (data: CumulativeStats, index: number) => {
                                    Column()
                                        .width(40)
                                        .height(180)
                                        .onClick(() => {
                                            this.showDataTooltip(
                                                data.date,
                                                data.cumulativeIncome,
                                                data.cumulativeExpense
                                            );
                                        })
                                })
                            }
                            .width(this.cumulativeChartWidth)
                            .height(180)
                        }
                        .width(this.cumulativeChartWidth)
                        .height(180)
                        .margin({ bottom: 8 })
                        
                        // X轴标签
                        Row() {
                            ForEach(this.cumulativeData, (data: CumulativeStats) => {
                                Text(this.statisticsMode === 'month' 
                                    ? data.date.split('-')[2] + '日'
                                    : (this.statisticsMode === 'year' 
                                        ? data.date.split('-')[1] + '月'
                                        : data.date))
                                    .fontSize(10)
                                    .fontColor($r('app.color.text_tertiary'))
                                    .width(40)
                                    .textAlign(TextAlign.Center)
                            })
                        }
                        .width(this.cumulativeChartWidth)
                    }
                    .padding({ left: 8, right: 16, top: 16, bottom: 16 })
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Auto)
                .layoutWeight(1)
            }
            .width('100%')
        }
        
        // 当前累积值
        if (this.cumulativeData.length > 0) {
            Row() {
                Text(`累积收入: ¥${BillStatisticsUtil.formatAmount(this.cumulativeData[this.cumulativeData.length - 1].cumulativeIncome)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.success_color'))
                    .margin({ right: 16 })
                
                Text(`累积支出: ¥${BillStatisticsUtil.formatAmount(this.cumulativeData[this.cumulativeData.length - 1].cumulativeExpense)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.danger_color'))
                    .margin({ right: 16 })
                
                Text(`累积结余: ¥${BillStatisticsUtil.formatAmount(this.cumulativeData[this.cumulativeData.length - 1].cumulativeBalance)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.primary_color'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 16 })
        }
        
        // 图例
        Row() {
            Row() {
                Column()
                    .width(20)
                    .height(2)
                    .backgroundColor($r('app.color.success_color'))
                    .margin({ right: 4 })
                Text('累积收入')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
            .margin({ right: 12 })
            
            Row() {
                Column()
                    .width(20)
                    .height(2)
                    .backgroundColor($r('app.color.danger_color'))
                    .margin({ right: 4 })
                Text('累积支出')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
            .margin({ right: 12 })
            
            Row() {
                Column()
                    .width(20)
                    .height(2)
                    .backgroundColor($r('app.color.primary_color'))
                    .margin({ right: 4 })
                Text('累积结余')
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
            }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 16 })
        
        // 悬浮提示
        if (this.showTooltip) {
            this.buildTooltip();
        }
    }

    @Builder
    buildCategoryStatsList() {
        Column() {
            Text('分类统计')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding({ left: 16, top: 16, bottom: 8 })

            if (this.categoryStats.length === 0) {
                Text('暂无数据')
                    .fontSize(14)
                    .fontColor($r('app.color.text_tertiary'))
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
        .backgroundColor($r('app.color.card_background'))
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
                        .fontColor($r('app.color.text_primary'))

                    Text(stat.percentage + '%')
                        .fontSize(12)
                        .fontColor($r('app.color.text_tertiary'))
                        .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('¥' + BillStatisticsUtil.formatAmount(stat.amount))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(stat.type === BillType.INCOME ? $r('app.color.success_color') : $r('app.color.danger_color'))
            }
            .width('100%')
            .padding(16)

            // 进度条
            Row()
                .width(stat.percentage + '%')
                .height(4)
                .backgroundColor(stat.type === BillType.INCOME ? $r('app.color.success_color') : $r('app.color.danger_color'))
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

    // 格式化Y轴标签
    formatYAxisLabel(value: number): string {
        if (value >= 10000 || value <= -10000) {
            return (value / 10000).toFixed(1) + 'w';
        } else if (value >= 1000 || value <= -1000) {
            return (value / 1000).toFixed(1) + 'k';
        } else {
            return value.toFixed(0);
        }
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
