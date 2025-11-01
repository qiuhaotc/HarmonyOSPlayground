import { BillModel, BillType, BillCategory, getCategoriesByType } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { DateUtil } from '../utils/DateUtil';
import { PreferencesUtil } from '../utils/PreferencesUtil';
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
    private billDb: BillDatabase = BillDatabase.getInstance();
    private prefsUtil: PreferencesUtil = PreferencesUtil.getInstance();

    async aboutToAppear() {
        // 初始化偏好设置
        try {
            await this.prefsUtil.init(getContext(this));
        } catch (err) {
            console.error('初始化偏好设置失败', JSON.stringify(err));
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
        .backgroundColor('#F5F5F5')
        .alignItems(HorizontalAlign.Start)
    }

    @Builder
    buildTitleBar() {
        Row() {
            Text('返回')
                .fontSize(16)
                .fontColor('#333333')
                .onClick(() => {
                    router.back();
                })

            Text('记一笔')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

            Text('账单')
                .fontSize(16)
                .fontColor('#007DFF')
                .onClick(() => {
                    router.pushUrl({ url: 'pages/BillListPage' });
                })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
    }

    @Builder
    buildAmountInput() {
        Column() {
            Text('金额')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ bottom: 8 })

            Row() {
                Text('¥')
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')

                TextInput({ text: this.amount, placeholder: '0.00' })
                    .fontSize(20)
                    .fontColor('#333333')
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
        .backgroundColor('#FFFFFF')
        .margin({ top: 12 })
    }

    @Builder
    buildTypeSelector() {
        Row() {
            Button('支出')
                .fontSize(16)
                .fontColor(this.selectedType === BillType.EXPENSE ? '#FFFFFF' : '#333333')
                .backgroundColor(this.selectedType === BillType.EXPENSE ? '#FF6B6B' : '#F0F0F0')
                .layoutWeight(1)
                .onClick(async () => {
                    this.selectedType = BillType.EXPENSE;
                    // 切换类型后重新加载分类
                    await this.loadCategories();
                })

            Button('收入')
                .fontSize(16)
                .fontColor(this.selectedType === BillType.INCOME ? '#FFFFFF' : '#333333')
                .backgroundColor(this.selectedType === BillType.INCOME ? '#00B894' : '#F0F0F0')
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
        .backgroundColor('#FFFFFF')
        .margin({ top: 1 })
    }

    @Builder
    buildCategorySelector() {
        Column() {
            Text('分类')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ bottom: 12 })
            Grid() {
                ForEach(this.currentCategories, (category: BillCategory) => {
                    GridItem() {
                        Column() {
                            Text(category.icon)
                                .fontSize(32)

                            Text(category.name)
                                .fontSize(14)
                                .fontColor(this.selectedCategory === category.name ? '#FFFFFF' : '#333333')
                                .margin({ top: 4 })
                        }
                        .width('100%')
                        .padding(12)
                        .borderRadius(8)
                        .backgroundColor(this.selectedCategory === category.name ? category.color : '#F0F0F0')
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
        .backgroundColor('#FFFFFF')
        .margin({ top: 1 })
    }

    @Builder
    buildDateSelector() {
        Row() {
            Text('日期')
                .fontSize(14)
                .fontColor('#999999')

            Text(DateUtil.formatDateChinese(this.selectedDate))
                .fontSize(16)
                .fontColor('#007DFF')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .onClick(() => {
                    this.showDatePickerDialog();
                })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#FFFFFF')
        .margin({ top: 1 })
    }

    @Builder
    buildNoteInput() {
        Column() {
            Row() {
                Text('备注')
                    .fontSize(14)
                    .fontColor('#999999')

                Blank()

                Text(`${this.note.length}/500`)
                    .fontSize(12)
                    .fontColor(this.note.length > 500 ? '#FF6B6B' : '#999999')
            }
            .width('100%')
            .margin({ bottom: 8 })

            TextInput({ text: this.note, placeholder: '添加备注信息...' })
                .fontSize(16)
                .fontColor('#333333')
                .backgroundColor('#F0F0F0')
                .maxLength(500)
                .onChange((value: string) => {
                    if (value.length <= 500) {
                        this.note = value;
                    }
                })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .margin({ top: 1 })
    }

    @Builder
    buildSaveButton() {
        Button('保存')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .backgroundColor(this.selectedType === BillType.EXPENSE ? '#FF6B6B' : '#00B894')
            .width('90%')
            .height(48)
            .margin({ top: 32 })
            .onClick(() => {
                this.saveBill();
            })
    }

    // 显示日期选择器
    showDatePickerDialog() {
        const dateArray = this.selectedDate.split('-');
        const selectedYear = parseInt(dateArray[0]);
        const selectedMonth = parseInt(dateArray[1]);
        const selectedDay = parseInt(dateArray[2]);
        this.getUIContext().showDatePickerDialog({
            start: new Date('2000-1-1'),
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

        // 创建账单对象
        const bill = new BillModel(
            amountNum,
            this.selectedType,
            this.selectedCategory,
            this.selectedDate,
            this.note
        );

        try {
            // 保存到数据库
            await this.billDb.insertBill(bill);

            // 保存用户选择的分类
            await this.prefsUtil.saveLastCategory(this.selectedType, this.selectedCategory);

            // 清空金额和备注，保留类型和分类选择
            this.amount = '';
            this.note = '';
            // 保持当前日期不变，方便连续记账

            // 显示成功提示
            this.getUIContext().getPromptAction().showToast({
                message: "保存成功",  // 提示文本
                duration: 1000      // 显示时长（毫秒）
            });
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
}
