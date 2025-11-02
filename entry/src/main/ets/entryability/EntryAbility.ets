import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { BillDatabase } from '../database/BillDatabase';
import { RecurringBillDatabase } from '../database/RecurringBillDatabase';
import { RecurringBillService } from '../utils/RecurringBillService';

const DOMAIN = 0x0000;
const WINDOW_SIZE_PREFS = 'window_size_preferences';

export default class EntryAbility extends UIAbility {
    private mainWindow: window.Window | null = null;
    private windowSizePrefs: preferences.Preferences | null = null;

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

            // 使用官网推荐的方式：在 getMainWindow 回调中恢复窗口状态
            windowStage.getMainWindow(async (err, windowClass) => {
                if (err.code) {
                    hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(err));
                    return;
                }

                try {
                    this.mainWindow = windowClass;
                    
                    // 初始化首选项
                    if (!this.windowSizePrefs) {
                        this.windowSizePrefs = await preferences.getPreferences(this.context, WINDOW_SIZE_PREFS);
                    }

                    // 读取保存的窗口状态
                    const savedWidth = await this.windowSizePrefs.get('window_width', 0) as number;
                    const savedHeight = await this.windowSizePrefs.get('window_height', 0) as number;
                    const savedX = await this.windowSizePrefs.get('window_x', -1) as number;
                    const savedY = await this.windowSizePrefs.get('window_y', -1) as number;
                    const isMaximized = await this.windowSizePrefs.get('is_maximized', false) as boolean;

                    // 恢复窗口状态
                    if (savedWidth > 0 && savedHeight > 0) {
                        if (isMaximized) {
                            await windowClass.maximize();
                            hilog.info(DOMAIN, 'testTag', 'Window maximized');
                        } else {
                            if (savedX >= 0 && savedY >= 0) {
                                await windowClass.moveWindowTo(savedX, savedY);
                            }
                            await windowClass.resize(savedWidth, savedHeight);
                            hilog.info(DOMAIN, 'testTag', 'Window restored: %{public}d x %{public}d at (%{public}d, %{public}d)',
                                savedWidth, savedHeight, savedX, savedY);
                        }
                    } else {
                        hilog.info(DOMAIN, 'testTag', 'No saved window state found, using default');
                    }

                    // 监听窗口大小变化
                    windowClass.on('windowSizeChange', async (size: window.Size) => {
                        await this.saveWindowState();
                    });

                    hilog.info(DOMAIN, 'testTag', 'Window size management initialized');
                } catch (error) {
                    hilog.error(DOMAIN, 'testTag', 'Failed to restore window state. Cause: %{public}s', JSON.stringify(error));
                }
            });
        });
    }

    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
        
        // 取消窗口大小变化监听
        if (this.mainWindow) {
            this.mainWindow.off('windowSizeChange');
        }
    }

    onForeground(): void {
        // Ability has brought to foreground
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    }

    onBackground(): void {
        // Ability has back to background
        hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    }

    // 保存窗口状态（大小、位置、最大化状态）
    private async saveWindowState(): Promise<void> {
        try {
            if (this.windowSizePrefs && this.mainWindow) {
                // 获取窗口属性
                const properties = await this.mainWindow.getWindowProperties();
                
                // 保存窗口状态
                await this.windowSizePrefs.put('window_width', properties.windowRect.width);
                await this.windowSizePrefs.put('window_height', properties.windowRect.height);
                await this.windowSizePrefs.put('window_x', properties.windowRect.left);
                await this.windowSizePrefs.put('window_y', properties.windowRect.top);
                await this.windowSizePrefs.put('is_maximized', properties.isLayoutFullScreen);
                await this.windowSizePrefs.flush();
                
                hilog.info(DOMAIN, 'testTag', 'Window state saved: %{public}d x %{public}d at (%{public}d, %{public}d), maximized: %{public}s', 
                    properties.windowRect.width, properties.windowRect.height, 
                    properties.windowRect.left, properties.windowRect.top,
                    properties.isLayoutFullScreen);
            }
        } catch (error) {
            hilog.error(DOMAIN, 'testTag', 'Failed to save window state. Cause: %{public}s', JSON.stringify(error));
        }
    }
}