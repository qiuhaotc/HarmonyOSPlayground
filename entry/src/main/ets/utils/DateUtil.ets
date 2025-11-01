/**
 * 日期工具类
 */
export class DateUtil {
  /**
   * 获取当前日期 格式: YYYY-MM-DD
   */
  static getCurrentDate(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化日期对象为字符串 格式: YYYY-MM-DD
   */
  static formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 获取当前时间 格式: HH:mm:ss
   */
  static getCurrentTime(): string {
    const date = new Date();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  /**
   * 获取当前年份
   */
  static getCurrentYear(): string {
    return String(new Date().getFullYear());
  }

  /**
   * 获取当前月份
   */
  static getCurrentMonth(): string {
    return String(new Date().getMonth() + 1).padStart(2, '0');
  }

  /**
   * 格式化日期显示 YYYY-MM-DD -> YYYY年MM月DD日
   */
  static formatDateChinese(date: string): string {
    if (!date || date.length < 10) {
      return date;
    }
    const parts = date.split('-');
    return `${parts[0]}年${parts[1]}月${parts[2]}日`;
  }

  /**
   * 格式化时间显示 HH:mm:ss -> HH:mm
   */
  static formatTimeShort(time: string): string {
    if (!time || time.length < 5) {
      return time;
    }
    return time.substring(0, 5);
  }

  /**
   * 获取年月显示 YYYY-MM -> YYYY年MM月
   */
  static formatYearMonth(yearMonth: string): string {
    if (!yearMonth || yearMonth.length < 7) {
      return yearMonth;
    }
    const parts = yearMonth.split('-');
    return `${parts[0]}年${parts[1]}月`;
  }

  /**
   * 获取最近N个月的年月列表
   */
  static getRecentMonths(count: number): string[] {
    const months: string[] = [];
    const date = new Date();

    for (let i = 0; i < count; i++) {
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      months.push(`${year}-${month}`);

      // 减一个月
      date.setMonth(date.getMonth() - 1);
    }

    return months;
  }
}
