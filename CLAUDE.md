# watchOS 番茄钟 — 项目工作指引

一个运行在 Apple Watch 上的番茄钟 App（纯手表应用，watchOS ≥ 11，SwiftUI，中文界面）。
项目所有者是编程零基础，用中文沟通；开发遵循**小步分阶段推进**原则。

## 工作方式（重要）

1. **一次只做一个阶段**：按 docs/ROADMAP.md 的当前阶段工作，完成并通过验收后再进入下一阶段，不要一口气做太多。
2. 写任何代码前，先读对应标准文档：
   - 功能该怎么做 → docs/REQUIREMENTS.md（需求规格）
   - 代码该怎么写 → docs/TECH.md（技术规范：状态机、通知 ID、UserDefaults 键、pbxproj 规范）
   - 界面长什么样 → docs/DESIGN.md（设计规范：色板、字号、页面规格）
   - 现在做到哪一步 → docs/ROADMAP.md（执行步骤）
3. 需求或方案有变：先更新对应 docs 文档，再改代码。
4. 与用户对话用中文，解释要通俗（对方不懂代码）；代码注释可用中文。

## 开发日志（devlog/）

- 每次会话开始时：检查 devlog/ 下是否有今天的日志（`YYYY-MM-DD.md`），没有就按 devlog/TEMPLATE.md 创建；读一下 devlog/TODO.md 了解当前待办。
- 会话结束前：把今天完成的事项、遇到的问题、下一步待办更新到今日日志和 devlog/TODO.md。
- 另有每日 21:07 的自动汇总定时任务（由 Claude Code 定时任务驱动，仅会话运行期间生效；该任务 7 天自动过期，若失效请让 Claude 重建，说一句「重建每日日志任务」即可）。

## 标准文件路径

| 文件 | 内容 |
|---|---|
| docs/REQUIREMENTS.md | 需求规格（功能清单、产品决策） |
| docs/TECH.md | 技术规范（架构、状态机、通知设计、持久化键、工程规范） |
| docs/DESIGN.md | 设计规范（色板、排版、页面规格、动效） |
| docs/ROADMAP.md | 执行步骤（分阶段计划与验收标准） |
| devlog/ | 每日开发日志（按 TEMPLATE.md 建当天文件） |
| devlog/TODO.md | 跨日待办清单 |

## 环境须知

- 开发机是 Windows，无法本地编译 watchOS；代码先在 Windows 写好，用 GitHub Actions（macOS 云机器）验证编译；最终安装需要 Mac（详见 README，阶段 8 编写）。
- 文件规范：全项目 LF 换行、UTF-8 无 BOM、文件名全 ASCII（中文只出现在 UI 文案与 Info.plist 显示名）。
- 目标设备：Ultra / Ultra 2 / Series 10 级手表，最低系统 watchOS 11.0，Xcode 26 构建。
