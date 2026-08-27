//
//  ContentView.swift
//  番茄钟
//
//  主界面（docs/DESIGN.md §4.1）：横向分页 TabView，共 2 页，底部圆点指示。
//  第一页 = 计时器（TimerView）；第二页 = 统计（StatsView）。
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

                // 第二页：近 7 天柱状图（docs/DESIGN.md §4.3）
                StatsView()
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
}

#Preview {
    ContentView()
}
