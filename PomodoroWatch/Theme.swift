//
//  Theme.swift
//  番茄钟
//
//  全局样式与常量总表（docs/TECH.md §6：所有魔法值集中在此，禁止散落）。
//  颜色/字号对照 docs/DESIGN.md，存储键对照 docs/TECH.md §5，
//  通知 ID 对照 docs/TECH.md §4。
//

import SwiftUI
import WatchKit

// MARK: - 颜色（docs/DESIGN.md §2 唯一色板）

enum Theme {
    /// 主色：Apple Watch Ultra 橙 #FF6000
    static let orange = Color(red: 1.0, green: 96.0 / 255.0, blue: 0.0)
    /// 全局背景：纯黑
    static let background = Color.black
    /// 文本主色：白（大数字、标题）
    static let textPrimary = Color.white
    /// 文本次级：白 50%（副信息）
    static let textSecondary = Color.white.opacity(0.5)
    /// 文本三级：白 35%（提示性小字）
    static let textTertiary = Color.white.opacity(0.35)
    /// 圆环轨道：白 12%（进度环底色）
    static let ringTrack = Color.white.opacity(0.12)
    /// 往日柱：主色 40%（图表非今日柱）
    static let pastBar = Color(red: 1.0, green: 96.0 / 255.0, blue: 0.0).opacity(0.4)
    /// 次要按钮底：白 15%（取消等次要圆形按钮）
    static let secondaryButton = Color.white.opacity(0.15)
}

// MARK: - 字号（docs/DESIGN.md §3）

extension Theme {
    /// 倒计时大数字：48pt semibold，等宽数字（一秒一跳不抖动）
    static let countdownFont = Font.system(size: 48, weight: .semibold).monospacedDigit()
    /// 阶段标签：16pt semibold
    static let phaseLabelFont = Font.system(size: 16, weight: .semibold)
    /// 页面标题：17pt semibold
    static let pageTitleFont = Font.system(size: 17, weight: .semibold)
    /// 今日分钟数：28pt semibold
    static let todayMinutesFont = Font.system(size: 28, weight: .semibold)
    /// 图表轴标签：10pt
    static let axisLabelFont = Font.system(size: 10)
    /// 待机页副标题（时长回显）：13pt
    static let idleSubtitleFont = Font.system(size: 13)
}

// MARK: - UserDefaults 键（docs/TECH.md §5，唯一标准）

enum StorageKeys {
    /// 当前阶段 rawValue
    static let phase = "phase"
    /// 当前阶段结束时刻（秒；暂停/完成/空闲时无效）
    static let phaseEndDate = "phaseEndDate"
    /// 进行中专注的开始时刻（秒）
    static let focusStartDate = "focusStartDate"
    /// 进行中专注的幂等标识
    static let sessionUUID = "sessionUUID"
    /// 该会话是否已计入统计
    static let sessionCounted = "sessionCounted"
    /// 暂停时剩余秒数
    static let pausedRemaining = "pausedRemaining"
    /// 进行中专注的计划时长（秒；统计用，暂停不改变）
    static let plannedFocusSeconds = "plannedFocusSeconds"
    /// 设置项：专注时长（分钟）
    static let focusMinutes = "focusMinutes"
    /// 设置项：休息时长（分钟）
    static let restMinutes = "restMinutes"
    /// 统计：`"yyyy-MM-dd"`（本地时区）→ 分钟数
    static let dailyFocusMinutes = "dailyFocusMinutes"
    /// 是否已申请过通知权限（避免重复弹框）
    static let didRequestNotificationPermission = "didRequestNotificationPermission"
}

// MARK: - 通知 ID（docs/TECH.md §4，唯一标准）

enum NotificationID {
    /// 通知请求 ID（同时最多一个待发通知，取消简单）
    static let focusEnd = "focusEnd"
    static let restEnd = "restEnd"

    /// 通知分类 ID
    static let categoryFocusEnd = "FOCUS_END"
    static let categoryRestEnd = "REST_END"

    /// 通知按钮 action ID
    static let actionStartRest = "START_REST"
    static let actionSkipRest = "SKIP_REST"
    static let actionStartFocus = "START_FOCUS"

    /// 调试启动参数：`-pomodoro-test <秒数>`（≥60），压短阶段时长快速走通循环
    static let testArgument = "-pomodoro-test"
}

// MARK: - 触感反馈（docs/DESIGN.md §5）

extension Theme {
    /// 播放系统触感：开始/继续 .start、暂停/取消 .stop、阶段完成 .success
    static func haptic(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}
