import { BillModel } from '../models/BillModel';
import { RecurringBillConfig, RecurringType, GeneratedBillRecord } from '../models/RecurringBillModel';
import { BillDatabase } from '../database/BillDatabase';
import { RecurringBillDatabase } from '../database/RecurringBillDatabase';

/**
 * 定期账单生成服务
 */
export class RecurringBillService {
  private static instance: RecurringBillService;
  private billDb: BillDatabase = BillDatabase.getInstance();
  private recurringDb: RecurringBillDatabase = RecurringBillDatabase.getInstance();

  private constructor() {
  }

  static getInstance(): RecurringBillService {
    if (!RecurringBillService.instance) {
      RecurringBillService.instance = new RecurringBillService();
    }
    return RecurringBillService.instance;
  }

  /**
   * 生成定期账单（在APP启动时调用）
   * @returns 生成的账单总数
   */
  async generateRecurringBills(): Promise<number> {
    try {
      console.info('RecurringBillService: 开始生成定期账单');
      
      // 获取所有活跃的定期配置
      const configs = await this.recurringDb.queryActiveConfigs();
      
      if (configs.length === 0) {
        console.info('RecurringBillService: 没有活跃的定期配置');
        return 0;
      }

      const today = this.formatDate(new Date());
      let totalGenerated = 0;

      for (const config of configs) {
        try {
          const generated = await this.generateBillsForConfig(config, today);
          totalGenerated += generated;
        } catch (err) {
          console.error(`RecurringBillService: 配置${config.id}生成账单失败`, JSON.stringify(err));
        }
      }

      console.info(`RecurringBillService: 完成生成定期账单，共生成${totalGenerated}条`);
      return totalGenerated;
    } catch (err) {
      console.error('RecurringBillService: 生成定期账单失败', JSON.stringify(err));
      return 0;
    }
  }

  /**
   * 为单个配置生成账单
   */
  private async generateBillsForConfig(config: RecurringBillConfig, today: string): Promise<number> {
    if (!config.id) {
      return 0;
    }

    let generatedCount = 0;
    const startDate = new Date(config.startDate);
    const todayDate = new Date(today);

    // 开始日期必须是今天或之前
    if (startDate > todayDate) {
      return 0;
    }

    // 如果有重复次数限制，检查已生成的数量
    let alreadyGeneratedCount = 0;
    if (config.repeatCount) {
      const records = await this.recurringDb.queryRecordsByConfigId(config.id);
      alreadyGeneratedCount = records.length;
      
      // 如果已达到重复次数，禁用配置
      if (alreadyGeneratedCount >= config.repeatCount) {
        if (config.isActive) {
          config.isActive = false;
          await this.recurringDb.updateConfig(config);
          console.info(`RecurringBillService: 配置${config.id}已达到重复次数${config.repeatCount}，自动禁用`);
        }
        return 0;
      }
    }

    // 计算应该生成的日期列表
    const datesToGenerate = this.calculateDatesShouldGenerate(config, today, alreadyGeneratedCount);

    for (const date of datesToGenerate) {
      // 检查是否已生成
      const hasGenerated = await this.recurringDb.hasGeneratedBill(config.id, date);
      if (hasGenerated) {
        continue;
      }

      // 生成账单
      const noteWithPrefix = `[定期]${config.note ? ' ' + config.note : ''}`;
      const bill = new BillModel(
        config.amount,
        config.type,
        config.category,
        date,
        noteWithPrefix
      );

      try {
        const billId = await this.billDb.insertBill(bill);
        
        // 记录生成记录
        const record = new GeneratedBillRecord(config.id, date, billId);
        await this.recurringDb.insertGeneratedRecord(record);
        
        generatedCount++;
        alreadyGeneratedCount++;
        console.info(`RecurringBillService: 为配置${config.id}生成账单，日期=${date}`);
        
        // 检查是否达到重复次数
        if (config.repeatCount && alreadyGeneratedCount >= config.repeatCount) {
          break;
        }
      } catch (err) {
        console.error(`RecurringBillService: 生成账单失败，日期=${date}`, JSON.stringify(err));
      }
    }

    // 检查是否应该禁用配置（即使没有生成新账单也要检查）
    const shouldDeactivate = await this.shouldDeactivateConfig(config, today);
    let needUpdate = false;
    
    // 更新最后生成日期
    if (generatedCount > 0) {
      config.lastGeneratedDate = today;
      needUpdate = true;
    }
    
    // 如果配置到期，设置为 inactive
    if (shouldDeactivate && config.isActive) {
      config.isActive = false;
      needUpdate = true;
      console.info(`RecurringBillService: 配置${config.id}已达到结束条件，自动禁用`);
    }
    
    // 如果有任何更新，保存配置
    if (needUpdate) {
      await this.recurringDb.updateConfig(config);
    }

    return generatedCount;
  }

