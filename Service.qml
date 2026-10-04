import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  readonly property string helperPath: Qt.resolvedUrl("scripts/omarchy-calendar-sync").toString().replace(/^file:\/\//, "")

  function syncCalendars() {
    if (!syncProcess.running) {
      syncProcess.running = true
    }
  }

  function checkNotifications() {
    if (!notifyProcess.running) {
      notifyProcess.running = true
    }
  }

  Process {
    id: initProcess
    command: [root.helperPath, "--init"]
  }

  Process {
    id: syncProcess
    command: [root.helperPath, "--sync"]
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.checkNotifications()
      }
    }
  }

  Process {
    id: notifyProcess
    command: [root.helperPath, "--check-notify"]
  }

  // 1. 开机/插件加载后，自举初始化配置并执行首次同步
  Timer {
    id: initialBootTimer
    interval: 3000
    running: true
    repeat: false
    onTriggered: {
      initProcess.running = true
      root.syncCalendars()
    }
  }

  // 2. 日历数据定时同步周期 (默认每 15 分钟拉取一次最新在线 ics)
  Timer {
    id: syncTimer
    interval: 15 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.syncCalendars()
  }

  // 3. 到期提醒检查周期 (每 30 秒检查一次是否达到 15 分钟前或日程开始时刻)
  Timer {
    id: notifyTimer
    interval: 30 * 1000
    running: true
    repeat: true
    onTriggered: root.checkNotifications()
  }

  IpcHandler {
    target: "agenda"

    function sync(): string {
      root.syncCalendars()
      return "syncing"
    }

    function check(): string {
      root.checkNotifications()
      return "checking"
    }
  }
}
