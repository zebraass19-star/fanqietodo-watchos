//
//  TimerView.swift
//  番茄钟
//
//  第一页 · 计时器（docs/DESIGN.md §4.2）。
//  每秒由 TimelineView 驱动 TimerModel.tick()（补记 + 刷新显示）。
//  倒计时不依赖内存 Timer，App 挂起/重启后仍正确（docs/TECH.md §1）。
//

import SwiftUI

struct TimerView: View {

    @ObservedObject private var model = TimerModel.shared
    /// 设置项回显（待机副标题用；@AppStorage 会在设置页修改后自动刷新）
    @AppStorage(StorageKeys.focusMinutes) private var focusMinutes = 25
    @AppStorage(StorageKeys.restMinutes) private var restMinutes = 5

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 2) {
                // 阶段标签（专注=主色，休息=白，暂停/待机=三级灰，docs/DESIGN.md §3）
                Text(phaseLabel.text)
                    .font(Theme.phaseLabelFont)
                    .foregroundStyle(phaseLabel.color)

                // 圆环 + 内嵌剩余时间
                ZStack {
                    ProgressRing(progress: model.progress, dimmed: isPaused)
                    Text(timeString)
                        .font(Theme.countdownFont)
                        .foregroundStyle(countdownColor)
                        .contentTransition(.numericText(value: Double(model.remainingSeconds)))
                        .animation(.linear(duration: 1), value: model.remainingSeconds)
                }
                .frame(width: 104, height: 104)

                // 各状态按钮（docs/DESIGN.md §4.2）
                controls
            }
            .onAppear { model.tick() }
            .onChange(of: context.date) { model.tick() }
        }
    }

    // MARK: - 显示辅助

    private var timeString: String {
        let s = model.remainingSeconds
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private var isPaused: Bool {
        model.phase == .focusPaused || model.phase == .restPaused
    }

    private var countdownColor: Color {
        switch model.phase {
        case .focus, .rest, .idle: return Theme.textPrimary
        // 暂停/完成态：数字退为次要色，页面焦点让给状态与按钮
        default: return Theme.textSecondary
        }
    }

    private var phaseLabel: (text: String, color: Color) {
        switch model.phase {
        case .idle:        return ("专注", Theme.textTertiary)
        case .focus:       return ("专注", Theme.orange)
        case .focusPaused: return ("已暂停", Theme.textTertiary)
        case .focusDone:   return ("专注完成", Theme.orange)
        case .rest:        return ("休息", Theme.textPrimary)
        case .restPaused:  return ("已暂停", Theme.textTertiary)
        case .restDone:    return ("休息结束", Theme.textPrimary)
        }
    }

    // MARK: - 各状态按钮

    @ViewBuilder
    private var controls: some View {
        switch model.phase {
        case .idle:
            VStack(spacing: 2) {
                Text("专注 \(focusMinutes) 分钟 · 休息 \(restMinutes) 分钟")
                    .font(Theme.idleSubtitleFont)
                    .foregroundStyle(Theme.textTertiary)
                CircleButton(title: "开始", size: 52, filled: true) { model.startFocus() }
            }
        case .focus, .rest:
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", size: 44, filled: false) { model.cancel() }
                CircleButton(symbol: "pause.fill", size: 52, filled: true) { model.pause() }
            }
        case .focusPaused, .restPaused:
            HStack(spacing: 12) {
                CircleButton(symbol: "xmark", size: 44, filled: false) { model.cancel() }
                CircleButton(symbol: "play.fill", size: 52, filled: true) { model.resume() }
            }
        case .focusDone:
            HStack(spacing: 8) {
                CapsuleButton("开始休息", filled: true) { model.startRest() }
                CapsuleButton("跳过休息", filled: false) { model.startFocus() }
            }
        case .restDone:
            HStack(spacing: 8) {
                CapsuleButton("开始专注", filled: true) { model.startFocus() }
                CapsuleButton("结束", filled: false) { model.finish() }
            }
        }
    }
}

// MARK: - 圆环（docs/DESIGN.md §4.2：104pt、线宽 8、圆头、从满环收窄）

private struct ProgressRing: View {
    /// 剩余比例 0~1（待机/完成态为满环）
    let progress: Double
    /// 暂停时整体 40% 透明度
    let dimmed: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.ringTrack, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
        .opacity(dimmed ? 0.4 : 1)
    }
}

// MARK: - 圆形按钮（橙底实心 / 灰底次要，docs/DESIGN.md §2 色板）

private struct CircleButton: View {
    var title: String? = nil
    var symbol: String? = nil
    let size: CGFloat
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let title {
                    Text(title)
                        .font(.system(size: 19, weight: .semibold))
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.42, weight: .semibold))
                }
            }
            .foregroundStyle(filled ? Theme.background : Theme.textPrimary)
            .frame(width: size, height: size)
            .background(Circle().fill(filled ? Theme.orange : Theme.secondaryButton))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 胶囊按钮（完成态的「开始休息 / 跳过休息」等）

private struct CapsuleButton: View {
    let title: String
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(filled ? Theme.background : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Capsule().fill(filled ? Theme.orange : Theme.secondaryButton))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TimerView()
        .preferredColorScheme(.dark)
}
