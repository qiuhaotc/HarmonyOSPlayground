import { BillModel, BillType, DEFAULT_CATEGORIES } from '../models/BillModel';
import { BillDatabase } from '../database/BillDatabase';
import { BillStatisticsUtil } from '../utils/BillStatisticsUtil';
import { DateUtil } from '../utils/DateUtil';
import router from '@ohos.router';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { BusinessError } from '@ohos.base';
import util from '@ohos.util';

/**
 * 账单列表页面
 */
@Entry
@Component
struct BillListPage {
    @State bills: BillModel[] = []; // 账单列表
    @State selectedYear: string = DateUtil.getCurrentYear(); // 选中的年份
    @State selectedMonth: string = DateUtil.getCurrentMonth(); // 选中的月份
    @State totalIncome: number = 0; // 总收入
    @State totalExpense: number = 0; // 总支出
    @State balance: number = 0; // 结余
    @State showClearDialog: boolean = false; // 显示清空账单弹窗
    @State clearStartDate: string = ''; // 清空起始日期
    @State clearEndDate: string = ''; // 清空结束日期
    @State showClearStartDatePicker: boolean = false; // 显示清空起始日期选择器
    @State showClearEndDatePicker: boolean = false; // 显示清空结束日期选择器

    private billDb: BillDatabase = BillDatabase.getInstance();

    aboutToAppear() {
        this.loadBills();
    }

    // 页面每次显示时刷新数据
    onPageShow() {
        this.loadBills();
    }

    // 加载账单数据
    async loadBills() {
        try {
            this.bills = await this.billDb.queryBillsByYearMonth(this.selectedYear, this.selectedMonth);
            this.calculateStatistics();
        } catch (err) {
            console.error('加载账单失败', JSON.stringify(err));
        }
    }

    // 计算统计数据
    calculateStatistics() {
        const stats = BillStatisticsUtil.calculateStatistics(this.bills);
        this.totalIncome = stats.totalIncome;
        this.totalExpense = stats.totalExpense;
        this.balance = stats.balance;
    }

    // 获取分类图标
    getCategoryIcon(categoryName: string): string {
        const category = DEFAULT_CATEGORIES.find(cat => cat.name === categoryName);
        return category ? category.icon : '📝';
    }

