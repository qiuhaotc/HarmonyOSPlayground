import { BillType } from './BillModel';

/**
 * 定期记账重复类型
 */
export enum RecurringType {
  DAILY = 'daily',     // 按天
  WEEKLY = 'weekly',   // 按周
  MONTHLY = 'monthly'  // 按月
}

/**
 * 定期记账配置模型
 */
export class RecurringBillConfig {
  id?: number;                    // 配置ID
  amount: number = 0;             // 金额
  type: BillType = BillType.EXPENSE; // 类型
  category: string = '';          // 分类
  note: string = '';              // 备注
  recurringType: RecurringType = RecurringType.DAILY; // 重复类型
  interval: number = 1;           // 间隔（如每2天、每3周）
  repeatCount?: number;           // 重复次数（可选）
  endDate?: string;               // 截止日期（可选，格式: YYYY-MM-DD）
  startDate: string = '';         // 开始日期（格式: YYYY-MM-DD）
  lastGeneratedDate?: string;     // 最后生成日期（格式: YYYY-MM-DD）
  isActive: boolean = true;       // 是否启用
  createTime: string = '';        // 创建时间

  constructor(
    amount: number,
    type: BillType,
    category: string,
    recurringType: RecurringType,
    interval: number,
    startDate: string,
    note: string = '',
    repeatCount?: number,
    endDate?: string
  ) {
    this.amount = amount;
    this.type = type;
    this.category = category;
    this.recurringType = recurringType;
    this.interval = interval;
    this.startDate = startDate;
    this.note = note;
    this.repeatCount = repeatCount;
    this.endDate = endDate;
    this.createTime = new Date().toISOString();
    this.isActive = true;
  }

  /**
   * 获取重复类型的中文描述
   */
  getRecurringTypeText(): string {
    switch (this.recurringType) {
      case RecurringType.DAILY:
        return this.interval === 1 ? '每天' : `每${this.interval}天`;
      case RecurringType.WEEKLY:
        return this.interval === 1 ? '每周' : `每${this.interval}周`;
      case RecurringType.MONTHLY:
        return this.interval === 1 ? '每月' : `每${this.interval}月`;
      default:
        return '未知';
    }
  }

  /**
   * 获取结束条件描述
   */
  getEndConditionText(): string {
    if (this.endDate) {
      return `截止到${this.endDate}`;
    }
    if (this.repeatCount) {
      return `重复${this.repeatCount}次`;
    }
    return '永久';
  }
}

/**
 * 定期账单生成记录模型（软外键）
 */
export class GeneratedBillRecord {
  id?: number;                    // 记录ID
  recurringConfigId: number = 0;  // 关联的定期配置ID（软外键）
  generatedDate: string = '';     // 生成的账单日期（格式: YYYY-MM-DD）
  billId: number = 0;             // 生成的账单ID（软外键）
  createTime: string = '';        // 创建时间

  constructor(recurringConfigId: number, generatedDate: string, billId: number) {
    this.recurringConfigId = recurringConfigId;
    this.generatedDate = generatedDate;
    this.billId = billId;
    this.createTime = new Date().toISOString();
  }
}
