import { BillModel, BillType, DEFAULT_CATEGORIES, BillCategory } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { DateUtil } from '../utils/DateUtil';
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
    @State showDatePicker: boolean = false; // 是否显示日期选择器
    private billDb: BillDatabase = BillDatabase.getInstance();

    // 获取当前类型的分类列表
    currentCategories = DEFAULT_CATEGORIES.filter(cat => cat.type === this.selectedType);

    aboutToAppear() {
        // 默认选中第一个分类
        if (this.currentCategories.length > 0) {
            this.selectedCategory = this.currentCategories[0].name;
        }
    }

    build() {
        Column() {
            // 标题栏
            this.buildTitleBar();

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
        .height('100%')
        .backgroundColor('#F5F5F5')
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

            Text('   ')
                .fontSize(16)
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
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                    .backgroundColor(Color.Transparent)
                    .type(InputType.Number)
                    .layoutWeight(1)
                    .onChange((value: string) => {
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
                .onClick(() => {
                    this.selectedType = BillType.EXPENSE;
                    // 切换类型后重新选择第一个分类
                    if (this.currentCategories.length > 0) {
                        this.selectedCategory = this.currentCategories[0].name;
                    }
                })

            Button('收入')
                .fontSize(16)
                .fontColor(this.selectedType === BillType.INCOME ? '#FFFFFF' : '#333333')
                .backgroundColor(this.selectedType === BillType.INCOME ? '#00B894' : '#F0F0F0')
                .layoutWeight(1)
                .margin({ left: 12 })
                .onClick(() => {
                    this.selectedType = BillType.INCOME;
                    // 切换类型后重新选择第一个分类
                    if (this.currentCategories.length > 0) {
                        this.selectedCategory = this.currentCategories[0].name;
                    }
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
                .fontColor('#333333')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .onClick(() => {
                    this.showDatePicker = true;
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
            Text('备注')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ bottom: 8 })

            TextInput({ text: this.note, placeholder: '添加备注信息...' })
                .fontSize(16)
                .fontColor('#333333')
                .backgroundColor('#F0F0F0')
                .onChange((value: string) => {
                    this.note = value;
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

    // 保存账单
    async saveBill() {
        // 验证金额
        const amountNum = parseFloat(this.amount);
        if (isNaN(amountNum) || amountNum <= 0) {
            AlertDialog.show({
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
            DateUtil.getCurrentTime(),
            this.note
        );

        try {
            // 保存到数据库
            await this.billDb.insertBill(bill);

            // 显示成功提示
            AlertDialog.show({
                message: '保存成功',
                confirm: {
                    value: '确定',
                    action: () => {
                        router.back();
                    }
                }
            });
        } catch (err) {
            AlertDialog.show({
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
