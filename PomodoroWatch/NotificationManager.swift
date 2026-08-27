//
//  NotificationManager.swift
//  番茄钟
//
//  系统通知总管家（docs/TECH.md §4 为唯一标准）。
//  职责：注册通知分类、申请权限、排期/取消阶段结束通知、处理通知按钮回调。
//  按钮回调与计时逻辑（TimerModel）的接线在阶段 8 完成。
//

import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    /// 全局唯一实例。UNUserNotificationCenter 的 delegate 是弱引用，
    /// 用单例保证它一直存活（否则点通知按钮后回调无人接收）。
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    // MARK: - 注册（在 App.init 里调用，docs/TECH.md §2.6）

    /// 注册通知分类 + 设置代理。必须在 App 启动最早期调用，
    /// 否则冷启动时到达的通知按钮回调会丢失。
    func register() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // 专注结束分类：两个按钮（屏幕上最多显示 2 个）
        let focusCategory = UNNotificationCategory(
            identifier: NotificationID.categoryFocusEnd,
            actions: [
                UNNotificationAction(identifier: NotificationID.actionStartRest, title: "开始休息"),
                UNNotificationAction(identifier: NotificationID.actionSkipRest, title: "跳过休息"),
            ],
            intentIdentifiers: [],
            options: []
        )

        // 休息结束分类：一个按钮
        let restCategory = UNNotificationCategory(
            identifier: NotificationID.categoryRestEnd,
            actions: [
                UNNotificationAction(identifier: NotificationID.actionStartFocus, title: "开始专注"),
            ],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([focusCategory, restCategory])
    }

    // MARK: - 权限

    /// 申请通知权限。整个生命周期只弹一次框（docs/TECH.md §5）。
    /// 用户拒绝也不影响计时功能，只是阶段结束提醒会缺失。
    func requestPermissionIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: StorageKeys.didRequestNotificationPermission) else {
            return
        }
        defaults.set(true, forKey: StorageKeys.didRequestNotificationPermission)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // 结果不阻塞流程；后续可在此提示用户去系统设置开启
        }
    }

    // MARK: - 排期 / 取消

    /// 排期「专注完成」通知（正文里 X = 计划分钟数）
    /// - Parameters:
    ///   - seconds: 距现在的秒数（调用方保证 ≥ 60，系统通知最短间隔约 60 秒）
    ///   - plannedFocusMinutes: 这一轮专注的计划分钟数（写进通知正文）
    func scheduleFocusEnd(after seconds: TimeInterval, plannedFocusMinutes: Int) {
        let content = makeContent(category: NotificationID.categoryFocusEnd)
        content.title = "专注完成"
        content.body = "已完成 \(plannedFocusMinutes) 分钟专注，休息一下吧。"
        schedule(content, after: seconds, identifier: NotificationID.focusEnd)
    }

    /// 排期「休息结束」通知
    /// - Parameter seconds: 距现在的秒数（调用方保证 ≥ 60）
    func scheduleRestEnd(after seconds: TimeInterval) {
        let content = makeContent(category: NotificationID.categoryRestEnd)
        content.title = "休息结束"
        content.body = "休息好了吗？开始下一轮专注吧。"
        schedule(content, after: seconds, identifier: NotificationID.restEnd)
    }

    /// 取消全部待发 + 已展示的阶段通知（暂停/取消/换阶段时调用）
    func cancelPhaseNotifications() {
        let ids = [NotificationID.focusEnd, NotificationID.restEnd]
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    // MARK: - 私有：内容与排期

    private func makeContent(category: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = category
        content.sound = .default
        // 时间敏感：会绕过手表专注模式，确保提醒送达
        content.interruptionLevel = .timeSensitive
        return content
    }

    private func schedule(_ content: UNNotificationContent, after seconds: TimeInterval, identifier: String) {
        // 通知请求 ID 固定（docs/TECH.md §4），同时最多一个待发通知，取消简单
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 代理回调（按钮接线在阶段 8 完成）

    /// App 在前台时也显示带按钮的横幅（docs/TECH.md §4）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// 用户点了通知按钮 / 点通知本体 / 划掉通知（docs/TECH.md §4 didReceive 分支）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 注意：回调在后台队列执行，阶段 8 接入 TimerModel 时需切回主线程
        let action = response.actionIdentifier

        switch action {
        case NotificationID.actionStartRest:
            // TODO(阶段 8)：补记统计 → 进入休息 → 排期休息结束通知
            break
        case NotificationID.actionSkipRest:
            // TODO(阶段 8)：补记统计 → 立即开始新一轮专注
            break
        case NotificationID.actionStartFocus:
            // TODO(阶段 8)：开始新一轮专注
            break
        default:
            // 点通知本体 / 划掉通知：仅补记同步状态，不改变阶段
            // TODO(阶段 8)：synchronize()
            break
        }

        completionHandler()
    }
}
