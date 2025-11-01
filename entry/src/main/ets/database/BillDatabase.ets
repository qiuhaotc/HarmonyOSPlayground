import relationalStore from '@ohos.data.relationalStore';
import { BillModel, BillType } from '../models/BillModel';

/**
 * 账单数据库管理类
 */
export class BillDatabase {
    private static instance: BillDatabase;
    private rdbStore: relationalStore.RdbStore | null = null;
    private readonly DATABASE_NAME: string = 'BillDatabase.db';
    private readonly TABLE_NAME: string = 'bills';
    // 数据库配置
    private readonly STORE_CONFIG: relationalStore.StoreConfig = {
        name: this.DATABASE_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
    };
    // 创建表的SQL语句
    private readonly CREATE_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL,
      time TEXT NOT NULL,
      note TEXT,
      createTime TEXT NOT NULL
    )
  `;

    private constructor() {
    }

    /**
     * 获取数据库实例
     */
    static getInstance(): BillDatabase {
        if (!BillDatabase.instance) {
            BillDatabase.instance = new BillDatabase();
        }
        return BillDatabase.instance;
    }

    /**
     * 初始化数据库
     */
    async init(context: Context): Promise<void> {
        try {
            this.rdbStore = await relationalStore.getRdbStore(context, this.STORE_CONFIG);
            await this.rdbStore.executeSql(this.CREATE_TABLE_SQL);
            console.info('BillDatabase: 数据库初始化成功');
        } catch (err) {
            console.error('BillDatabase: 数据库初始化失败', JSON.stringify(err));
            throw new Error(`数据库初始化失败: ${err}`);
        }
    }

    /**
     * 插入账单
     */
    async insertBill(bill: BillModel): Promise<number> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const valueBucket: relationalStore.ValuesBucket = {
            'amount': bill.amount,
            'type': bill.type,
            'category': bill.category,
            'date': bill.date,
            'time': bill.time,
            'note': bill.note,
            'createTime': bill.createTime || new Date().toISOString()
        };

        // 如果bill有id且id>0,则包含id字段(用于导入时保留原ID)
        if (bill.id && bill.id > 0) {
            valueBucket['id'] = bill.id;
        }

        try {
            const rowId = await this.rdbStore.insert(this.TABLE_NAME, valueBucket);
            console.info('BillDatabase: 插入账单成功, rowId=' + rowId);
            return rowId;
        } catch (err) {
            console.error('BillDatabase: 插入账单失败', JSON.stringify(err));
            throw new Error(`插入账单失败: ${err}`);
        }
    }

    /**
     * 删除账单
     */
    async deleteBill(id: number): Promise<number> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo('id', id);

        try {
            const rows = await this.rdbStore.delete(predicates);
            console.info('BillDatabase: 删除账单成功, rows=' + rows);
            return rows;
        } catch (err) {
            console.error('BillDatabase: 删除账单失败', JSON.stringify(err));
            throw new Error(`删除账单失败: ${err}`);
        }
    }

    /**
     * 更新账单
     */
    async updateBill(bill: BillModel): Promise<number> {
        if (!this.rdbStore || !bill.id) {
            throw new Error('数据库未初始化或账单ID为空');
        }

        const valueBucket: relationalStore.ValuesBucket = {
            'amount': bill.amount,
            'type': bill.type,
            'category': bill.category,
            'date': bill.date,
            'time': bill.time,
            'note': bill.note
        };

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo('id', bill.id);

        try {
            const rows = await this.rdbStore.update(valueBucket, predicates);
            console.info('BillDatabase: 更新账单成功, rows=' + rows);
            return rows;
        } catch (err) {
            console.error('BillDatabase: 更新账单失败', JSON.stringify(err));
            throw new Error(`更新账单失败: ${err}`);
        }
    }

    /**
     * 根据ID查询账单
     */
    async queryBillById(id: number): Promise<BillModel | null> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo('id', id);

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills.length > 0 ? bills[0] : null;
        } catch (err) {
            console.error('BillDatabase: 根据ID查询账单失败', JSON.stringify(err));
            throw new Error(`根据ID查询账单失败: ${err}`);
        }
    }

    /**
     * 查询所有账单
     */
    async queryAllBills(): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 查询账单失败', JSON.stringify(err));
            throw new Error(`查询账单失败: ${err}`);
        }
    }

    /**
     * 按年月查询账单
     */
    async queryBillsByYearMonth(year: string, month: string): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const yearMonth = `${year}-${month.padStart(2, '0')}`;
        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.like('date', `${yearMonth}%`);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 按年月查询账单失败', JSON.stringify(err));
            throw new Error(`按年月查询账单失败: ${err}`);
        }
    }

    /**
     * 按年查询账单
     */
    async queryBillsByYear(year: string): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.like('date', `${year}%`);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 按年查询账单失败', JSON.stringify(err));
            throw new Error(`按年查询账单失败: ${err}`);
        }
    }

    /**
     * 按分类查询账单
     */
    async queryBillsByCategory(category: string): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo('category', category);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 按分类查询账单失败', JSON.stringify(err));
            throw new Error(`按分类查询账单失败: ${err}`);
        }
    }

    /**
     * 按年和分类查询账单
     */
    async queryBillsByYearAndCategory(year: string, category: string): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.like('date', `${year}%`);
        predicates.equalTo('category', category);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 按年和分类查询账单失败', JSON.stringify(err));
            throw new Error(`按年和分类查询账单失败: ${err}`);
        }
    }

    /**
     * 按年月和分类查询账单
     */
    async queryBillsByYearMonthAndCategory(year: string, month: string, category: string): Promise<BillModel[]> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        const yearMonth = `${year}-${month.padStart(2, '0')}`;
        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.like('date', `${yearMonth}%`);
        predicates.equalTo('category', category);
        predicates.orderByDesc('date').orderByDesc('time');

        try {
            const resultSet = await this.rdbStore.query(predicates);
            const bills = this.convertResultSetToBills(resultSet);
            resultSet.close();
            return bills;
        } catch (err) {
            console.error('BillDatabase: 按年月和分类查询账单失败', JSON.stringify(err));
            throw new Error(`按年月和分类查询账单失败: ${err}`);
        }
    }

    /**
     * 将ResultSet转换为BillModel数组
     */
    private convertResultSetToBills(resultSet: relationalStore.ResultSet): BillModel[] {
        const bills: BillModel[] = [];

        while (resultSet.goToNextRow()) {
            const bill = new BillModel(
                resultSet.getDouble(resultSet.getColumnIndex('amount')),
                resultSet.getString(resultSet.getColumnIndex('type')) as BillType,
                resultSet.getString(resultSet.getColumnIndex('category')),
                resultSet.getString(resultSet.getColumnIndex('date')),
                resultSet.getString(resultSet.getColumnIndex('time')),
                resultSet.getString(resultSet.getColumnIndex('note'))
            );
            bill.id = resultSet.getLong(resultSet.getColumnIndex('id'));
            bill.createTime = resultSet.getString(resultSet.getColumnIndex('createTime'));
            bills.push(bill);
        }

        return bills;
    }

    /**
     * 清空所有账单(用于测试)
     */
    async clearAllBills(): Promise<void> {
        if (!this.rdbStore) {
            throw new Error('数据库未初始化');
        }

        try {
            await this.rdbStore.executeSql(`DELETE FROM ${this.TABLE_NAME}`);
            console.info('BillDatabase: 清空所有账单成功');
        } catch (err) {
            console.error('BillDatabase: 清空所有账单失败', JSON.stringify(err));
            throw new Error(`清空所有账单失败: ${err}`);
        }
    }
}
