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
        // TODO(阶段 3)：注册通知分类与 UNUserNotificationCenter 代理
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
