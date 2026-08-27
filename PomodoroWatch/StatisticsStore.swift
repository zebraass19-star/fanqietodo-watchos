//
//  StatisticsStore.swift
//  番茄钟
//
//  统计账本（docs/TECH.md §6：统计读写只在这里）。
//  存储：UserDefaults 字典 dailyFocusMinutes：`"yyyy-MM-dd"` → 分钟数（docs/TECH.md §5）。
//

import Foundation
import Combine

/// 某一天的专注分钟快照（图表数据源；date 为该天零点）
struct DayStat {
    let date: Date
    let minutes: Int
}

final class StatisticsStore: ObservableObject {

    /// 数据版本号：每次记账/清空 +1，统计页据此自动刷新（阶段 7）
    @Published private(set) var revision = 0

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
        revision += 1
    }

    // MARK: - 查询（阶段 6：图表数据）

    /// 近 7 天（含今天）逐日分钟数，按时间从早到晚排列
    func last7Days(endingAt endDate: Date) -> [DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: endDate)
        let all = UserDefaults.standard.dictionary(forKey: StorageKeys.dailyFocusMinutes) as? [String: Int] ?? [:]
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return DayStat(date: day, minutes: all[Self.dayKey(for: day)] ?? 0)
        }
    }

    // MARK: - 维护（阶段 7 接线）

    /// 清空全部统计（设置页「清除统计数据」按钮用）
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.dailyFocusMinutes)
        revision += 1
    }
}
