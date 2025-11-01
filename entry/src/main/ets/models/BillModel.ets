/**
 * 账单类型枚举
 */
export enum BillType {
  INCOME = 'income',  // 收入
  EXPENSE = 'expense' // 支出
}

/**
 * 账单分类
 */
export class BillCategory {
  id: number = 0;
  name: string = '';
  type: BillType = BillType.EXPENSE;
  icon: string = '';
  color: string = '';

  constructor(id: number, name: string, type: BillType, icon: string = '', color: string = '') {
    this.id = id;
    this.name = name;
    this.type = type;
    this.icon = icon;
    this.color = color;
  }
}

/**
 * 账单数据模型
 */
export class BillModel {
  id?: number; // 数据库自增ID
  amount: number = 0; // 金额
  type: BillType = BillType.EXPENSE; // 类型
  category: string = ''; // 分类
  date: string = ''; // 日期 格式: YYYY-MM-DD
  time: string = ''; // 时间 格式: HH:mm:ss
  note: string = ''; // 备注
  createTime: string = ''; // 创建时间

  constructor(amount: number, type: BillType, category: string, date: string, time: string, note: string = '') {
    this.amount = amount;
    this.type = type;
    this.category = category;
    this.date = date;
    this.time = time;
    this.note = note;
    this.createTime = new Date().toISOString();
  }

  // 获取年月 格式: YYYY-MM
  getYearMonth(): string {
    return this.date.substring(0, 7);
  }

  // 获取年份
  getYear(): string {
    return this.date.substring(0, 4);
  }

  // 获取月份
  getMonth(): string {
    return this.date.substring(5, 7);
  }
}

/**
 * 账单统计数据
 */
export class BillStatistics {
  totalIncome: number = 0; // 总收入
  totalExpense: number = 0; // 总支出
  balance: number = 0; // 结余
  categoryStats: Map<string, number> = new Map(); // 按分类统计

  constructor() {
    this.totalIncome = 0;
    this.totalExpense = 0;
    this.balance = 0;
    this.categoryStats = new Map();
  }
}

/**
 * 预定义的账单分类
 */
export const DEFAULT_CATEGORIES: BillCategory[] = [
  // 支出分类
  new BillCategory(1, '餐饮', BillType.EXPENSE, '🥢', '#FF6B6B'),
  new BillCategory(2, '交通', BillType.EXPENSE, '🚗', '#4ECDC4'),
  new BillCategory(3, '购物', BillType.EXPENSE, '🛍️', '#45B7D1'),
  new BillCategory(4, '娱乐', BillType.EXPENSE, '🎬', '#96CEB4'),
  new BillCategory(5, '医疗', BillType.EXPENSE, '💊', '#FFEAA7'),
  new BillCategory(6, '住房', BillType.EXPENSE, '🏠', '#DFE6E9'),
  new BillCategory(7, '教育', BillType.EXPENSE, '📚', '#74B9FF'),
  new BillCategory(8, '通讯', BillType.EXPENSE, '📱', '#A29BFE'),
  new BillCategory(9, '其他', BillType.EXPENSE, '📝', '#B2BEC3'),
  
  // 收入分类
  new BillCategory(10, '工资', BillType.INCOME, '💰', '#00B894'),
  new BillCategory(11, '奖金', BillType.INCOME, '🎁', '#00CEC9'),
  new BillCategory(12, '投资', BillType.INCOME, '📈', '#6C5CE7'),
  new BillCategory(13, '兼职', BillType.INCOME, '💼', '#FDCB6E'),
  new BillCategory(14, '其他', BillType.INCOME, '📝', '#B2BEC3'),
];

/**
 * 获取支出分类列表
 */
export function getExpenseCategories(): BillCategory[] {
  return DEFAULT_CATEGORIES.filter(cat => cat.type === BillType.EXPENSE);
}

/**
 * 获取收入分类列表
 */
export function getIncomeCategories(): BillCategory[] {
  return DEFAULT_CATEGORIES.filter(cat => cat.type === BillType.INCOME);
}

/**
 * 根据类型获取分类列表
 */
export function getCategoriesByType(type: BillType): BillCategory[] {
  return DEFAULT_CATEGORIES.filter(cat => cat.type === type);
}
