import { BillModel, BillType, BillStatistics } from '../models/BillModel';

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
}
