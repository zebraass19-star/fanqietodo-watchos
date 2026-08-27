# 待办事项（TODO）

> 跨日持续的任务清单。每日动态记在各天的日志文件里，长期待办在这里维护。
> 推进规则：**一次只推进一个阶段**，完成并通过验收（编译/CI 绿/用户确认）后再进入下一阶段。

## 进行中
- [ ] 阶段 6：StatisticsStore 扩展 + StatsView（近 7 天柱状图，Swift Charts）——代码与评审完成，待 CI 验收

## 已验收
- [x] 阶段 0：需求确认与方案评审（产出 docs/ 四份标准文档）
- [x] 阶段 1：Xcode 工程骨架 —— 文件、git 推送、GitHub Actions 云编译全部通过 ✅
- [x] 阶段 2：App 入口 + 主题 + 占位界面（CI 绿 ✅）
- [x] 阶段 3：通知模块 NotificationManager（评审通过 + CI 绿 ✅）
- [x] 阶段 4：状态机 TimerModel + StatisticsStore 最小版（13 项逻辑评审通过 + CI 绿 ✅）
- [x] 阶段 5：TimerView + ContentView（10 项设计评审通过 + CI 绿 ✅；期间加了 CI 错误注释提取机制，远程排错不用翻日志）

## 后续阶段（一次只做一个）
- [ ] 阶段 2：App 入口 + 主题 + 占位界面
- [ ] 阶段 3：NotificationManager（通知分类/权限/排期/回调）
- [ ] 阶段 4：TimerModel 状态机（核心逻辑）
- [ ] 阶段 5：TimerView + ContentView（倒计时 UI、分页）
- [ ] 阶段 6：StatisticsStore + StatsView（统计与图表）
- [ ] 阶段 7：SettingsView（时长设置）
- [ ] 阶段 8：通知回调接线 + 打磨 + 中文 README
- [ ] 阶段 9：设备验证（模拟器 + 真机，需要 Mac 时进行）
