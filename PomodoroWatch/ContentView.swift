//
//  ContentView.swift
//  番茄钟
//
//  主界面（阶段 2 占位版）：验证 Theme 颜色与深色模式。
//  阶段 5 将替换为正式结构：横向分页（计时器页 + 统计页）+ 右上角齿轮（docs/DESIGN.md §4.1）。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.orange)

                Text("番茄钟")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text("专注 25 分钟 · 休息 5 分钟")
                    .font(Theme.idleSubtitleFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
