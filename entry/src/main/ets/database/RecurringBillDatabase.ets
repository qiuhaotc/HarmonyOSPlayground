import relationalStore from '@ohos.data.relationalStore';
import { RecurringBillConfig, RecurringType, GeneratedBillRecord } from '../models/RecurringBillModel';
import { BillType } from '../models/BillModel';

/**
 * 定期记账数据库管理类
 */
export class RecurringBillDatabase {
  private static instance: RecurringBillDatabase;
  private rdbStore: relationalStore.RdbStore | null = null;
  private readonly DATABASE_NAME: string = 'BillDatabase.db';
  private readonly CONFIG_TABLE: string = 'recurring_bill_configs';
  private readonly RECORD_TABLE: string = 'generated_bill_records';

  // 定期配置表SQL
  private readonly CREATE_CONFIG_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS ${this.CONFIG_TABLE} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      note TEXT,
      recurringType TEXT NOT NULL,
      interval INTEGER NOT NULL,
      repeatCount INTEGER,
      endDate TEXT,
      startDate TEXT NOT NULL,
      lastGeneratedDate TEXT,
      isActive INTEGER NOT NULL DEFAULT 1,
      createTime TEXT NOT NULL
    )
  `;

  // 生成记录表SQL
  private readonly CREATE_RECORD_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS ${this.RECORD_TABLE} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      recurringConfigId INTEGER NOT NULL,
      generatedDate TEXT NOT NULL,
      billId INTEGER NOT NULL,
      createTime TEXT NOT NULL
    )
  `;

  // 创建索引以加速查询
  private readonly CREATE_INDEX_SQL: string[] = [
    `CREATE INDEX IF NOT EXISTS idx_recurring_config_active ON ${this.CONFIG_TABLE}(isActive)`,
    `CREATE INDEX IF NOT EXISTS idx_recurring_config_start_date ON ${this.CONFIG_TABLE}(startDate)`,
    `CREATE INDEX IF NOT EXISTS idx_generated_record_config_id ON ${this.RECORD_TABLE}(recurringConfigId)`,
    `CREATE INDEX IF NOT EXISTS idx_generated_record_date ON ${this.RECORD_TABLE}(generatedDate)`,
    `CREATE INDEX IF NOT EXISTS idx_generated_record_bill_id ON ${this.RECORD_TABLE}(billId)`
  ];

  private constructor() {
  }

  static getInstance(): RecurringBillDatabase {
    if (!RecurringBillDatabase.instance) {
      RecurringBillDatabase.instance = new RecurringBillDatabase();
    }
    return RecurringBillDatabase.instance;
  }

  /**
   * 初始化数据库
   */
  async init(context: Context): Promise<void> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, {
        name: this.DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      });
      
      // 创建表
      await this.rdbStore.executeSql(this.CREATE_CONFIG_TABLE_SQL);
      await this.rdbStore.executeSql(this.CREATE_RECORD_TABLE_SQL);
      
      // 创建索引
      for (const sql of this.CREATE_INDEX_SQL) {
        await this.rdbStore.executeSql(sql);
      }
      
      console.info('RecurringBillDatabase: 数据库初始化成功');
    } catch (err) {
      console.error('RecurringBillDatabase: 数据库初始化失败', JSON.stringify(err));
      throw new Error(`定期记账数据库初始化失败: ${err}`);
    }
  }

  /**
   * 插入定期配置
   */
  async insertConfig(config: RecurringBillConfig): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'amount': config.amount,
      'type': config.type,
      'category': config.category,
      'note': config.note,
      'recurringType': config.recurringType,
      'interval': config.interval,
      'repeatCount': config.repeatCount ?? null,
      'endDate': config.endDate ?? null,
      'startDate': config.startDate,
      'lastGeneratedDate': config.lastGeneratedDate ?? null,
      'isActive': config.isActive ? 1 : 0,
      'createTime': config.createTime || new Date().toISOString()
    };

    try {
      const rowId = await this.rdbStore.insert(this.CONFIG_TABLE, valueBucket);
      console.info('RecurringBillDatabase: 插入定期配置成功, rowId=' + rowId);
      return rowId;
    } catch (err) {
      console.error('RecurringBillDatabase: 插入定期配置失败', JSON.stringify(err));
      throw new Error(`插入定期配置失败: ${err}`);
    }
  }

  /**
   * 更新定期配置
   */
  async updateConfig(config: RecurringBillConfig): Promise<number> {
    if (!this.rdbStore || !config.id) {
      throw new Error('数据库未初始化或配置ID为空');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'amount': config.amount,
      'type': config.type,
      'category': config.category,
      'note': config.note,
      'recurringType': config.recurringType,
      'interval': config.interval,
      'repeatCount': config.repeatCount ?? null,
      'endDate': config.endDate ?? null,
      'startDate': config.startDate,
      'lastGeneratedDate': config.lastGeneratedDate ?? null,
      'isActive': config.isActive ? 1 : 0
    };

    const predicates = new relationalStore.RdbPredicates(this.CONFIG_TABLE);
    predicates.equalTo('id', config.id);

    try {
      const rows = await this.rdbStore.update(valueBucket, predicates);
      console.info('RecurringBillDatabase: 更新定期配置成功, rows=' + rows);
      return rows;
    } catch (err) {
      console.error('RecurringBillDatabase: 更新定期配置失败', JSON.stringify(err));
      throw new Error(`更新定期配置失败: ${err}`);
    }
  }

  /**
   * 删除定期配置
   */
  async deleteConfig(id: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.CONFIG_TABLE);
    predicates.equalTo('id', id);

    try {
      const rows = await this.rdbStore.delete(predicates);
      console.info('RecurringBillDatabase: 删除定期配置成功, rows=' + rows);
      return rows;
    } catch (err) {
      console.error('RecurringBillDatabase: 删除定期配置失败', JSON.stringify(err));
      throw new Error(`删除定期配置失败: ${err}`);
    }
  }

  /**
   * 查询所有活跃的定期配置
   */
  async queryActiveConfigs(): Promise<RecurringBillConfig[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.CONFIG_TABLE);
    predicates.equalTo('isActive', 1);
    predicates.orderByAsc('startDate');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      const configs = this.convertResultSetToConfigs(resultSet);
      resultSet.close();
      return configs;
    } catch (err) {
      console.error('RecurringBillDatabase: 查询活跃配置失败', JSON.stringify(err));
      throw new Error(`查询活跃配置失败: ${err}`);
    }
  }

  /**
   * 查询所有定期配置（包括禁用的）
   */
  async queryAllConfigs(): Promise<RecurringBillConfig[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.CONFIG_TABLE);
    predicates.orderByDesc('createTime');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      const configs = this.convertResultSetToConfigs(resultSet);
      resultSet.close();
      return configs;
    } catch (err) {
      console.error('RecurringBillDatabase: 查询所有配置失败', JSON.stringify(err));
      throw new Error(`查询所有配置失败: ${err}`);
    }
  }

  /**
   * 根据ID查询定期配置
   */
  async queryConfigById(id: number): Promise<RecurringBillConfig | null> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.CONFIG_TABLE);
    predicates.equalTo('id', id);

    try {
      const resultSet = await this.rdbStore.query(predicates);
      const configs = this.convertResultSetToConfigs(resultSet);
      resultSet.close();
      return configs.length > 0 ? configs[0] : null;
    } catch (err) {
      console.error('RecurringBillDatabase: 根据ID查询配置失败', JSON.stringify(err));
      throw new Error(`根据ID查询配置失败: ${err}`);
    }
  }

  /**
   * 插入生成记录
   */
  async insertGeneratedRecord(record: GeneratedBillRecord): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'recurringConfigId': record.recurringConfigId,
      'generatedDate': record.generatedDate,
      'billId': record.billId,
      'createTime': record.createTime || new Date().toISOString()
    };

    try {
      const rowId = await this.rdbStore.insert(this.RECORD_TABLE, valueBucket);
      console.info('RecurringBillDatabase: 插入生成记录成功, rowId=' + rowId);
      return rowId;
    } catch (err) {
      console.error('RecurringBillDatabase: 插入生成记录失败', JSON.stringify(err));
      throw new Error(`插入生成记录失败: ${err}`);
    }
  }

  /**
   * 检查指定日期是否已生成账单
   */
  async hasGeneratedBill(configId: number, date: string): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.RECORD_TABLE);
    predicates.equalTo('recurringConfigId', configId);
    predicates.equalTo('generatedDate', date);

    try {
      const resultSet = await this.rdbStore.query(predicates);
      const count = resultSet.rowCount;
      resultSet.close();
      return count > 0;
    } catch (err) {
      console.error('RecurringBillDatabase: 检查生成记录失败', JSON.stringify(err));
      throw new Error(`检查生成记录失败: ${err}`);
    }
  }

  /**
   * 查询配置的所有生成记录
   */
  async queryRecordsByConfigId(configId: number): Promise<GeneratedBillRecord[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.RECORD_TABLE);
    predicates.equalTo('recurringConfigId', configId);
    predicates.orderByDesc('generatedDate');

    try {
      const resultSet = await this.rdbStore.query(predicates);
      const records = this.convertResultSetToRecords(resultSet);
      resultSet.close();
      return records;
    } catch (err) {
      console.error('RecurringBillDatabase: 查询生成记录失败', JSON.stringify(err));
      throw new Error(`查询生成记录失败: ${err}`);
    }
  }

  /**
   * 删除配置的所有生成记录
   */
  async deleteRecordsByConfigId(configId: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates(this.RECORD_TABLE);
    predicates.equalTo('recurringConfigId', configId);

    try {
      const rows = await this.rdbStore.delete(predicates);
      console.info('RecurringBillDatabase: 删除生成记录成功, rows=' + rows);
      return rows;
    } catch (err) {
      console.error('RecurringBillDatabase: 删除生成记录失败', JSON.stringify(err));
      throw new Error(`删除生成记录失败: ${err}`);
    }
  }

  /**
   * 转换ResultSet为配置数组
   */
  private convertResultSetToConfigs(resultSet: relationalStore.ResultSet): RecurringBillConfig[] {
    const configs: RecurringBillConfig[] = [];

    while (resultSet.goToNextRow()) {
      const config = new RecurringBillConfig(
        resultSet.getDouble(resultSet.getColumnIndex('amount')),
        resultSet.getString(resultSet.getColumnIndex('type')) as BillType,
        resultSet.getString(resultSet.getColumnIndex('category')),
        resultSet.getString(resultSet.getColumnIndex('recurringType')) as RecurringType,
        resultSet.getLong(resultSet.getColumnIndex('interval')),
        resultSet.getString(resultSet.getColumnIndex('startDate')),
        resultSet.getString(resultSet.getColumnIndex('note')) || ''
      );
      
      config.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      
      const repeatCountIndex = resultSet.getColumnIndex('repeatCount');
      if (!resultSet.isColumnNull(repeatCountIndex)) {
        config.repeatCount = resultSet.getLong(repeatCountIndex);
      }
      
      const endDateIndex = resultSet.getColumnIndex('endDate');
      if (!resultSet.isColumnNull(endDateIndex)) {
        config.endDate = resultSet.getString(endDateIndex);
      }
      
      const lastGeneratedDateIndex = resultSet.getColumnIndex('lastGeneratedDate');
      if (!resultSet.isColumnNull(lastGeneratedDateIndex)) {
        config.lastGeneratedDate = resultSet.getString(lastGeneratedDateIndex);
      }
      
      config.isActive = resultSet.getLong(resultSet.getColumnIndex('isActive')) === 1;
      config.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
      
      configs.push(config);
    }

    return configs;
  }

  /**
   * 转换ResultSet为记录数组
   */
  private convertResultSetToRecords(resultSet: relationalStore.ResultSet): GeneratedBillRecord[] {
    const records: GeneratedBillRecord[] = [];

    while (resultSet.goToNextRow()) {
      const record = new GeneratedBillRecord(
        resultSet.getLong(resultSet.getColumnIndex('recurringConfigId')),
        resultSet.getString(resultSet.getColumnIndex('generatedDate')),
        resultSet.getLong(resultSet.getColumnIndex('billId'))
      );
      
      record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      record.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
      
      records.push(record);
    }

    return records;
  }
}
