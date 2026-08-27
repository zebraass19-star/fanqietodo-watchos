//
//  ContentView.swift
//  番茄钟
//
//  主界面（docs/DESIGN.md §4.1）：横向分页 TabView，共 2 页，底部圆点指示。
//  第一页 = 计时器（TimerView）；第二页 = 统计（StatsView）。
//  右上角齿轮 = 设置页入口（sheet 弹出，设置页自带「完成」按钮）。
//

import SwiftUI

struct ContentView: View {
    /// 设置弹层开关（齿轮按钮，docs/DESIGN.md §4.1）
    @State private var showSettings = false
    /// App 前台/后台状态（回到前台时刷新通知权限状态）
    @Environment(\.scenePhase) private var scenePhase

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
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: scenePhase) {
            // 回到前台：用户可能刚在系统设置里改过通知权限，刷新提示行状态
            if scenePhase == .active {
                NotificationManager.shared.refreshPermissionStatus()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
