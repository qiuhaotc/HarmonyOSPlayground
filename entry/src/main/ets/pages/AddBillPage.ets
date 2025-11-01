import { BillModel, BillType, BillCategory, getCategoriesByType } from '../models/BillModel';
import { RecurringBillConfig, RecurringType } from '../models/RecurringBillModel';
import { BillDatabase } from '../database/BillDatabase';
import { RecurringBillDatabase } from '../database/RecurringBillDatabase';
import { DateUtil } from '../utils/DateUtil';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { RecurringBillService } from '../utils/RecurringBillService';
import router from '@ohos.router';

/**
 * 添加账单页面
 */
@Entry
@Component
struct AddBillPage {
    @State amount: string = ''; // 金额输入
    @State selectedType: BillType = BillType.EXPENSE; // 选中的类型
    @State selectedCategory: string = ''; // 选中的分类
    @State selectedDate: string = DateUtil.getCurrentDate(); // 选中的日期
    @State note: string = ''; // 备注
    @State currentCategories: BillCategory[] = []; // 当前类型的分类列表
    
    // 定期记账相关状态
    @State isRecurring: boolean = false; // 是否启用定期记账
    @State recurringType: RecurringType = RecurringType.DAILY; // 重复类型
    @State interval: string = '1'; // 间隔
    @State repeatCount: string = ''; // 重复次数（可选）
    @State endDate: string = ''; // 截止日期（可选）
    
    private billDb: BillDatabase = BillDatabase.getInstance();
    private recurringDb: RecurringBillDatabase = RecurringBillDatabase.getInstance();
    private prefsUtil: PreferencesUtil = PreferencesUtil.getInstance();
    private recurringService: RecurringBillService = RecurringBillService.getInstance();

    async aboutToAppear() {
        // 初始化偏好设置
        try {
            await this.prefsUtil.init(getContext(this));
        } catch (err) {
            console.error('初始化偏好设置失败', JSON.stringify(err));
        }

        // 初始化定期记账数据库
        try {
            await this.recurringDb.init(getContext(this));
        } catch (err) {
            console.error('初始化定期记账数据库失败', JSON.stringify(err));
        }

        // 加载分类列表
        await this.loadCategories();
    }

    // 加载分类列表
    async loadCategories() {
        this.currentCategories = getCategoriesByType(this.selectedType);
        
        // 尝试加载上次选择的分类
        const lastCategory = await this.prefsUtil.getLastCategory(this.selectedType);
        
        if (lastCategory && this.currentCategories.some(cat => cat.name === lastCategory)) {
            this.selectedCategory = lastCategory;
        } else if (this.currentCategories.length > 0) {
            this.selectedCategory = this.currentCategories[0].name;
        }
    }

