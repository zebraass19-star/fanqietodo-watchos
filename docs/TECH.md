# 技术规范（Technical Standard）

> 版本 v1.0 · 本文档是代码实现的唯一技术标准。改动架构必须先更新本文档并记录到当日开发日志。

## 1. 总体架构

- 单 target、纯手表 SwiftUI App（无 iPhone 伴侣 App、无 WatchKit 扩展、无 storyboard）
- 核心两部分：
  - `TimerModel`：状态机，所有状态持久化到 UserDefaults，App 挂起/重启后可完整重建
  - `NotificationManager`：UNUserNotificationCenter 代理，预先排期阶段结束通知、处理通知按钮回调
- 倒计时显示：`TimelineView(.periodic(by:1))` 每秒从存储的 `phaseEndDate` 推算剩余时间（不依赖内存 Timer 后台运行）

## 2. 关键平台约束（已核实，勿违反）

1. watchOS App 进入后台即挂起，**不能**靠内存 Timer 计时、不能靠后台任务触发代码。
2. 阶段结束提醒 = **预先排好的本地通知**（`UNTimeIntervalNotificationTrigger`，不重复）。
3. 通知触发时不能运行代码 → 统计用「补记」机制实现（见 §4 补记规则）。
4. 用户点通知按钮 → 系统后台唤醒 App 调 `didReceive` 回调（前提：用户没有强制杀掉 App）→ 在回调里排下一阶段通知。这是整个循环的机制核心。
5. 本地通知带按钮：`UNNotificationCategory` + `UNNotificationAction`（屏幕上最多显示 2 个按钮）。
6. 通知分类与代理必须在 App 冷启动最早期注册（`App.init()` 内），否则冷启动时到达的通知回调会丢失。

## 3. 状态机（7 态，持久化）

`idle → focus → focusPaused → focusDone → rest → restPaused → restDone`

- `focusDone`/`restDone` = 阶段完成待确认态：用户回到 App 时仍能看到「专注完成 / 开始休息」等选项（与通知按钮一致），而不是直接闪回待机
- 暂停 = 取消待发通知 + 保存剩余秒数；继续 = 以剩余秒数重新排期
- 取消 = 清空会话状态，不计统计
- 状态变更即写 UserDefaults（write-through），启动时一次性读入内存

## 4. 通知设计（ID 与文案为唯一标准）

| 项 | 值 |
|---|---|
| 专注结束分类 | `FOCUS_END`：标题「专注完成」，正文「已完成 X 分钟专注，休息一下吧。」（X = 计划分钟数） |
| 专注结束按钮 | `START_REST`「开始休息」、`SKIP_REST`「跳过休息」 |
| 休息结束分类 | `REST_END`：标题「休息结束」，正文「休息好了吗？开始下一轮专注吧。」 |
| 休息结束按钮 | `START_FOCUS`「开始专注」 |
| 通知请求 ID | 固定 `"focusEnd"` / `"restEnd"`（同时最多一个待发通知，取消简单） |
| 前台展示 | `willPresent` 返回 `[.banner, .sound]`（App 在前台时也显示带按钮横幅） |
| 其他 | `interruptionLevel = .timeSensitive`；阶段完成时播放系统触感反馈 |

### 按钮回调处理（didReceive 分支）

- `START_REST`：补记统计 → 进入休息 → 排期 REST_END
- `SKIP_REST`：补记统计 → 立即开始新一轮专注
- `START_FOCUS`：开始新一轮专注
- 点通知正文（default action）/ 划掉通知：仅补记同步状态，不改变阶段
- 所有分支先走 `synchronize()` 补记，保证统计幂等、不漏不重

### 补记规则（synchronize）

- 运行时机：App 启动、回到前台、任何通知回调、倒计时每 tick（内存比较，开销极小）
- `focus` 且时间到 → 未计则把「计划分钟数」计入当天统计并置 `sessionCounted`，状态转 `focusDone`
- `rest` 且时间到 → 转 `restDone`
- 其余状态（暂停/待机/完成态）不变

## 5. 持久化键（UserDefaults，唯一标准）

| 键 | 类型 | 含义 |
|---|---|---|
| `phase` | String | 当前阶段 rawValue |
| `phaseEndDate` | Double | 当前阶段结束时刻（暂停/完成/空闲时无效） |
| `focusStartDate` | Double? | 进行中专注的开始时刻 |
| `sessionUUID` | String? | 进行中专注的幂等标识 |
| `sessionCounted` | Bool | 该会话是否已计入统计 |
| `pausedRemaining` | Double | 暂停时剩余秒数 |
| `plannedFocusSeconds` | Double | 进行中专注的计划时长（统计用，暂停不改变） |
| `focusMinutes` / `restMinutes` | Int | 设置项（@AppStorage） |
| `dailyFocusMinutes` | [String: Int] | 统计：`"yyyy-MM-dd"`（本地时区）→ 分钟数 |
| `didRequestNotificationPermission` | Bool | 避免重复弹权限框 |

## 6. 代码规范

- Swift 5.0 语言模式（`SWIFT_VERSION = 5.0`，避免 Swift 6 严格并发报错困扰初学者）
- 文件职责边界：TimerModel 只管状态与逻辑；NotificationManager 只管系统通知；StatisticsStore 只管统计读写；View 只读模型，不做业务判断
- 常量（颜色、字号、UserDefaults 键、通知 ID、分类 ID）统一放 Theme.swift，禁止散落魔法值
- 全项目 LF 换行、UTF-8 无 BOM；target/文件/目录名全 ASCII；中文只出现在 UI 字符串与 Info.plist 显示名
- 中文界面文案硬编码（v1 不做本地化文件）
- 不引入第三方依赖（纯系统框架：SwiftUI、Swift Charts、UserNotifications、WatchKit）

## 7. 工程文件（pbxproj）规范

- objectVersion 77 + `PBXFileSystemSynchronizedRootGroup` 文件夹同步组：源码/资源零逐条登记，新增文件自动进 target
- **必须**把 Info.plist 加入 membership 例外集（`PBXFileSystemSynchronizedBuildFileExceptionSet`），防止被拷贝进资源包
- 关键构建设置：
  - `TARGETED_DEVICE_FAMILY = 4`（watchOS）
  - `GENERATE_INFOPLIST_FILE = NO`（手写 Info.plist，保证 WKApplication/WKWatchOnly 键存在）
  - `SDKROOT = watchos`、`WATCHOS_DEPLOYMENT_TARGET = 11.0`
  - `DEVELOPMENT_TEAM` 留空（用户在 Xcode 界面里选免费个人团队）
  - `PRODUCT_BUNDLE_IDENTIFIER = com.example.pomodoro-watch`（用户可在 Xcode 中修改）
- Info.plist 必备键：`WKApplication = YES`、`WKWatchOnly = YES`、`CFBundleDisplayName = 番茄钟`

## 8. 测试钩子（DEBUG）

- 启动参数 `-pomodoro-test <秒数>`（≥ 60，通知最短间隔约 60 秒）：把阶段时长压短，快速走通通知循环
- DEBUG 构建设置页额外提供「1 分钟」档位（与上一条等价，操作更直观）