    build() {
        Column() {
            // 标题栏
            this.buildTitleBar();

            // 日期选择器
            this.buildDateSelector();

            // 统计卡片
            this.buildStatisticsCard();

            // 导入导出按钮
            this.buildImportExportButtons();

            // 账单列表（已支持滚动）
            this.buildBillList();

            // 清空账单按钮
            this.buildClearButton();

            // 添加按钮
            this.buildAddButton();

            // 清空账单弹窗
            if (this.showClearDialog) {
                this.buildClearBillsDialog();
            }
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

            Text('账单列表')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

            Text('统计')
                .fontSize(16)
                .fontColor($r('app.color.primary_color'))
                .onClick(() => {
                    router.pushUrl({ url: 'pages/StatisticsPage' });
                })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor($r('app.color.card_background'))
    }

    @Builder
    buildDateSelector() {
        Row() {
            Button('<')
                .fontSize(18)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.page_background'))
                .width(40)
                .height(40)
                .onClick(() => {
                    this.previousMonth();
                })

            Text(DateUtil.formatYearMonth(`${this.selectedYear}-${this.selectedMonth}`))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.Center)

            Button('>')
                .fontSize(18)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.page_background'))
                .width(40)
                .height(40)
                .onClick(() => {
                    this.nextMonth();
                })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 1 })
    }

    @Builder
    buildStatisticsCard() {
        Column() {
            Row() {
                Column() {
                    Text('收入')
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalIncome))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.success_color'))
                        .margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                    Text('支出')
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                    Text('¥' + BillStatisticsUtil.formatAmount(this.totalExpense))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.danger_color'))
                        .margin({ top: 4 })
                }
                .layoutWeight(1)

                Column() {
                    Text('结余')
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                    Text('¥' + BillStatisticsUtil.formatAmount(this.balance))
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.balance >= 0 ? $r('app.color.text_primary') : $r('app.color.danger_color'))
                        .margin({ top: 4 })
                }
                .layoutWeight(1)
            }
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .margin({ top: 12 })
        .borderRadius(8)
    }

    @Builder
    buildImportExportButtons() {
        Row() {
            Button('📤 导出数据')
                .fontSize(15)
                .fontColor('#FFFFFF')
                .backgroundColor($r('app.color.success_color'))
                .height(44)
                .layoutWeight(1)
                .onClick(() => {
                    this.exportData();
                })

            Blank()
                .width(12)

            Button('📥 导入数据')
                .fontSize(15)
                .fontColor('#FFFFFF')
                .backgroundColor($r('app.color.info_color'))
                .height(44)
                .layoutWeight(1)
                .onClick(() => {
                    this.importData();
                })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12 })
    }

    @Builder
    buildBillList() {
        List() {
            ForEach(this.bills, (bill: BillModel) => {
                ListItem() {
                    this.buildBillItem(bill);
                }
                .swipeAction({ end: this.buildDeleteButton(bill) })
            })
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 12 })
    }

    @Builder
    buildClearButton() {
        Button('🗑️ 清空账单')
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.danger_color'))
            .height(44)
            .width('100%')
            .margin({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
                this.showClearBillsDialog();
            })
    }

    @Builder
    buildBillItem(bill: BillModel) {
        Row() {
            // 分类图标
            Text(this.getCategoryIcon(bill.category))
                .fontSize(32)
                .margin({ right: 12 })

            Column() {
                Text(bill.category)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))

                Text(DateUtil.formatDateChinese(bill.date))
                    .fontSize(12)
                    .fontColor($r('app.color.text_tertiary'))
                    .margin({ top: 4 })

                if (bill.note) {
                    Text(bill.note)
                        .fontSize(12)
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ top: 4 })
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text((bill.type === BillType.INCOME ? '+' : '-') + '¥' + BillStatisticsUtil.formatAmount(bill.amount))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(bill.type === BillType.INCOME ? $r('app.color.success_color') : $r('app.color.danger_color'))
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
        .margin({ left: 12, right: 12, bottom: 8 })
    }

    @Builder
    buildDeleteButton(bill: BillModel) {
        Button('删除')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.danger_color'))
            .height('100%')
            .onClick(() => {
                this.deleteBill(bill);
            })
    }

    @Builder
    buildAddButton() {
        Button('+')
            .fontSize(32)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.primary_color'))
            .width(56)
            .height(56)
            .borderRadius(28)
            .position({ x: '85%', y: '85%' })
            .onClick(() => {
                router.pushUrl({ url: 'pages/AddBillPage' });
            })
    }

    // 上一个月
    previousMonth() {
        let year = parseInt(this.selectedYear);
        let month = parseInt(this.selectedMonth);

        month--;
        if (month < 1) {
            month = 12;
            year--;
        }

        this.selectedYear = String(year);
        this.selectedMonth = String(month).padStart(2, '0');
        this.loadBills();
    }

    // 下一个月
    nextMonth() {
        let year = parseInt(this.selectedYear);
        let month = parseInt(this.selectedMonth);

        month++;
        if (month > 12) {
            month = 1;
            year++;
        }

        this.selectedYear = String(year);
        this.selectedMonth = String(month).padStart(2, '0');
        this.loadBills();
    }

    // 删除账单
    async deleteBill(bill: BillModel) {
        if (!bill.id) {
            return;
        }

        try {
            await this.billDb.deleteBill(bill.id);
            await this.loadBills();
        } catch (err) {
            console.error('删除账单失败', JSON.stringify(err));
        }
    }

    // 导出数据
    async exportData() {
        try {
            // 查询所有账单
            const allBills = await this.billDb.queryAllBills();

            if (allBills.length === 0) {
                this.getUIContext().showAlertDialog({
                    message: '没有数据可导出',
                    confirm: {
                        value: '确定', action: () => {
                        }
                    }
                });
                return;
            }

            // 转换为JSON字符串
            const jsonData = JSON.stringify(allBills, null, 2);

            // 使用文档选择器保存文件
            const documentSaveOptions = new picker.DocumentSaveOptions();
            documentSaveOptions.newFileNames = [`bills_backup_${DateUtil.formatDate(new Date())}.json`];
            const documentPicker = new picker.DocumentViewPicker();

            const uris = await documentPicker.save(documentSaveOptions);
            if (uris && uris.length > 0) {
                const file = fs.openSync(uris[0], fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
                // 使用UTF-8编码写入,避免中文乱码
                const encoder = new util.TextEncoder();
                const uint8Array = encoder.encodeInto(jsonData);
                fs.writeSync(file.fd, uint8Array.buffer);
                fs.closeSync(file);

                this.getUIContext().showAlertDialog({
                    message: `成功导出 ${allBills.length} 条账单记录\n(包含主键ID)`,
                    confirm: {
                        value: '确定', action: () => {
                        }
                    }
                });
            }
        } catch (err) {
            console.error('导出数据失败', JSON.stringify(err));
            this.getUIContext().showAlertDialog({
                message: '导出失败: ' + (err as BusinessError).message,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        }
    }

    // 导入数据
    async importData() {
        try {
            // 使用文档选择器选择文件
            const documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.maxSelectNumber = 1;
            const documentPicker = new picker.DocumentViewPicker();

            const uris = await documentPicker.select(documentSelectOptions);
            if (!uris || uris.length === 0) {
                return;
            }

            // 读取文件内容
            const file = fs.openSync(uris[0], fs.OpenMode.READ_ONLY);
            const buffer = new ArrayBuffer(10 * 1024 * 1024); // 10MB 缓冲区
            const readLen = fs.readSync(file.fd, buffer);
            fs.closeSync(file);

            // 使用UTF-8解码,避免中文乱码
            const decoder = util.TextDecoder.create('utf-8');
            const jsonStr = decoder.decodeToString(new Uint8Array(buffer, 0, readLen));
            const bills: BillModel[] = JSON.parse(jsonStr);

            // 确认导入
            this.getUIContext().showAlertDialog({
                message: `文件包含 ${bills.length} 条账单记录，是否导入？\n主键相同的记录将被更新`,
                primaryButton:{
                    value: '导入',
                    fontColor: '#FF0000',
                    action: async () => {
                        await this.performImport(bills);
                    }
                },
                secondaryButton:{
                    value: '取消',
                    action:() => {}
                },
                cancel: () => {
                }
            });
        } catch (err) {
            console.error('导入数据失败', JSON.stringify(err));
            this.getUIContext().showAlertDialog({
                message: '导入失败: ' + (err as BusinessError).message,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        }
    }

    // 执行导入
    async performImport(bills: BillModel[]) {
        try {
            let insertCount = 0;
            let updateCount = 0;
            let failCount = 0;

            for (const bill of bills) {
                try {
                    if (bill.id) {
                        // 检查ID是否存在
                        const existingBill = await this.billDb.queryBillById(bill.id);
                        if (existingBill) {
                            // ID存在,执行更新
                            await this.billDb.updateBill(bill);
                            updateCount++;
                        } else {
                            // ID不存在,直接插入(使用原ID)
                            await this.billDb.insertBill(bill);
                            insertCount++;
                        }
                    } else {
                        // 没有ID,插入新记录
                        await this.billDb.insertBill(bill);
                        insertCount++;
                    }
                } catch (err) {
                    console.error('导入账单失败', JSON.stringify(err));
                    failCount++;
                }
            }

            await this.loadBills();

            this.getUIContext().showAlertDialog({
                message: `导入完成\n新增: ${insertCount} 条\n更新: ${updateCount} 条\n失败: ${failCount} 条`,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        } catch (err) {
            console.error('执行导入失败', JSON.stringify(err));
            this.getUIContext().showAlertDialog({
                message: '导入过程出错: ' + (err as BusinessError).message,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        }
    }

    // 显示清空账单对话框
    showClearBillsDialog() {
        // 初始化默认日期范围（当前月份的第一天到最后一天）
        const year = parseInt(this.selectedYear);
        const month = parseInt(this.selectedMonth);
        this.clearStartDate = `${this.selectedYear}-${this.selectedMonth}-01`;
        
        // 计算月份最后一天
        const lastDay = new Date(year, month, 0).getDate();
        this.clearEndDate = `${this.selectedYear}-${this.selectedMonth}-${String(lastDay).padStart(2, '0')}`;
        
        this.showClearDialog = true;
    }

    // 清空账单弹窗
    @Builder
    buildClearBillsDialog() {
        Stack() {
            // 遮罩层
            Column()
                .width('100%')
                .height('100%')
                .backgroundColor('rgba(0, 0, 0, 0.5)')
                .onClick(() => {
                    this.showClearDialog = false;
                    this.showClearStartDatePicker = false;
                    this.showClearEndDatePicker = false;
                })

            // 对话框内容
            Column() {
                Text('清空账单')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                    .margin({ bottom: 20 })

                // 起始日期
                Row() {
                    Text('起始日期:')
                        .fontSize(14)
                        .fontColor($r('app.color.text_primary'))
                        .width(80)

                    Text(this.clearStartDate)
                        .fontSize(14)
                        .fontColor(this.clearStartDate ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.showClearStartDatePickerDialog();
                        })
                }
                .width('100%')
                .margin({ bottom: 16 })

                // 结束日期
                Row() {
                    Text('结束日期:')
                        .fontSize(14)
                        .fontColor($r('app.color.text_primary'))
                        .width(80)

                    Text(this.clearEndDate)
                        .fontSize(14)
                        .fontColor(this.clearEndDate ? $r('app.color.primary_color') : $r('app.color.text_tertiary'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.showClearEndDatePickerDialog();
                        })
                }
                .width('100%')
                .margin({ bottom: 20 })

                // 按钮
                Row() {
                    Button('确认清空')
                        .fontSize(15)
                        .fontColor('#FFFFFF')
                        .backgroundColor($r('app.color.danger_color'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.confirmClearBills();
                        })

                    Blank()
                        .width(12)

                    Button('取消')
                        .fontSize(15)
                        .fontColor($r('app.color.text_primary'))
                        .backgroundColor($r('app.color.page_background'))
                        .layoutWeight(1)
                        .onClick(() => {
                            this.showClearDialog = false;
                        })
                }
                .width('100%')
            }
            .width('85%')
            .padding(20)
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(12)

            // 起始日期选择器
            if (this.showClearStartDatePicker) {
                Column() {
                    DatePicker({
                        start: new Date('2000-01-01'),
                        selected: this.parseDateString(this.clearStartDate)
                    })
                        .onChange((value: DatePickerResult) => {
                            this.clearStartDate = this.formatDatePickerResult(value);
                            this.showClearStartDatePicker = false;
                        })

                    Button('取消')
                        .fontSize(14)
                        .margin({ top: 10 })
                        .onClick(() => {
                            this.showClearStartDatePicker = false;
                        })
                }
                .width('85%')
                .padding(20)
                .backgroundColor($r('app.color.card_background'))
                .borderRadius(12)
            }

            // 结束日期选择器
            if (this.showClearEndDatePicker) {
                Column() {
                    DatePicker({
                        start: new Date('2000-01-01'),
                        selected: this.parseDateString(this.clearEndDate)
                    })
                        .onChange((value: DatePickerResult) => {
                            this.clearEndDate = this.formatDatePickerResult(value);
                            this.showClearEndDatePicker = false;
                        })

                    Button('取消')
                        .fontSize(14)
                        .margin({ top: 10 })
                        .onClick(() => {
                            this.showClearEndDatePicker = false;
                        })
                }
                .width('85%')
                .padding(20)
                .backgroundColor($r('app.color.card_background'))
                .borderRadius(12)
            }
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(1000)
        .alignContent(Alignment.Center)
    }

    // 显示起始日期选择器
    showClearStartDatePickerDialog() {
        this.showClearStartDatePicker = true;
        this.showClearEndDatePicker = false;
    }

    // 显示结束日期选择器
    showClearEndDatePickerDialog() {
        this.showClearEndDatePicker = true;
        this.showClearStartDatePicker = false;
    }

    // 解析日期字符串为Date对象
    parseDateString(dateStr: string): Date {
        if (!dateStr) {
            return new Date();
        }
        const parts = dateStr.split('-');
        if (parts.length === 3) {
            return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        }
        return new Date();
    }

    // 格式化DatePicker结果为YYYY-MM-DD
    formatDatePickerResult(value: DatePickerResult): string {
        const year = value.year;
        const month = String((value.month ?? 0) + 1).padStart(2, '0');
        const day = String(value.day).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }


    // 确认清空账单
    async confirmClearBills() {
        // 验证日期范围
        if (this.clearStartDate > this.clearEndDate) {
            this.getUIContext().showAlertDialog({
                message: '起始日期不能大于结束日期',
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
            return;
        }

        try {
            // 使用日期范围查询,提升性能
            const billsToDelete = await this.billDb.queryBillsByDateRange(this.clearStartDate, this.clearEndDate);

            if (billsToDelete.length === 0) {
                this.getUIContext().showAlertDialog({
                    message: '该日期范围内没有账单记录',
                    confirm: {
                        value: '确定', action: () => {
                            this.showClearDialog = false;
                        }
                    }
                });
                return;
            }

            // 显示确认对话框
            this.getUIContext().showAlertDialog({
                message: `确定要删除 ${this.clearStartDate} 至 ${this.clearEndDate} 期间的 ${billsToDelete.length} 条账单记录吗？\n\n此操作不可恢复！`,
                primaryButton: {
                    value: '删除',
                    fontColor: '#FF0000',
                    action: async () => {
                        await this.performClearBills(billsToDelete);
                    }
                },
                secondaryButton: {
                    value: '取消',
                    action: () => {
                    }
                }
            });
        } catch (err) {
            console.error('查询账单失败', JSON.stringify(err));
            this.getUIContext().showAlertDialog({
                message: '查询账单失败: ' + (err as BusinessError).message,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        }
    }

    // 执行清空账单
    async performClearBills(billsToDelete: BillModel[]) {
        try {
            let successCount = 0;
            let failCount = 0;

            for (const bill of billsToDelete) {
                if (bill.id) {
                    try {
                        await this.billDb.deleteBill(bill.id);
                        successCount++;
                    } catch (err) {
                        console.error('删除账单失败', JSON.stringify(err));
                        failCount++;
                    }
                }
            }

            this.showClearDialog = false;
            await this.loadBills();

            this.getUIContext().showAlertDialog({
                message: `清空完成\n成功删除: ${successCount} 条\n失败: ${failCount} 条`,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        } catch (err) {
            console.error('清空账单失败', JSON.stringify(err));
            this.getUIContext().showAlertDialog({
                message: '清空账单失败: ' + (err as BusinessError).message,
                confirm: {
                    value: '确定', action: () => {
                    }
                }
            });
        }
    }
}
