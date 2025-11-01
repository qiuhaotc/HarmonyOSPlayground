import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BillDatabase } from '../database/BillDatabase';
import { RecurringBillDatabase } from '../database/RecurringBillDatabase';
import { RecurringBillService } from '../utils/RecurringBillService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        try {
            // 设置为跟随系统的颜色模式（自动适配暗黑模式）
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (err) {
            hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
        }
        
        // 初始化数据库并生成定期账单
        this.initDatabaseAndGenerateRecurringBills();
        
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    }
    
    // 初始化数据库并生成定期账单
    private async initDatabaseAndGenerateRecurringBills(): Promise<void> {
        try {
            // 初始化账单数据库
            const billDb = BillDatabase.getInstance();
            await billDb.init(this.context);
            hilog.info(DOMAIN, 'testTag', 'BillDatabase initialized');
            
            // 初始化定期记账数据库
            const recurringDb = RecurringBillDatabase.getInstance();
            await recurringDb.init(this.context);
            hilog.info(DOMAIN, 'testTag', 'RecurringBillDatabase initialized');
            
            // 生成定期账单
            const recurringService = RecurringBillService.getInstance();
            await recurringService.generateRecurringBills();
            hilog.info(DOMAIN, 'testTag', 'Recurring bills generated');
        } catch (err) {
            hilog.error(DOMAIN, 'testTag', 'Failed to init database or generate recurring bills. Cause: %{public}s', JSON.stringify(err));
        }
    }

    onDestroy(): void {
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
        });
    }

    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    }

    onForeground(): void {
        // Ability has brought to foreground
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    }

    onBackground(): void {
        // Ability has back to background
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    }
}