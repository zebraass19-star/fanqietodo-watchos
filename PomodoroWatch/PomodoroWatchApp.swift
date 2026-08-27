//
//  PomodoroWatchApp.swift
//  番茄钟
//
//  App 入口。
//  重要：通知分类与代理必须在 App.init() 里最早注册（docs/TECH.md §2.6），
//  否则冷启动时到达的通知按钮回调会丢失。阶段 3 将在这里接入 NotificationManager。
//

import SwiftUI

@main
struct PomodoroWatchApp: App {
    init() {
        // 通知分类与代理必须在 App 启动最早期注册（docs/TECH.md §2.6）
        NotificationManager.shared.register()
        // 权限只弹一次框（内部有标记位控制）
        NotificationManager.shared.requestPermissionIfNeeded()
        // 读取当前权限状态（非首次启动时权限弹窗不会再弹，需要主动查询）
        NotificationManager.shared.refreshPermissionStatus()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
