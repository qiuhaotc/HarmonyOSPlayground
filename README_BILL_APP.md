# 记账本应用 - HarmonyOS

这是一个基于HarmonyOS(ArkTS)开发的记账应用,支持记录日常收支、按年月和分类进行统计分析。

## 功能特性

### 1. 记账功能
- ✅ 支持收入和支出两种类型
- ✅ 提供多种预定义分类(餐饮、交通、购物、娱乐等)
- ✅ 自定义金额和备注信息
- ✅ 按日期记录账单

### 2. 账单管理
- ✅ 查看账单列表
- ✅ 按年月筛选账单
- ✅ 显示收入、支出和结余统计
- ✅ 滑动删除账单
- ✅ 快速添加新账单

### 3. 统计分析
- ✅ 按年月统计收支情况
- ✅ 按分类统计支出占比
- ✅ 分类详情查看
- ✅ 可视化展示统计数据

## 项目结构

```
entry/src/main/ets/
├── models/              # 数据模型
│   └── BillModel.ets   # 账单模型、分类定义
├── database/           # 数据库管理
│   └── BillDatabase.ets # 关系型数据库操作
├── utils/              # 工具类
│   ├── BillStatisticsUtil.ets # 统计工具
│   └── DateUtil.ets    # 日期工具
└── pages/              # 页面
    ├── Index.ets       # 主页
    ├── AddBillPage.ets # 添加账单
    ├── BillListPage.ets # 账单列表
    ├── StatisticsPage.ets # 统计页面
    └── CategoryDetailPage.ets # 分类详情
```

## 数据模型

### BillModel (账单模型)
```typescript
{
  id: number,           // 自增ID
  amount: number,       // 金额
  type: BillType,       // 类型(收入/支出)
  category: string,     // 分类
  date: string,         // 日期 YYYY-MM-DD
  time: string,         // 时间 HH:mm:ss
  note: string,         // 备注
  createTime: string    // 创建时间
}
```

### 预定义分类

**支出分类:**
- 🍔 餐饮
- 🚗 交通
- 🛍️ 购物
- 🎬 娱乐
- 💊 医疗
- 🏠 住房
- 📚 教育
- 📱 通讯
- 📝 其他

**收入分类:**
- 💰 工资
- 🎁 奖金
- 📈 投资
- 💼 兼职
- 📝 其他

## 数据存储

使用HarmonyOS关系型数据库(RelationalStore)存储账单数据:

- 数据库名称: `BillDatabase.db`
- 表名: `bills`
- 安全级别: S1

### 数据库操作
- `insertBill()` - 插入账单
- `deleteBill()` - 删除账单
- `updateBill()` - 更新账单
- `queryAllBills()` - 查询所有账单
- `queryBillsByYearMonth()` - 按年月查询
- `queryBillsByCategory()` - 按分类查询
- `queryBillsByYearMonthAndCategory()` - 按年月和分类查询

## 统计功能

### BillStatistics (统计数据)
```typescript
{
  totalIncome: number,      // 总收入
  totalExpense: number,     // 总支出
  balance: number,          // 结余
  categoryStats: Map        // 分类统计
}
```

### 统计工具方法
- `calculateStatistics()` - 计算统计数据
- `groupByYearMonth()` - 按年月分组
- `groupByCategory()` - 按分类分组
- `getMonthlyStatistics()` - 获取月度统计
- `getCategoryStatistics()` - 获取分类统计
- `getCategoryPercentage()` - 计算分类占比

## 使用说明

### 1. 初始化
应用启动时会自动初始化数据库,无需手动操作。

### 2. 添加账单
1. 点击主页"记一笔"按钮
2. 输入金额
3. 选择类型(收入/支出)
4. 选择分类
5. 选择日期(默认当天)
6. 可选填备注
7. 点击保存

### 3. 查看账单
1. 点击主页"账单列表"按钮
2. 使用左右箭头切换月份
3. 查看该月的收支统计
4. 向左滑动账单可删除

### 4. 统计分析
1. 点击主页"统计分析"按钮
2. 查看月度收支总览
3. 查看各分类支出占比
4. 点击分类查看详细账单

## 技术栈

- **开发语言:** ArkTS
- **UI框架:** ArkUI
- **数据存储:** RelationalStore (关系型数据库)
- **路由管理:** @ohos.router
- **开发工具:** DevEco Studio

## 开发文档参考

- [HarmonyOS官方文档](https://developer.huawei.com/consumer/cn/doc/)
- [ArkTS语言基础](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-get-started-V5)
- [关系型数据库](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/data-persistence-by-rdb-store-V5)
- [ArkUI声明式UI](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-ui-development-overview-V5)

## 构建运行

### 环境要求
- DevEco Studio 5.0+
- HarmonyOS SDK API 12+

### 运行步骤
1. 使用DevEco Studio打开项目
2. 连接HarmonyOS设备或启动模拟器
3. 点击Run按钮运行应用

## 后续扩展功能

- [ ] 添加预算管理
- [ ] 支持图表可视化(饼图、折线图)
- [ ] 账单导入导出
- [ ] 数据备份与恢复
- [ ] 多账本支持
- [ ] 账单搜索功能
- [ ] 周期性账单(如每月固定支出)
- [ ] 账单图片附件

## 注意事项

1. 数据库初始化在应用启动时自动完成
2. 所有金额保留两位小数
3. 日期格式统一为 YYYY-MM-DD
4. 删除操作不可恢复,请谨慎操作

## 许可证

MIT License
