# 执行步骤（Roadmap）

> 推进规则：**一次只做当前阶段**，完成并通过验收（编译通过 / CI 绿 / 用户确认）后再进入下一阶段。
> 每阶段完成后更新 devlog/TODO.md 与当日开发日志。

## 阶段 0 · 需求与方案（已完成 ✅）

- 需求确认、技术可行性核实、方案评审
- 产出：docs/ 四份标准文档 + devlog/ 日志体系 + CLAUDE.md 工作指引

## 阶段 1 · 工程骨架

- 目录结构、.gitignore / .editorconfig（LF 换行）、Info.plist、Assets 清单（AppIcon / AccentColor）
- 手写 project.pbxproj（objectVersion 77 + 文件夹同步组）、共享 scheme
- tools/make_icons.py + 生成全部图标 PNG
- .github/workflows/build.yml（GitHub Actions 云编译验证）
- **验收**：推 GitHub 跑 CI，`xcodebuild build` 通过（证明 pbxproj 合法、工程可打开）

## 阶段 2 · App 入口与主题

- Theme.swift（色板 / 字体 / 常量键）、PomodoroWatchApp.swift（init 注册通知代理骨架）、占位 ContentView
- **验收**：CI 编译通过

## 阶段 3 · 通知模块

- NotificationManager：分类注册、权限申请、排期/取消、willPresent、didReceive 分支（先接桩）
- **验收**：编译通过 + 代码评审

## 阶段 4 · 状态机（核心）

- TimerModel：7 态、持久化读写、start/pause/resume/cancel/skip、synchronize 补记、调试时长钩子
- **验收**：编译通过 + 逐状态逻辑评审

## 阶段 5 · 计时器 UI 与分页

- TimerView（圆环 / 倒计时 / 各状态按钮）+ ContentView（分页 TabView + 齿轮占位）
- **验收**：编译通过 + 对照 DESIGN.md 评审

## 阶段 6 · 统计模块

- StatisticsStore + StatsView（近 7 天柱状图）
- **验收**：编译通过 + 图表规格对照评审

## 阶段 7 · 设置页

- SettingsView（时长 Picker、清除统计、DEBUG 1 分钟档）
- **验收**：编译通过

## 阶段 8 · 接线与打磨

- 通知回调接线 TimerModel、前台触感、权限拒绝提示、边界场景排查（漏点通知 / 杀 App / 重启手表）
- 中文 README.md（装 Xcode、免费签名、开发者模式、7 天过期说明、云 Mac 替代方案）
- **验收**：全量代码评审 + CI 绿

## 阶段 9 · 设备验证（需要 Mac 时进行）

- 模拟器全流程验证 → 真机安装（开发者模式、免费个人团队）→ 通知循环实测（DEBUG 1 分钟档）
- **验收**：真机走通「专注 → 通知 → 休息 → 通知」全循环
