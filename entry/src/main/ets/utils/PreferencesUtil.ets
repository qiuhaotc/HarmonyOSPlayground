import preferences from '@ohos.data.preferences';
import { BillType } from '../models/BillModel';

/**
 * 用户偏好设置管理
 */
export class PreferencesUtil {
    private static instance: PreferencesUtil;
    private preferences: preferences.Preferences | null = null;
    private readonly PREFERENCES_NAME: string = 'bill_preferences';
    // 偏好设置的键
    private readonly KEY_LAST_EXPENSE_CATEGORY = 'last_expense_category';
    private readonly KEY_LAST_INCOME_CATEGORY = 'last_income_category';

    private constructor() {
    }

    /**
     * 获取实例
     */
    static getInstance(): PreferencesUtil {
        if (!PreferencesUtil.instance) {
            PreferencesUtil.instance = new PreferencesUtil();
        }
        return PreferencesUtil.instance;
    }

    /**
     * 初始化偏好设置
     */
    async init(context: Context): Promise<void> {
        try {
            this.preferences = await preferences.getPreferences(context, this.PREFERENCES_NAME);
            console.info('PreferencesUtil: 初始化成功');
        } catch (err) {
            console.error('PreferencesUtil: 初始化失败', JSON.stringify(err));
            throw new Error(`PreferencesUtil初始化失败: ${err?.message || JSON.stringify(err)}`);
        }
    }

    /**
     * 保存上次选择的分类
     */
    async saveLastCategory(type: BillType, category: string): Promise<void> {
        if (!this.preferences) {
            console.error('PreferencesUtil: 未初始化');
            return;
        }

        try {
            const key = type === BillType.EXPENSE ? this.KEY_LAST_EXPENSE_CATEGORY : this.KEY_LAST_INCOME_CATEGORY;
            await this.preferences.put(key, category);
            await this.preferences.flush();
            console.info(`PreferencesUtil: 保存分类成功 ${type} - ${category}`);
        } catch (err) {
            console.error('PreferencesUtil: 保存分类失败', JSON.stringify(err));
        }
    }

    /**
     * 获取上次选择的分类
     */
    async getLastCategory(type: BillType): Promise<string> {
        if (!this.preferences) {
            console.error('PreferencesUtil: 未初始化');
            return '';
        }

        try {
            const key = type === BillType.EXPENSE ? this.KEY_LAST_EXPENSE_CATEGORY : this.KEY_LAST_INCOME_CATEGORY;
            const category = await this.preferences.get(key, '');
            return category as string;
        } catch (err) {
            console.error('PreferencesUtil: 获取分类失败', JSON.stringify(err));
            return '';
        }
    }
}
