//
//  StatsView.swift
//  番茄钟
//
//  第二页 · 专注统计（docs/DESIGN.md §4.3）：近 7 天柱状图。
//  数据来自 StatisticsStore；进入本页或状态变化时刷新。
//  0 分钟的日子只留空位不画柱（基准线保持存在）。
//

import SwiftUI
import Charts

struct StatsView: View {

    /// 近 7 天数据（进入本页时刷新）
    @State private var days: [DayStat] = []
    /// 观察状态机：阶段变化时刷新统计（例如前台点通知按钮完成补记）
    @ObservedObject private var model = TimerModel.shared

    var body: some View {
        VStack(spacing: 4) {
            Text("专注统计")
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.textPrimary)

            Text("今日 \(todayMinutes) 分钟")
                .font(Theme.todayMinutesFont)
                .foregroundStyle(Theme.textPrimary)

            Text("近 7 天共 \(weekTotal) 分钟")
                .font(Theme.idleSubtitleFont)
                .foregroundStyle(Theme.textTertiary)

            chart
                .frame(height: 96)
        }
        .onAppear { refresh() }
        .onChange(of: model.phase) { refresh() }
    }

    // MARK: - 柱状图（docs/DESIGN.md §4.3）

    private var chart: some View {
        Chart(items, id: \.label) { item in
            // 底部基准线（白 15%）
            RuleMark(y: .value("基线", 0))
                .foregroundStyle(Theme.baseline)
                .lineStyle(StrokeStyle(lineWidth: 1))

            // 今日亮橙 100%，往日透明橙 40%；0 分钟不画柱
            BarMark(
                x: .value("日期", item.label),
                y: .value("分钟", item.minutes)
            )
            .foregroundStyle(item.isToday ? Theme.orange : Theme.pastBar)
            .cornerRadius(3) // 柱宽由系统自动均分（watchOS 的 Charts 无固定柱宽 API，见 DESIGN §4.3）
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label)
                            .font(Theme.axisLabelFont)
                            .fontWeight(label == todayLabel ? .bold : .regular)
                            .foregroundStyle(label == todayLabel ? Theme.orange : Theme.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - 数据与显示辅助

    private var items: [(label: String, minutes: Int, isToday: Bool)] {
        days.map { day in
            (label(for: day.date), day.minutes, Calendar.current.isDateInToday(day.date))
        }
    }

    private var todayMinutes: Int {
        items.last(where: { $0.isToday })?.minutes ?? 0
    }

    private var weekTotal: Int {
        days.reduce(0) { $0 + $1.minutes }
    }

    /// 今日的横轴标签（用来加粗标橙）
    private var todayLabel: String {
        days.first(where: { Calendar.current.isDateInToday($0.date) }).map { label(for: $0.date) } ?? "今"
    }

    /// 横轴标签：今天 = 「今」，其余用星期几单字（docs/DESIGN.md §4.3）
    private func label(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "今" }
        let weekday = Calendar.current.component(.weekday, from: date) // 1=周日
        return ["日", "一", "二", "三", "四", "五", "六"][weekday - 1]
    }

    private func refresh() {
        days = StatisticsStore.shared.last7Days(endingAt: Date())
    }
}

#Preview {
    StatsView()
        .preferredColorScheme(.dark)
}
