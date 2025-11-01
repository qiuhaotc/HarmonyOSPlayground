# 记账本应用 - HarmonyOS

这是一个基于HarmonyOS(ArkTS)开发的记账应用,支持记录日常收支、定期记账、按年月和分类进行统计分析。

> 📖 **[快速开始指南](QUICK_START.md)** - 查看详细的使用教程和开发指南

## 📱 应用截图

<table>
  <tr>
    <td><img src="Docs/1主页.png" alt="主页" width="200"/></td>
    <td><img src="Docs/2记一笔.png" alt="记一笔" width="200"/></td>
    <td><img src="Docs/4定期记账.png" alt="定期记账" width="200"/></td>
    <td><img src="Docs/6账单.png" alt="账单列表" width="200"/></td>
  </tr>
  <tr>
    <td align="center">主页</td>
    <td align="center">记一笔</td>
    <td align="center">定期记账</td>
    <td align="center">账单列表</td>
  </tr>
</table>

> 更多界面截图请查看 [快速开始指南](QUICK_START.md#-界面预览)

## 功能特性

### 1. 记账功能
- ✅ 支持收入和支出两种类型
- ✅ 提供多种预定义分类(餐饮、交通、购物、娱乐等)
- ✅ 自定义金额和备注信息
- ✅ 按日期记录账单

### 2. 定期记账 ⭐新增
- ✅ 支持按天/周/月自动生成账单
- ✅ 灵活配置重复次数和截止日期
- ✅ APP启动时自动生成应生成的账单
- ✅ 智能防重复生成机制
- ✅ 配置到期自动禁用
- ✅ 删除时可选是否删除关联账单
- ✅ 自动生成的账单添加`[定期]`标识

### 3. 账单管理
- ✅ 查看账单列表
- ✅ 按年月筛选账单
- ✅ 显示收入、支出和结余统计
- ✅ 滑动删除账单
- ✅ 快速添加新账单

### 4. 统计分析
- ✅ 按年月统计收支情况
- ✅ 按分类统计支出占比
- ✅ 分类详情查看
- ✅ 可视化展示统计数据

## 项目结构

```
entry/src/main/ets/
├── models/              # 数据模型
│   ├── BillModel.ets   # 账单模型、分类定义
│   └── RecurringBillModel.ets # 定期记账模型 ⭐新增
├── database/           # 数据库管理
│   ├── BillDatabase.ets # 账单数据库操作
│   └── RecurringBillDatabase.ets # 定期记账数据库操作 ⭐新增
├── utils/              # 工具类
│   ├── BillStatisticsUtil.ets # 统计工具
│   ├── DateUtil.ets    # 日期工具
│   └── RecurringBillService.ets # 定期记账服务 ⭐新增
└── pages/              # 页面
    ├── Index.ets       # 主页
    ├── AddBillPage.ets # 添加账单(含定期配置)
    ├── BillListPage.ets # 账单列表
    ├── StatisticsPage.ets # 统计页面
    ├── CategoryDetailPage.ets # 分类详情
    └── RecurringBillManagePage.ets # 定期记账管理 ⭐新增
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
  note: string,         // 备注
  createTime: string    // 创建时间戳
}
```

### RecurringBillConfig (定期记账配置) ⭐新增
```typescript
{
  id: number,              // 自增ID
  amount: number,          // 金额
  type: BillType,          // 类型(收入/支出)
  category: string,        // 分类
  note: string,            // 备注
  recurringType: RecurringType, // 重复类型(daily/weekly/monthly)
  interval: number,        // 间隔
  repeatCount: number,     // 重复次数(可选)
  endDate: string,         // 截止日期(可选)
  startDate: string,       // 开始日期
  lastGeneratedDate: string, // 最后生成日期
  isActive: boolean,       // 是否启用
  createTime: string       // 创建时间
}
```

### GeneratedBillRecord (生成记录) ⭐新增
```typescript
{
  id: number,              // 自增ID
  recurringConfigId: number, // 配置ID(软外键)
  generatedDate: string,   // 生成日期
  billId: number,          // 账单ID(软外键)
  createTime: string       // 创建时间
}
```

### 预定义分类

**支出分类:**
- 🥢 餐饮
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

### 账单数据库操作
- `insertBill()` - 插入账单
- `deleteBill()` - 删除账单
- `updateBill()` - 更新账单
- `queryAllBills()` - 查询所有账单
- `queryBillsByYearMonth()` - 按年月查询
- `queryBillsByYear()` - 按年查询
- `queryBillsByCategory()` - 按分类查询
- `queryBillsByYearAndCategory()` - 按年和分类查询
- `queryBillsByYearMonthAndCategory()` - 按年月和分类查询

### 定期记账数据库操作 ⭐新增
- `insertConfig()` - 插入定期配置
- `deleteConfig()` - 删除定期配置
- `updateConfig()` - 更新定期配置
- `queryAllConfigs()` - 查询所有配置
- `queryConfigById()` - 根据ID查询配置
- `insertRecord()` - 插入生成记录
- `deleteRecordsByConfigId()` - 删除配置的所有记录
- `queryRecordsByConfigId()` - 查询配置的所有记录
- `hasGeneratedBill()` - 检查是否已生成账单

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
5. 点击"统计"按钮查看统计分析

### 4. 定期记账 ⭐新增
1. 点击主页"定期记账"按钮
2. 查看所有定期记账配置
3. 可启用/禁用配置
4. 删除配置时选择是否删除关联账单
5. 在"记一笔"页面可配置新的定期记账

### 5. 统计分析
1. 点击主页"统计分析"按钮或账单列表页的"统计"按钮
2. 查看月度收支总览
3. 查看各分类支出占比
4. 点击分类卡片查看该分类的详细账单

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
- [x] ~~周期性账单(如每月固定支出)~~ ✅ 已完成
- [ ] 账单图片附件
- [ ] 定期账单更复杂的规则(如每月第一天、每周一等)
- [ ] 定期账单预览功能
- [ ] 定期账单通知提醒

## 注意事项

1. 数据库初始化在应用启动时自动完成
2. 所有金额保留两位小数
3. 日期格式统一为 YYYY-MM-DD
4. 删除操作不可恢复,请谨慎操作
5. 账单按日期和创建时间降序排列
6. 支持记住上次选择的分类,方便连续记账

## 许可证

Apache License
MIT License
