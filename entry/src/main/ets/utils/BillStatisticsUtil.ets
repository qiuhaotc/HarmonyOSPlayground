import { BillModel, BillType, BillStatistics } from '../models/BillModel';

// 每日统计接口
export interface DailyStats {
    income: number;
    expense: number;
}

// 累积统计接口
export interface CumulativeStats {
    date: string;
    cumulativeIncome: number;
    cumulativeExpense: number;
    cumulativeBalance: number;
}

// 月度趋势接口
export interface MonthlyTrend {
    yearMonth: string;
    income: number;
    expense: number;
    balance: number;
}

// 周趋势接口
export interface WeeklyTrend {
    week: string;
    income: number;
    expense: number;
    balance: number;
}

/**
 * 账单统计工具类
 */
export class BillStatisticsUtil {
    /**
     * 统计账单数据
     */
    static calculateStatistics(bills: BillModel[]): BillStatistics {
        const stats = new BillStatistics();

        bills.forEach((bill) => {
            if (bill.type === BillType.INCOME) {
                stats.totalIncome += bill.amount;
            } else {
                stats.totalExpense += bill.amount;
            }

            // 按分类统计
            const categoryAmount = stats.categoryStats.get(bill.category) || 0;
            stats.categoryStats.set(bill.category, categoryAmount + bill.amount);
        });

        stats.balance = stats.totalIncome - stats.totalExpense;
        return stats;
    }

    /**
     * 按年月分组统计
     */
    static groupByYearMonth(bills: BillModel[]): Map<string, BillModel[]> {
        const grouped = new Map<string, BillModel[]>();

        bills.forEach((bill) => {
            const yearMonth = bill.getYearMonth();
            if (!grouped.has(yearMonth)) {
                grouped.set(yearMonth, []);
            }
            grouped.get(yearMonth)?.push(bill);
        });

        return grouped;
    }

    /**
     * 按分类分组统计
     */
    static groupByCategory(bills: BillModel[]): Map<string, BillModel[]> {
        const grouped = new Map<string, BillModel[]>();

        bills.forEach((bill) => {
            if (!grouped.has(bill.category)) {
                grouped.set(bill.category, []);
            }
            grouped.get(bill.category)?.push(bill);
        });

        return grouped;
    }

    /**
     * 获取指定年月的统计数据
     */
    static getMonthlyStatistics(bills: BillModel[], year: string, month: string): BillStatistics {
        const yearMonth = `${year}-${month.padStart(2, '0')}`;
        const monthlyBills = bills.filter(bill => bill.getYearMonth() === yearMonth);
        return BillStatisticsUtil.calculateStatistics(monthlyBills);
    }

    /**
     * 获取指定分类的统计数据
     */
    static getCategoryStatistics(bills: BillModel[], category: string): BillStatistics {
        const categoryBills = bills.filter(bill => bill.category === category);
        return BillStatisticsUtil.calculateStatistics(categoryBills);
    }

    /**
     * 格式化金额
     */
    static formatAmount(amount: number): string {
        return amount.toFixed(2);
    }

    /**
     * 获取分类占比
     */
    static getCategoryPercentage(categoryAmount: number, totalAmount: number): string {
        if (totalAmount === 0) {
            return '0.00';
        }
        const percentage = (categoryAmount / totalAmount) * 100;
        return percentage.toFixed(2);
    }

    /**
     * 获取每日统计数据（用于趋势图）
     */
    static getDailyStatistics(bills: BillModel[]): Map<string, DailyStats> {
        const dailyStats = new Map<string, DailyStats>();

        bills.forEach((bill: BillModel) => {
            if (!dailyStats.has(bill.date)) {
                const newStats: DailyStats = { income: 0, expense: 0 };
                dailyStats.set(bill.date, newStats);
            }
            const stats = dailyStats.get(bill.date);
            if (stats) {
                if (bill.type === BillType.INCOME) {
                    stats.income += bill.amount;
                } else {
                    stats.expense += bill.amount;
                }
            }
        });

        return dailyStats;
    }

