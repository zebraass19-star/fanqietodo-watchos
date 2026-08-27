//
//  TimerModel.swift
//  番茄钟
//
//  状态机「大脑」（docs/TECH.md §3/§4/§5 为唯一标准）。
//  7 态：idle → focus → focusPaused → focusDone → rest → restPaused → restDone
//  所有状态写穿持久化到 UserDefaults，App 挂起/重启后可完整重建。
//  倒计时不依赖内存 Timer：从存储的 phaseEndDate 实时推算（watchOS 后台限制）。
//

import Foundation
import SwiftUI

/// 7 种阶段状态（docs/TECH.md §3）
enum PomodoroPhase: String {
    case idle
    case focus
    case focusPaused
    case focusDone
    case rest
    case restPaused
    case restDone
}

final class TimerModel: ObservableObject {

    static let shared = TimerModel()

    // MARK: - 对外状态（View 只读，不直接改）

    @Published private(set) var phase: PomodoroPhase = .idle
    /// 剩余秒数（供界面显示）
    @Published private(set) var remainingSeconds: Int = 0
    /// 圆环进度 0~1（剩余比例；待机/完成态为满环）
    @Published private(set) var progress: Double = 1.0

    // MARK: - 内部状态（与 UserDefaults 键一一对应，docs/TECH.md §5）

    private var phaseEndDate: TimeInterval = 0
    private var focusStartDate: TimeInterval = 0
    private var sessionUUID: String?
    private var sessionCounted = false
    private var pausedRemaining: TimeInterval = 0
    private var plannedFocusSeconds: TimeInterval = 0

    /// 调试钩子压短的阶段时长（docs/TECH.md §8），nil = 用设置值
    private var testOverrideSeconds: TimeInterval?

    // MARK: - 初始化（启动时重建现场）

    private init() {
        let d = UserDefaults.standard
        phase = PomodoroPhase(rawValue: d.string(forKey: StorageKeys.phase) ?? "") ?? .idle
        phaseEndDate = d.double(forKey: StorageKeys.phaseEndDate)
        focusStartDate = d.double(forKey: StorageKeys.focusStartDate)
        sessionUUID = d.string(forKey: StorageKeys.sessionUUID)
        sessionCounted = d.bool(forKey: StorageKeys.sessionCounted)
        pausedRemaining = d.double(forKey: StorageKeys.pausedRemaining)
        plannedFocusSeconds = d.double(forKey: StorageKeys.plannedFocusSeconds)

        parseTestHook()
        refreshDisplay()
        // 启动即补记：若上次专注在 App 未运行期间到期，立即结算
        synchronize()
    }

    // MARK: - 操作（按钮/通知回调都会调用这些方法；需在主线程调用）

    /// 开始一轮新专注。入口：待机「开始」、专注完成后「跳过休息」、休息完成后「开始专注」
    func startFocus() {
        guard phase == .idle || phase == .focusDone || phase == .restDone else { return }

        let now = Date().timeIntervalSince1970
        plannedFocusSeconds = effectiveFocusSeconds
        focusStartDate = now
        sessionUUID = UUID().uuidString
        sessionCounted = false
        pausedRemaining = 0
        phaseEndDate = now + plannedFocusSeconds
        phase = .focus

        NotificationManager.shared.scheduleFocusEnd(
            after: plannedFocusSeconds,
            plannedFocusMinutes: Int(plannedFocusSeconds / 60)
        )
        Theme.haptic(.start)
        persist()
        refreshDisplay()
    }

    /// 开始休息。入口：专注完成后「开始休息」
    func startRest() {
        guard phase == .focusDone else { return }

        let now = Date().timeIntervalSince1970
        phaseEndDate = now + effectiveRestSeconds
        pausedRemaining = 0
        phase = .rest

        NotificationManager.shared.scheduleRestEnd(after: effectiveRestSeconds)
        Theme.haptic(.start)
        persist()
        refreshDisplay()
    }

    /// 暂停（专注/休息中）。撤掉待发通知，保存剩余秒数
    func pause() {
        guard phase == .focus || phase == .rest else { return }

        let now = Date().timeIntervalSince1970
        pausedRemaining = max(0, phaseEndDate - now)
        phaseEndDate = 0
        phase = (phase == .focus) ? .focusPaused : .restPaused

        NotificationManager.shared.cancelPhaseNotifications()
        Theme.haptic(.stop)
        persist()
        refreshDisplay()
    }

    /// 继续（已暂停）。以剩余秒数重新排期通知
    func resume() {
        guard phase == .focusPaused || phase == .restPaused else { return }

        let now = Date().timeIntervalSince1970
        phaseEndDate = now + pausedRemaining
        let remaining = pausedRemaining
        pausedRemaining = 0
        phase = (phase == .focusPaused) ? .focus : .rest

        if phase == .focus {
            NotificationManager.shared.scheduleFocusEnd(
                after: remaining,
                plannedFocusMinutes: Int(plannedFocusSeconds / 60)
            )
        } else {
            NotificationManager.shared.scheduleRestEnd(after: remaining)
        }
        Theme.haptic(.start)
        persist()
        refreshDisplay()
    }

    /// 取消（任何非待机状态）。清空会话，不计统计
    func cancel() {
        guard phase != .idle else { return }
        clearSession(toIdle: true)
        NotificationManager.shared.cancelPhaseNotifications()
        Theme.haptic(.stop)
        persist()
        refreshDisplay()
    }

