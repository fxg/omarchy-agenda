# Omarchy Agenda (待办日程看板)

[![Omarchy Plugin](https://img.shields.io/badge/Omarchy-Shell%20Plugin-58a6ff?style=flat-square&logo=archlinux)](https://github.com/basecamp/omarchy)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-blue?style=flat-square&logo=python)](https://python.org)

专为 **Omarchy Desktop** 打造的高颜值、原生质感在线日历与待办日程看板插件（Google Calendar & ics 订阅同步）。

集成在顶栏居中时钟旁，提供磨砂玻璃看板展示、全天及跨天日程智能折叠、提前 15 分钟桌面卡片通知与后台自动静默同步。

---

## ✨ 核心特性

- 📅 **原生精致看板**：磨砂半透明毛玻璃质感，与 Omarchy 整体主题动态契合，按时间轴清晰聚合「今天 (Today)」、「明天 (Tomorrow)」及「未来安排 (Upcoming)」。
- 🔄 **开箱即用后台服务**：基于 Omarchy 原生 `Service.qml` 驱动周期性拉取（每 15 分钟）与提醒判定，无需手动繁琐配置服务即可即装即用。
- 🔔 **精致桌面通知**：日程开始前 15 分钟及开始时刻，自动通过 Omarchy 原生桌面通知通道弹出圆角提醒卡片（附带倒计时与地点），全天事件自动静默免打扰。
- 🗓️ **智能周期与跨天日程**：
  - 「未来安排」默认聚焦最近 **7 天**，超过时支持一键展开/折叠 **未来 30 天**。
  - 智能支持国庆黄金周等多天跨天日程，持续期间全程常驻在「今天」板块。
- 🌐 **多源日历聚合**：无缝支持 Google Calendar、滴答清单 (TickTick)、Outlook、Apple iCloud 以及各种公开 iCal (.ics) 日历订阅源。
- ⚡ **纯标准库实现**：核心解析引擎纯 Python 实现，零额外第三方 pip 依赖，极速解析 RFC 5545 格式。

---

## 🚀 安装与启用

### 方式一：标准 Omarchy 插件安装（推荐）

直接在终端执行 Omarchy 标准插件安装命令：

```bash
omarchy plugin add https://github.com/fxg/omarchy-agenda.git --enable
```

> [!TIP]
> 推荐将其放置于居中时钟 `omarchy.clock` 右侧：
> ```bash
> omarchy bar move fxg.agenda --after omarchy.clock
> ```

### 方式二：克隆并本地链接

```bash
git clone https://github.com/fxg/omarchy-agenda.git ~/.config/omarchy/plugins/fxg.agenda
omarchy plugin enable fxg.agenda
```

若需要在命令行中全局使用 `omarchy-calendar-sync` 命令，可运行自带的链接脚本：
```bash
~/.config/omarchy/plugins/fxg.agenda/install.sh
```

---

## ⚙️ 日历源配置

配置文件默认位于：`~/.config/omarchy/calendars.json`

首次运行或点击看板右上角的 **⚙️ 齿轮图标** 将自动生成初始模版：

```json
[
  {
    "name": "Google",
    "url": "https://calendar.google.com/calendar/ical/YOUR_ACCOUNT%40gmail.com/private-xxxxxxxxxxxxxxxx/basic.ics",
    "color": "#4285F4",
    "enabled": true
  },
  {
    "name": "节假日",
    "url": "https://calendar.google.com/calendar/ical/zh.china%23holiday%40group.v.calendar.google.com/public/basic.ics",
    "color": "#EA4335",
    "enabled": true
  },
  {
    "name": "工作待办",
    "url": "https://dida365.com/pub/calendar/feeds/xxxxxx/basic.ics",
    "color": "#34A853",
    "enabled": false
  }
]
```

### 字段说明

| 字段 | 说明 | 示例 |
| :--- | :--- | :--- |
| `name` | 日历标签名称（显示在卡片右侧） | `"个人日历"`, `"工作"` |
| `url` | 在线 `.ics` 订阅地址（私密地址） | `https://.../basic.ics` |
| `color` | 左侧指示条高亮颜色（十六进制色值） | `"#4285F4"` |
| `enabled` | 是否启用该日历源同步 | `true` / `false` |

---

## 📖 获取 Google 日历私密 ics 链接教程

1. 打开浏览器登录访问 [Google 日历网页版 (calendar.google.com)](https://calendar.google.com/)。
2. 点击右上角 **齿轮图标 ->「设置 (Settings)」**。
3. 在左侧侧边栏中找到 **「我的日历的设置 (Settings for my calendars)」**，点击你想同步的主日历。
4. 向下滚动页面，找到 **「整合日历 (Integrate calendar)」** 板块。
5. 复制 **「iCal 格式的私密地址 (Secret address in iCal format)」**：
   ```text
   https://calendar.google.com/calendar/ical/你的邮箱%40gmail.com/private-xxxxxxxxxxxxxxxx/basic.ics
   ```
6. 将该 URL 粘贴到 `~/.config/omarchy/calendars.json` 的 `url` 字段中即可。

> [!CAUTION]
> 请注意复制的是 **“私密地址”**，而不是网页浏览链接（网页链接会返回 HTML 导致无法解析）。

---

## 🖱️ 交互与快捷操作

### 顶栏图标 (`󰃭`)
- **鼠标左键**：展开 / 收起「待办日程看板」。
- **鼠标右键**：立即触发一次静默日历同步。
- **鼠标中键**：在默认浏览器中直接打开 Google Calendar 网页版。

### 看板窗口内部
- **󰑐 刷新按钮**：手动强制拉取所有在线日历。
- **󰅟 网页图标**：快速直达 Google Calendar 网页端。
- **󰒓 齿轮图标**：一键调用系统默认编辑器打开 `calendars.json` 配置文件。
- **查看更多 / 收起**：若未来 8~30 天有日程安排，底部提供一键展开/收起切换。

---

## 🛠️ CLI 调试与状态检查

若安装了命令行链接（或直接运行脚本）：

```bash
# 查看当前已同步的日程及状态
omarchy-calendar-sync --status

# 立即执行一次同步拉取
omarchy-calendar-sync --sync

# 检查当前待触发的日程提醒通知
omarchy-calendar-sync --check-notify
```

---

## 🗑️ 卸载

```bash
omarchy plugin disable fxg.agenda
omarchy plugin remove fxg.agenda
```

---

## 📄 License

本项目基于 [MIT License](LICENSE) 开源发布。
