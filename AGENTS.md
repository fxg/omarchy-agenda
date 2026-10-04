# Omarchy Agenda (fxg.agenda) — Agent & Developer Architecture Guidelines

本规范文档（`AGENTS.md`）定义了 `omarchy-agenda` 插件的核心设计哲学、日历解析规范与代码演进准则。
任何 AI Agent 或开发人员在接手、维护或扩展此插件代码时，**必须严格遵循以下原则**。

---

## 🏛️ 核心设计哲学与架构红线

### 1. 零系统侵入与环境自洽原则 (Zero-Intrusion & Self-Contained)
- **严禁修改系统底层**：
  - 严禁任何试图修改、覆盖或依赖 `/usr/share/omarchy/` 官方系统底座代码的逻辑。
  - 所有待办看板渲染、日历拉取、通知派发逻辑，必须 100% 封装在插件自有代码目录内。
- **严禁绝对路径硬编码**：
  - 严禁在 QML 或脚本中硬编码任何特定用户的本地路径（如 `/home/xxx/`）。
  - CLI 脚本执行路径优先通过 `Qt.resolvedUrl("scripts/omarchy-calendar-sync")` 相对动态获取，回退至全局 PATH。
  - 用户配置路径统一采用 `Quickshell.env("HOME") + "/.config/omarchy/calendars.json"`。
- **全套自包含打包**：
  - 核心解析引擎自包含在 `scripts/` 目录下，确保任意新环境执行 `omarchy plugin add` 即可开箱即用。

---

### 2. 零外部 pip 依赖与标准 RFC 5545 解析准则 (Pure Stdlib & Robust Parsing)
- **纯 Python 标准库实现**：
  - `omarchy-calendar-sync` 核心解析引擎**严禁引入第三方 pip 外部库**（如 `requests`, `icalendar`, `dateutil` 等）。
  - 必须纯粹使用 Python 3 标准库（`urllib.request`, `datetime`, `zoneinfo`, `re`, `json` 等），防止因系统全局环境变化或 PEP 668 外部管理导致依赖断裂。
- **RFC 5545 健壮性保障**：
  - 严格支持多行折叠/展开（Unfolding，处理空格/Tab开头折行）；
  - 智能识别 `VALUE=DATE` 与 `VALUE=DATE-TIME`，正确处理 UTC `Z` 标识与 `TZID` 本地时区映射；
  - 针对 `RRULE` 循环事件，采用历史快进（Fast-Forward）算法，仅在当前前后 30 天滑动窗口内展开，杜绝无限死循环与内存泄漏。

---

### 3. 原生生命周期驱动与双模守护架构 (Dual-Mode Daemon Architecture)
- **桌面原生服务主导 (`Service.qml`)**：
  - 插件声明 `service` 类型的 entryPoint，由 Omarchy Shell 原生生命周期托管；
  - 开机 3 秒延迟自举初始化配置、每 15 分钟触发一次增量同步、每 30 秒触发一次到期提醒检查，**实现无需配置 systemd 的一键即用体验**。
- **独立 systemd 用户服务兼容**：
  - 随包提供 `systemd/omarchy-calendar-sync.service`，满足偏好独立守护进程的高级用户；
  - 两者均基于相同的缓存协议（`~/.cache/omarchy/calendar_events.json`）与去重标记（`calendar_notified.json`），互不冲突。

---

### 4. 智能通知防打扰与看板人机交互准则 (Non-intrusive & Clean UX)
- **精准提醒与免打扰红线**：
  - **全天日程与跨多天节日严格静默**，绝不在深夜零点弹出分秒级提醒骚扰用户；
  - 仅对明确含有时间段的事件触发两次通知：**提前 15 分钟**与**开始时刻**；
  - 严禁重复弹窗（通过 48 小时增量 ID 缓存去重）。
- **看板视觉与周期折叠规范**：
  - 「未来安排 (Upcoming)」默认聚焦最近 **7 天**日程，当月度有更多待办时提供 **30 天展开/收起切换**，保持看板尺寸适中；
  - 国庆等跨多天全天日程持续期间全程常驻在「今天」板块，避免单日后提前消失。

---

### 5. 质量保证与发布合规 (Validation & Conventional Commits)
- **本地严格校验红线**：
  - 任何改动提交前，必须在本地运行并通过官方规范校验：
    ```bash
    omarchy plugin validate .
    ```
- **提交与推送**：
  - Git 提交严格遵循 Conventional Commits 规范（`feat:`、`fix:`、`refactor:` 等）；
  - 远程提交必须使用 SSH 协议（`git@github.com:...`）。
