//
//  SettingsView.swift
//  番茄钟
//
//  设置页（docs/DESIGN.md §4.4）：时长选择 + 维护操作。
//  由 ContentView 右上角齿轮以 sheet 弹出，右上角带「完成」按钮。
//  时长改动即写 UserDefaults（@AppStorage）；TimerModel 在下一轮开始时读取，故「下一轮生效」。
//

import SwiftUI

struct SettingsView: View {

    /// 设置项（docs/TECH.md §5：focusMinutes / restMinutes）
    @AppStorage(StorageKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(StorageKeys.restMinutes) private var restMinutes = 5

    /// 关闭弹层（右上角「完成」）
    @Environment(\.dismiss) private var dismiss

    /// 清除统计的确认弹窗
    @State private var showClearConfirm = false

    /// 专注时长档位（分钟）；DEBUG 额外提供 1 分钟快测档（docs/TECH.md §8）
    private var focusOptions: [Int] {
        var options = [15, 20, 25, 30, 45, 60]
        #if DEBUG
        options.insert(1, at: 0)
        #endif
        return options
    }

    /// 休息时长档位（分钟）；DEBUG 额外提供 1 分钟快测档
    private var restOptions: [Int] {
        var options = [5, 10, 15, 20]
        #if DEBUG
        options.insert(1, at: 0)
        #endif
        return options
    }

    var body: some View {
        Form {
            // 第一节：时长（docs/DESIGN.md §4.4）
            Section {
                Picker("专注时长", selection: $focusMinutes) {
                    ForEach(focusOptions, id: \.self) { minutes in
                        Text("\(minutes) 分钟").tag(minutes)
                    }
                }
                Picker("休息时长", selection: $restMinutes) {
                    ForEach(restOptions, id: \.self) { minutes in
                        Text("\(minutes) 分钟").tag(minutes)
                    }
                }
            } footer: {
                Text("修改将在下一轮开始时生效。")
            }

            // 第二节：维护
            Section {
                Button("清除统计数据", role: .destructive) {
                    showClearConfirm = true
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .alert("确定清除所有专注统计？", isPresented: $showClearConfirm) {
            Button("清除", role: .destructive) {
                StatisticsStore.shared.clearAll()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("近 7 天图表数据将被清空，无法恢复。")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