    build() {
        Column() {
            // 标题栏
            this.buildTitleBar();

            // 可滚动内容区域
            Scroll() {
                Column() {
                    // 金额输入
                    this.buildAmountInput();

                    // 类型选择
                    this.buildTypeSelector();

                    // 分类选择
                    this.buildCategorySelector();

                    // 日期选择
                    this.buildDateSelector();

                    // 备注输入
                    this.buildNoteInput();

                    // 定期记账配置
                    this.buildRecurringConfig();

                    // 保存按钮
                    this.buildSaveButton();
                }
                .width('100%')
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            .scrollable(ScrollDirection.Vertical)
            .edgeEffect(EdgeEffect.Spring)
            .align(Alignment.Top)
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.page_background'))
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    buildTitleBar() {
        Row() {
            Text('返回')
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .onClick(() => {
                    router.back();
                })

            Text('记一笔')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

            Row({ space: 12 }) {
                Text('定期')
                    .fontSize(16)
                    .fontColor($r('app.color.primary_color'))
                    .onClick(() => {
                        router.pushUrl({ url: 'pages/RecurringBillManagePage' });
                    })

                Text('账单')
                    .fontSize(16)
                    .fontColor($r('app.color.primary_color'))
                    .onClick(() => {
                        router.pushUrl({ url: 'pages/BillListPage' });
                    })
            }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.card_background'))
    }

    @Builder
    buildAmountInput() {
        Column() {
            Text('金额')
                .fontSize(14)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ bottom: 8 })

            Row() {
                Text('¥')
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))

                TextInput({ text: this.amount, placeholder: '0.00' })
                    .fontSize(20)
                    .fontColor($r('app.color.text_primary'))
                    .backgroundColor(Color.Transparent)
                    .type(InputType.NUMBER_DECIMAL)
                    .layoutWeight(1)
                    .inputFilter("^\\d*\\.?\\d{0,2}$") // 正则表达式：允许整数或最多两位小数
                    .onChange((value: string) => {
                        // 支持小数点后两位
                        this.amount = value;
                    })
            }
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 12 })
    }

    @Builder
    buildTypeSelector() {
        Row() {
            Button('支出')
                .fontSize(16)
                .fontColor(this.selectedType === BillType.EXPENSE ? '#FFFFFF' : $r('app.color.text_primary'))
                .backgroundColor(this.selectedType === BillType.EXPENSE ? $r('app.color.danger_color') : $r('app.color.page_background'))
                .layoutWeight(1)
                .onClick(async () => {
                    this.selectedType = BillType.EXPENSE;
                    // 切换类型后重新加载分类
                    await this.loadCategories();
                })

            Button('收入')
                .fontSize(16)
                .fontColor(this.selectedType === BillType.INCOME ? '#FFFFFF' : $r('app.color.text_primary'))
                .backgroundColor(this.selectedType === BillType.INCOME ? $r('app.color.success_color') : $r('app.color.page_background'))
                .layoutWeight(1)
                .margin({ left: 12 })
                .onClick(async () => {
                    this.selectedType = BillType.INCOME;
                    // 切换类型后重新加载分类
                    await this.loadCategories();
                })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildCategorySelector() {
        Column() {
            Text('分类')
                .fontSize(14)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ bottom: 12 })
            Grid() {
                ForEach(this.currentCategories, (category: BillCategory) => {
                    GridItem() {
                        Column() {
                            Text(category.icon)
                                .fontSize(32)

                            Text(category.name)
                                .fontSize(14)
                                .fontColor(this.selectedCategory === category.name ? '#FFFFFF' : $r('app.color.text_primary'))
                                .margin({ top: 4 })
                        }
                        .width('100%')
                        .padding(12)
                        .borderRadius(8)
                        .backgroundColor(this.selectedCategory === category.name ? category.color : $r('app.color.page_background'))
                        .onClick(() => {
                            this.selectedCategory = category.name;
                        })
                    }
                })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .rowsGap(12)
            .columnsGap(12)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildDateSelector() {
        Row() {
            Text('日期')
                .fontSize(14)
                .fontColor($r('app.color.text_tertiary'))

            Text(DateUtil.formatDateChinese(this.selectedDate))
                .fontSize(16)
                .fontColor($r('app.color.primary_color'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .onClick(() => {
                    this.showDatePickerDialog();
                })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildNoteInput() {
        Column() {
            Row() {
                Text('备注')
                    .fontSize(14)
                    .fontColor($r('app.color.text_tertiary'))

                Blank()

                Text(`${this.note.length}/500`)
                    .fontSize(12)
                    .fontColor(this.note.length > 500 ? $r('app.color.danger_color') : $r('app.color.text_tertiary'))
            }
            .width('100%')
            .margin({ bottom: 8 })

            TextInput({ text: this.note, placeholder: '添加备注信息...' })
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.page_background'))
                .maxLength(500)
                .onChange((value: string) => {
                    if (value.length <= 500) {
                        this.note = value;
                    }
                })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildRecurringConfig() {
        Column() {
            // 定期记账开关
            Row() {
                Text('定期记账')
                    .fontSize(16)
                    .fontColor($r('app.color.text_primary'))
                
                Blank()
                
                Toggle({ type: ToggleType.Switch, isOn: this.isRecurring })
                    .onChange((isOn: boolean) => {
                        this.isRecurring = isOn;
                    })
            }
            .width('100%')
            .padding(16)

            // 定期记账详细配置（仅在启用时显示）
            if (this.isRecurring) {
                Column() {
                    // 重复类型
                    Row() {
                        Text('重复类型')
                            .fontSize(14)
                            .fontColor($r('app.color.text_tertiary'))
                            .width(80)
                        
                        Row() {
                            Button('按天')
                                .fontSize(14)
                                .fontColor(this.recurringType === RecurringType.DAILY ? '#FFFFFF' : $r('app.color.text_primary'))
                                .backgroundColor(this.recurringType === RecurringType.DAILY ? $r('app.color.primary_color') : $r('app.color.page_background'))
                                .height(36)
                                .layoutWeight(1)
                                .onClick(() => {
                                    this.recurringType = RecurringType.DAILY;
                                })
                            
                            Button('按周')
                                .fontSize(14)
                                .fontColor(this.recurringType === RecurringType.WEEKLY ? '#FFFFFF' : $r('app.color.text_primary'))
                                .backgroundColor(this.recurringType === RecurringType.WEEKLY ? $r('app.color.primary_color') : $r('app.color.page_background'))
                                .height(36)
                                .layoutWeight(1)
                                .margin({ left: 8 })
                                .onClick(() => {
                                    this.recurringType = RecurringType.WEEKLY;
                                })
                            
                            Button('按月')
                                .fontSize(14)
                                .fontColor(this.recurringType === RecurringType.MONTHLY ? '#FFFFFF' : $r('app.color.text_primary'))
                                .backgroundColor(this.recurringType === RecurringType.MONTHLY ? $r('app.color.primary_color') : $r('app.color.page_background'))
                                .height(36)
                                .layoutWeight(1)
                                .margin({ left: 8 })
                                .onClick(() => {
                                    this.recurringType = RecurringType.MONTHLY;
                                })
                        }
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .margin({ bottom: 16 })

                    // 间隔设置
                    Row() {
                        Text('间隔')
                            .fontSize(14)
                            .fontColor($r('app.color.text_tertiary'))
                            .width(80)
                        
                        Row() {
                            Text('每')
                                .fontSize(14)
                                .fontColor($r('app.color.text_primary'))
                            
                            TextInput({ text: this.interval, placeholder: '1' })
                                .fontSize(14)
                                .type(InputType.Number)
                                .width(60)
                                .textAlign(TextAlign.Center)
                                .margin({ left: 8, right: 8 })
                                .onChange((value: string) => {
                                    this.interval = value;
                                })
                            
                            Text(this.getIntervalUnit())
                                .fontSize(14)
                                .fontColor($r('app.color.text_primary'))
                        }
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .margin({ bottom: 16 })

                    // 重复次数（可选）
                    Row() {
                        Text('重复次数')
                            .fontSize(14)
                            .fontColor($r('app.color.text_tertiary'))
                            .width(80)
                        
                        TextInput({ text: this.repeatCount, placeholder: '不限制（可选）' })
                            .fontSize(14)
                            .type(InputType.Number)
                            .layoutWeight(1)
                            .onChange((value: string) => {
                                this.repeatCount = value;
                            })
                        
                        Text('次')
                            .fontSize(14)
                            .fontColor($r('app.color.text_primary'))
                            .margin({ left: 8 })
                    }
                    .width('100%')
                    .margin({ bottom: 16 })

                    // 截止日期（可选）
                    Row() {
                        Text('截止日期')
                            .fontSize(14)
                            .fontColor($r('app.color.text_tertiary'))
                            .width(80)
                        
                        Text(this.endDate || '不限制（可选）')
                            .fontSize(14)
                            .fontColor(this.endDate ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                            .layoutWeight(1)
                            .onClick(() => {
                                this.showEndDatePickerDialog();
                            })
                        
                        if (this.endDate) {
                            Text('清除')
                                .fontSize(12)
                                .fontColor($r('app.color.danger_color'))
                                .margin({ left: 8 })
                                .onClick(() => {
                                    this.endDate = '';
                                })
                        }
                    }
                    .width('100%')
                }
                .padding({ left: 16, right: 16, bottom: 16 })
            }
        }
        .width('100%')
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildSaveButton() {
        Button('保存')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .backgroundColor(this.selectedType === BillType.EXPENSE ? $r('app.color.danger_color') : $r('app.color.success_color'))
            .width('90%')
            .height(48)
            .margin({ top: 32, bottom: 32 })
            .onClick(() => {
                this.saveBill();
            })
    }
    
    // 获取间隔单位文本
    getIntervalUnit(): string {
        switch (this.recurringType) {
            case RecurringType.DAILY:
                return '天';
            case RecurringType.WEEKLY:
                return '周';
            case RecurringType.MONTHLY:
                return '月';
            default:
                return '';
        }
    }
    
    // 显示截止日期选择器
    showEndDatePickerDialog() {
        // 截止日期必须晚于开始日期
        const minDate = new Date(this.selectedDate);
        minDate.setDate(minDate.getDate() + 1);
        
        const selectedEndDate = this.endDate ? new Date(this.endDate) : minDate;
        
        this.getUIContext().showDatePickerDialog({
            start: minDate,
            end: new Date('2100-12-31'),
            selected: selectedEndDate,
            lunar: false,
            onAccept: (value: DatePickerResult) => {
                const year = value.year ?? new Date().getFullYear();
                const month = String((value.month ?? 0) + 1).padStart(2, '0');
                const day = String(value.day ?? 1).padStart(2, '0');
                this.endDate = `${year}-${month}-${day}`;
            }
        });
    }

    // 显示日期选择器
    showDatePickerDialog() {
        const dateArray = this.selectedDate.split('-');
        const selectedYear = parseInt(dateArray[0]);
        const selectedMonth = parseInt(dateArray[1]);
        const selectedDay = parseInt(dateArray[2]);
        
        // 如果启用了定期记账，开始日期必须是今天或未来
        const startDate = this.isRecurring ? new Date() : new Date('2000-1-1');
        
        this.getUIContext().showDatePickerDialog({
            start: startDate,
            end: new Date('2100-12-31'),
            selected: new Date(selectedYear, selectedMonth - 1, selectedDay),
            lunar: false,
            onAccept: (value: DatePickerResult) => {
                const year = value.year ?? new Date().getFullYear();
                const month = String((value.month ?? 0) + 1).padStart(2, '0');
                const day = String(value.day ?? 1).padStart(2, '0');
                this.selectedDate = `${year}-${month}-${day}`;
            }
        });
    }

    // 保存账单
    async saveBill() {
        // 验证金额
        const amountNum = parseFloat(this.amount);
        if (isNaN(amountNum) || amountNum <= 0) {
            this.getUIContext().showAlertDialog({
                message: '请输入正确的金额',
                confirm: {
                    value: '确定',
                    action: () => {
                    }
                }
            });
            return;
        }

        try {
            let generatedCount = 0;
            
            if (this.isRecurring) {
                // 保存定期记账配置并立即生成账单
                generatedCount = await this.saveRecurringBill(amountNum);
            } else {
                // 保存普通账单
                await this.saveNormalBill(amountNum);
            }

            // 保存用户选择的分类
            await this.prefsUtil.saveLastCategory(this.selectedType, this.selectedCategory);

            // 清空表单
            this.resetForm();

            // 显示成功提示
            if (this.isRecurring) {
                this.getUIContext().getPromptAction().showToast({
                    message: `定期记账配置保存成功，已自动生成${generatedCount}条账单`,
                    duration: 2000
                });
            } else {
                this.getUIContext().getPromptAction().showToast({
                    message: "保存成功",
                    duration: 1500
                });
            }
        } catch (err) {
            this.getUIContext().showAlertDialog({
                message: '保存失败: ' + JSON.stringify(err),
                confirm: {
                    value: '确定',
                    action: () => {
                    }
                }
            });
        }
    }

    // 保存普通账单
    async saveNormalBill(amountNum: number) {
        const bill = new BillModel(
            amountNum,
            this.selectedType,
            this.selectedCategory,
            this.selectedDate,
            this.note
        );
        await this.billDb.insertBill(bill);
    }

    // 保存定期记账配置并立即生成账单
    async saveRecurringBill(amountNum: number): Promise<number> {
        // 验证间隔
        const intervalNum = parseInt(this.interval);
        if (isNaN(intervalNum) || intervalNum < 1) {
            throw new Error('间隔必须大于等于1');
        }

        // 验证重复次数（如果填写了）
        let repeatCountNum: number | undefined = undefined;
        if (this.repeatCount) {
            repeatCountNum = parseInt(this.repeatCount);
            if (isNaN(repeatCountNum) || repeatCountNum < 1) {
                throw new Error('重复次数必须大于等于1');
            }
        }

        // 验证截止日期（如果填写了）
        if (this.endDate && this.endDate <= this.selectedDate) {
            throw new Error('截止日期必须晚于开始日期');
        }

        // 创建定期配置对象
        const config = new RecurringBillConfig(
            amountNum,
            this.selectedType,
            this.selectedCategory,
            this.recurringType,
            intervalNum,
            this.selectedDate,
            this.note,
            repeatCountNum,
            this.endDate || undefined
        );

        // 验证配置
        const validationError = this.recurringService.validateConfig(config, DateUtil.getCurrentDate());
        if (validationError) {
            throw new Error(validationError);
        }

        // 保存配置
        await this.recurringDb.insertConfig(config);
        
        // 立即生成账单并返回生成数量
        const generatedCount = await this.recurringService.generateRecurringBills();
        return generatedCount;
    }

    // 重置表单
    resetForm() {
        this.amount = '';
        this.note = '';
        this.isRecurring = false;
        this.recurringType = RecurringType.DAILY;
        this.interval = '1';
        this.repeatCount = '';
        this.endDate = '';
        // 保持类型、分类和日期不变，方便连续记账
    }
}
