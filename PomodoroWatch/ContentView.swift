//
//  ContentView.swift
//  番茄钟
//
//  主界面（docs/DESIGN.md §4.1）：横向分页 TabView，共 2 页，底部圆点指示。
//  第一页 = 计时器（TimerView）；第二页 = 统计（阶段 6 换真正的 StatsView）。
//  右上角齿轮 = 设置页入口（阶段 7 接线 sheet，当前占位）。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            TabView {
                TimerView()
                    .tag(0)

                // 第二页占位：阶段 6 换成 StatsView（近 7 天柱状图）
                statsPlaceholder
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // TODO(阶段 7)：点击打开设置 sheet（设置页带「完成」按钮）
                Button {
                    // 阶段 7 接线
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 第二页占位（阶段 6 删除）

    private var statsPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.orange)

            Text("专注统计")
                .font(Theme.pageTitleFont)
                .foregroundStyle(Theme.textPrimary)

            Text("阶段 6 上线")
                .font(Theme.idleSubtitleFont)
                .foregroundStyle(Theme.textTertiary)
        }
    }
}

#Preview {
    ContentView()
}
