//
//  StatisticsStore.swift
//  番茄钟
//
//  统计账本（docs/TECH.md §6：统计读写只在这里）。
//  存储：UserDefaults 字典 dailyFocusMinutes：`"yyyy-MM-dd"` → 分钟数（docs/TECH.md §5）。
//  阶段 6 将扩展近 7 天聚合等图表数据。
//

import Foundation

final class StatisticsStore {

    static let shared = StatisticsStore()

    private init() {}

    // MARK: - 日期键

    /// 把日期转成统计键 `"yyyy-MM-dd"`（本地时区；跨午夜的专注记在结束当天）
    static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - 记账

    /// 累加当天专注分钟数。
    /// 幂等性由调用方（TimerModel 的 sessionCounted 标记）保证，这里只管加。
    func record(minutes: Int, at date: Date) {
        let defaults = UserDefaults.standard
        var all = defaults.dictionary(forKey: StorageKeys.dailyFocusMinutes) as? [String: Int] ?? [:]
        all[Self.dayKey(for: date), default: 0] += minutes
        defaults.set(all, forKey: StorageKeys.dailyFocusMinutes)
    }

    // 阶段 6 扩展：查询某天/近 7 天数据、清空统计等
}