    /**
     * 获取累积统计数据
     */
    static getCumulativeStatistics(bills: BillModel[]): CumulativeStats[] {
        // 按日期排序
        const sortedBills = [...bills].sort((a: BillModel, b: BillModel) => a.date.localeCompare(b.date));
        
        const result: CumulativeStats[] = [];

        let cumulativeIncome = 0;
        let cumulativeExpense = 0;
        const dailyStats = BillStatisticsUtil.getDailyStatistics(sortedBills);
        
        // 获取所有日期并排序
        const dates = Array.from(dailyStats.keys()).sort();
        
        dates.forEach((date: string) => {
            const stats = dailyStats.get(date);
            if (stats) {
                cumulativeIncome += stats.income;
                cumulativeExpense += stats.expense;
                
                const item: CumulativeStats = {
                    date: date,
                    cumulativeIncome: cumulativeIncome,
                    cumulativeExpense: cumulativeExpense,
                    cumulativeBalance: cumulativeIncome - cumulativeExpense
                };
                result.push(item);
            }
        });

        return result;
    }

    /**
     * 获取月度趋势数据（最近N个月）
     */
    static getMonthlyTrend(bills: BillModel[], months: number = 12): MonthlyTrend[] {
        const monthlyMap = new Map<string, DailyStats>();

        bills.forEach((bill: BillModel) => {
            const yearMonth = bill.getYearMonth();
            if (!monthlyMap.has(yearMonth)) {
                const newStats: DailyStats = { income: 0, expense: 0 };
                monthlyMap.set(yearMonth, newStats);
            }
            const stats = monthlyMap.get(yearMonth);
            if (stats) {
                if (bill.type === BillType.INCOME) {
                    stats.income += bill.amount;
                } else {
                    stats.expense += bill.amount;
                }
            }
        });

        // 按月份排序并取最近N个月
        const entries = Array.from(monthlyMap.entries());
        entries.sort((a, b) => a[0].localeCompare(b[0]));
        
        const slicedEntries = entries.slice(-months);
        const sortedData: MonthlyTrend[] = slicedEntries.map((entry) => {
            const yearMonth = entry[0];
            const stats = entry[1];
            const trend: MonthlyTrend = {
                yearMonth: yearMonth,
                income: stats.income,
                expense: stats.expense,
                balance: stats.income - stats.expense
            };
            return trend;
        });

        return sortedData;
    }

    /**
     * 获取周趋势数据（最近N周）
     */
    static getWeeklyTrend(bills: BillModel[], weeks: number = 8): WeeklyTrend[] {
        const weeklyMap = new Map<string, DailyStats>();

        bills.forEach((bill: BillModel) => {
            const date = new Date(bill.date);
            const week = BillStatisticsUtil.getWeekString(date);
            
            if (!weeklyMap.has(week)) {
                const newStats: DailyStats = { income: 0, expense: 0 };
                weeklyMap.set(week, newStats);
            }
            const stats = weeklyMap.get(week);
            if (stats) {
                if (bill.type === BillType.INCOME) {
                    stats.income += bill.amount;
                } else {
                    stats.expense += bill.amount;
                }
            }
        });

        // 按周排序并取最近N周
        const entries = Array.from(weeklyMap.entries());
        entries.sort((a, b) => a[0].localeCompare(b[0]));
        
        const slicedEntries = entries.slice(-weeks);
        const sortedData: WeeklyTrend[] = slicedEntries.map((entry) => {
            const week = entry[0];
            const stats = entry[1];
            const trend: WeeklyTrend = {
                week: week,
                income: stats.income,
                expense: stats.expense,
                balance: stats.income - stats.expense
            };
            return trend;
        });

        return sortedData;
    }

    /**
     * 获取周字符串 (格式: YYYY-WW)
     */
    private static getWeekString(date: Date): string {
        const year = date.getFullYear();
        const startOfYear = new Date(year, 0, 1);
        const days = Math.floor((date.getTime() - startOfYear.getTime()) / (24 * 60 * 60 * 1000));
        const weekNum = Math.ceil((days + startOfYear.getDay() + 1) / 7);
        return `${year}-W${String(weekNum).padStart(2, '0')}`;
    }
}