    /// 结束（休息完成后「结束」按钮）。回到待机
    func finish() {
        guard phase == .restDone else { return }
        clearSession(toIdle: true)
        NotificationManager.shared.cancelPhaseNotifications()
        Theme.haptic(.stop)
        persist()
        refreshDisplay()
    }

    // MARK: - 补记与心跳（docs/TECH.md §4 补记规则）

    /// 补记同步：专注/休息时间到而未结算时，把状态推进到「完成待确认」。
    /// 幂等：sessionCounted 保证统计只记一次。
    /// 运行时机：启动、回到前台、任何通知回调、每 tick。
    func synchronize() {
        let now = Date().timeIntervalSince1970
        switch phase {
        case .focus:
            guard now >= phaseEndDate else { return }
            if !sessionCounted {
                StatisticsStore.shared.record(
                    minutes: Int(plannedFocusSeconds / 60),
                    at: Date()
                )
                sessionCounted = true
            }
            phase = .focusDone
            Theme.haptic(.success)
            persist()
            refreshDisplay()
        case .rest:
            guard now >= phaseEndDate else { return }
            phase = .restDone
            persist()
            refreshDisplay()
        default:
            break
        }
    }

    /// 每秒心跳：先补记（幂等，开销极小），再刷新显示。
    /// 由界面的 TimelineView(.periodic(by:1)) 驱动（阶段 5 接线）。
    func tick() {
        synchronize()
        refreshDisplay()
    }

    // MARK: - 持久化（写穿：每次状态变更立即写 UserDefaults）

    private func persist() {
        let d = UserDefaults.standard
        d.set(phase.rawValue, forKey: StorageKeys.phase)
        d.set(phaseEndDate, forKey: StorageKeys.phaseEndDate)
        d.set(focusStartDate, forKey: StorageKeys.focusStartDate)
        d.set(sessionCounted, forKey: StorageKeys.sessionCounted)
        d.set(pausedRemaining, forKey: StorageKeys.pausedRemaining)
        d.set(plannedFocusSeconds, forKey: StorageKeys.plannedFocusSeconds)
        if let uuid = sessionUUID {
            d.set(uuid, forKey: StorageKeys.sessionUUID)
        } else {
            d.removeObject(forKey: StorageKeys.sessionUUID)
        }
    }

    /// 清空会话级状态（取消/结束时调用）
    private func clearSession(toIdle: Bool) {
        phase = toIdle ? .idle : phase
        phaseEndDate = 0
        focusStartDate = 0
        sessionUUID = nil
        sessionCounted = false
        pausedRemaining = 0
        plannedFocusSeconds = 0
    }

    // MARK: - 显示刷新（倒计时从 phaseEndDate 推算，docs/TECH.md §1）

    private func refreshDisplay() {
        let now = Date().timeIntervalSince1970
        switch phase {
        case .focus:
            let remaining = max(0, phaseEndDate - now)
            remainingSeconds = Int(ceil(remaining))
            progress = plannedFocusSeconds > 0 ? min(1, remaining / plannedFocusSeconds) : 0
        case .rest:
            let remaining = max(0, phaseEndDate - now)
            remainingSeconds = Int(ceil(remaining))
            let total = effectiveRestSeconds
            progress = total > 0 ? min(1, remaining / total) : 0
        case .focusPaused:
            remainingSeconds = Int(ceil(pausedRemaining))
            progress = plannedFocusSeconds > 0 ? min(1, pausedRemaining / plannedFocusSeconds) : 0
        case .restPaused:
            remainingSeconds = Int(ceil(pausedRemaining))
            let total = effectiveRestSeconds
            progress = total > 0 ? min(1, pausedRemaining / total) : 0
        case .idle:
            // 待机：满环 + 显示即将开始的专注时长
            remainingSeconds = Int(effectiveFocusSeconds)
            progress = 1.0
        case .focusDone, .restDone:
            // 完成态为满环（docs/DESIGN.md §4.2）
            remainingSeconds = 0
            progress = 1.0
        }
    }

    // MARK: - 时长计算（设置项 + 调试钩子）

    /// 本轮专注计划秒数：优先调试钩子，否则用设置项（默认 25 分钟）
    private var effectiveFocusSeconds: TimeInterval {
        if let t = testOverrideSeconds { return t }
        let minutes = UserDefaults.standard.integer(forKey: StorageKeys.focusMinutes)
        return TimeInterval((minutes > 0 ? minutes : 25) * 60)
    }

    /// 本轮休息计划秒数：优先调试钩子，否则用设置项（默认 5 分钟）
    private var effectiveRestSeconds: TimeInterval {
        if let t = testOverrideSeconds { return t }
        let minutes = UserDefaults.standard.integer(forKey: StorageKeys.restMinutes)
        return TimeInterval((minutes > 0 ? minutes : 5) * 60)
    }

    /// 解析启动参数 `-pomodoro-test <秒数>`（≥60，docs/TECH.md §8）
    private func parseTestHook() {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: NotificationID.testArgument),
              index + 1 < args.count,
              let seconds = Double(args[index + 1]),
              seconds >= 60 else {
            return
        }
        testOverrideSeconds = seconds
    }
}