  /**
   * 计算应该生成的日期列表（从最后生成日期或开始日期到今天）
   */
  private calculateDatesShouldGenerate(config: RecurringBillConfig, today: string, alreadyGeneratedCount: number): string[] {
    const dates: string[] = [];
    
    // 确定起始日期：最后生成日期的下一个周期，或者开始日期
    let currentDate: Date;
    if (config.lastGeneratedDate) {
      currentDate = this.getNextDate(new Date(config.lastGeneratedDate), config.recurringType, config.interval);
    } else {
      currentDate = new Date(config.startDate);
    }

    const todayDate = new Date(today);

    while (currentDate <= todayDate) {
      const dateStr = this.formatDate(currentDate);
      
      // 检查截止日期
      if (config.endDate && dateStr > config.endDate) {
        break;
      }
      
      dates.push(dateStr);
      
      // 检查重复次数（包括已生成的）
      if (config.repeatCount && (alreadyGeneratedCount + dates.length) >= config.repeatCount) {
        break;
      }
      
      // 计算下一个日期
      currentDate = this.getNextDate(currentDate, config.recurringType, config.interval);
    }

    return dates;
  }

  /**
   * 计算下一个日期
   */
  private getNextDate(date: Date, recurringType: RecurringType, interval: number): Date {
    const nextDate = new Date(date);
    
    switch (recurringType) {
      case RecurringType.DAILY:
        nextDate.setDate(nextDate.getDate() + interval);
        break;
      case RecurringType.WEEKLY:
        nextDate.setDate(nextDate.getDate() + (interval * 7));
        break;
      case RecurringType.MONTHLY:
        nextDate.setMonth(nextDate.getMonth() + interval);
        break;
    }
    
    return nextDate;
  }

  /**
   * 判断配置是否应该禁用
   */
  private async shouldDeactivateConfig(config: RecurringBillConfig, today: string): Promise<boolean> {
    // 检查截止日期（今天超过截止日期时禁用）
    if (config.endDate && today > config.endDate) {
      return true;
    }
    
    // 检查重复次数
    if (config.repeatCount && config.id) {
      const records = await this.recurringDb.queryRecordsByConfigId(config.id);
      if (records.length >= config.repeatCount) {
        return true;
      }
    }
    
    return false;
  }

  /**
   * 格式化日期为 YYYY-MM-DD
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 验证定期配置是否合法
   */
  validateConfig(config: RecurringBillConfig, minDate: string): string | null {
    // 验证金额
    if (config.amount <= 0) {
      return '金额必须大于0';
    }

    // 验证开始日期必须是今天或未来
    if (config.startDate < minDate) {
      return '开始日期必须大于等于' + minDate;
    }

    // 验证间隔
    if (config.interval < 1) {
      return '间隔必须大于等于1';
    }

    // 验证截止日期
    if (config.endDate && config.endDate <= config.startDate) {
      return '截止日期必须晚于开始日期';
    }

    // 验证重复次数
    if (config.repeatCount && config.repeatCount < 1) {
      return '重复次数必须大于等于1';
    }

    // 如果同时设置了截止日期和重复次数，警告用户
    if (config.endDate && config.repeatCount) {
      // 这不是错误，但可以提示用户
      console.info('RecurringBillService: 同时设置了截止日期和重复次数，将以先到达的条件为准');
    }

    return null;
  }
}
