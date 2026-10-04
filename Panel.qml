import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "fxg.agenda"
  ipcTarget: "fxg.agenda"
  manageIpc: true

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  property var eventsData: ({ "events": [], "total": 0, "lastSyncFormatted": "—", "calendars": [] })

  readonly property var todayEvents: {
    var evs = root.eventsData && root.eventsData.events ? root.eventsData.events : []
    return evs.filter(function(e) { return e.relativeDay === "today" })
  }

  readonly property var tomorrowEvents: {
    var evs = root.eventsData && root.eventsData.events ? root.eventsData.events : []
    return evs.filter(function(e) { return e.relativeDay === "tomorrow" })
  }

  property bool showAllUpcoming: false

  readonly property var upcomingEvents: {
    var evs = root.eventsData && root.eventsData.events ? root.eventsData.events : []
    return evs.filter(function(e) { return e.relativeDay === "upcoming" })
  }

  readonly property var upcomingEvents7Days: {
    return upcomingEvents.filter(function(e) {
      return (e.daysFromToday !== undefined) ? (e.daysFromToday <= 7) : true
    })
  }

  readonly property var displayedUpcomingEvents: {
    return root.showAllUpcoming ? upcomingEvents : upcomingEvents7Days
  }

  readonly property int hiddenUpcomingCount: {
    return Math.max(0, upcomingEvents.length - upcomingEvents7Days.length)
  }

  function open() {
    root.showAllUpcoming = false
    eventsFile.reload()
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  property string helperPath: Qt.resolvedUrl("scripts/omarchy-calendar-sync").toString().replace(/^file:\/\//, "")

  function triggerSync() {
    var cmd = root.helperPath || "omarchy-calendar-sync"
    Quickshell.execDetached([cmd, "--sync"])
    Qt.callLater(function() { eventsFile.reload() })
  }


  function openConfigFile() {
    var path = Quickshell.env("HOME") + "/.config/omarchy/calendars.json"
    Quickshell.execDetached(["omarchy-launch-config-editor", path])
  }

  function openWebCalendar() {
    Quickshell.execDetached(["xdg-open", "https://calendar.google.com"])
  }

  FileView {
    id: eventsFile
    path: Quickshell.env("HOME") + "/.cache/omarchy/calendar_events.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var raw = text()
        if (raw && raw.trim().length > 0) {
          root.eventsData = JSON.parse(raw)
        }
      } catch (e) {
        console.warn("fxg.agenda: parse error: " + e)
      }
    }
  }

  Timer {
    interval: 1200
    running: true
    onTriggered: eventsFile.reload()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(Math.min(Style.space(560), mainColumn.implicitHeight + Style.space(24)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: scrollArea
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: mainColumn
          width: scrollArea.width
          spacing: Style.space(12)

          // ---- Header Row ----
          Item {
            width: parent.width
            height: headerRow.implicitHeight

            RowLayout {
              id: headerRow
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(10)

              Text {
                text: "󰃭"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: 22
              }

              Column {
                Layout.fillWidth: true
                spacing: Style.space(2)

                Text {
                  text: "待办日程 (AGENDA)"
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.title
                  font.bold: true
                  color: root.contentForeground
                  font.letterSpacing: 1
                }

                Text {
                  text: (root.eventsData.total || 0) + " 个待办 · 上次同步 " + (root.eventsData.lastSyncFormatted || "刚刚")
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.caption
                  color: Qt.darker(root.contentForeground, 1.6)
                }
              }

              Row {
                spacing: Style.space(6)

                PanelActionButton {
                  iconText: "󰑐"
                  tooltipText: "立即同步"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.triggerSync()
                }

                PanelActionButton {
                  iconText: "󰅟"
                  tooltipText: "Google 日历网页版"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.openWebCalendar()
                }

                PanelActionButton {
                  iconText: "󰒓"
                  tooltipText: "配置日历订阅"
                  foreground: root.contentForeground
                  fontFamily: root.contentFontFamily
                  onClicked: root.openConfigFile()
                }
              }
            }
          }

          // Separator hairline
          Rectangle {
            width: parent.width
            height: Style.spacing.hairline
            color: root.contentForeground
            opacity: 0.12
          }

          // ---- Empty State ----
          Column {
            visible: !root.eventsData || !root.eventsData.events || root.eventsData.events.length === 0
            width: parent.width
            spacing: Style.space(10)
            topPadding: Style.space(20)
            bottomPadding: Style.space(20)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "󰃭"
              font.family: root.contentFontFamily
              font.pixelSize: 42
              color: Qt.darker(root.contentForeground, 2.0)
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "近期暂无日程安排"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.body
              color: Qt.darker(root.contentForeground, 1.4)
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "在 ~/.config/omarchy/calendars.json 添加在线 ics 链接"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              color: Qt.darker(root.contentForeground, 1.8)
            }
          }

          // ---- Section 1: TODAY (今天) ----
          Column {
            visible: root.todayEvents.length > 0
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "今天 · TODAY"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
              color: Style.selectedStateColor(root.contentForeground, Color.accent)
            }

            Repeater {
              model: root.todayEvents

              Rectangle {
                required property var modelData
                width: parent.width
                height: eventCardCol.implicitHeight + Style.space(16)
                radius: Style.cornerRadius
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.05)
                border.width: Style.spacing.hairline
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.1)

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  anchors.margins: Style.space(8)
                  width: 3
                  radius: 1.5
                  color: modelData.color || Color.accent
                }

                Column {
                  id: eventCardCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(20)
                  anchors.rightMargin: Style.space(12)
                  spacing: Style.space(3)

                  RowLayout {
                    width: parent.width

                    Text {
                      Layout.fillWidth: true
                      text: modelData.summary
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      color: root.contentForeground
                      elide: Text.ElideRight
                    }

                    Text {
                      text: modelData.calendar
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      color: Qt.darker(root.contentForeground, 1.6)
                    }
                  }

                  Row {
                    spacing: Style.space(6)

                    Text {
                      text: "󰅐 " + modelData.displayTime
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.3)
                    }

                    Text {
                      visible: modelData.location !== ""
                      text: "· 󰍎 " + modelData.location
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.5)
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }
          }

          // ---- Section 2: TOMORROW (明天) ----
          Column {
            visible: root.tomorrowEvents.length > 0
            width: parent.width
            spacing: Style.space(6)

            Text {
              text: "明天 · TOMORROW"
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1
              color: Qt.darker(root.contentForeground, 1.4)
            }

            Repeater {
              model: root.tomorrowEvents

              Rectangle {
                required property var modelData
                width: parent.width
                height: tmrwCardCol.implicitHeight + Style.space(16)
                radius: Style.cornerRadius
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.04)
                border.width: Style.spacing.hairline
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.08)

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  anchors.margins: Style.space(8)
                  width: 3
                  radius: 1.5
                  color: modelData.color || Color.accent
                }

                Column {
                  id: tmrwCardCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(20)
                  anchors.rightMargin: Style.space(12)
                  spacing: Style.space(3)

                  RowLayout {
                    width: parent.width

                    Text {
                      Layout.fillWidth: true
                      text: modelData.summary
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      color: root.contentForeground
                      elide: Text.ElideRight
                    }

                    Text {
                      text: modelData.calendar
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      color: Qt.darker(root.contentForeground, 1.6)
                    }
                  }

                  Row {
                    spacing: Style.space(6)

                    Text {
                      text: "󰅐 " + modelData.displayTime
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.3)
                    }

                    Text {
                      visible: modelData.location !== ""
                      text: "· 󰍎 " + modelData.location
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.5)
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }
          }

          // ---- Section 3: UPCOMING (未来日程) ----
          Column {
            visible: root.displayedUpcomingEvents.length > 0
            width: parent.width
            spacing: Style.space(6)

            RowLayout {
              width: parent.width

              Text {
                Layout.fillWidth: true
                text: "未来安排 · UPCOMING" + (root.showAllUpcoming ? " (未来 30 天)" : " (未来 7 天)")
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1
                color: Qt.darker(root.contentForeground, 1.4)
              }

              Text {
                text: root.displayedUpcomingEvents.length + " 项"
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                color: Qt.darker(root.contentForeground, 1.8)
              }
            }

            Repeater {
              model: root.displayedUpcomingEvents

              Rectangle {
                required property var modelData
                width: parent.width
                height: upCardCol.implicitHeight + Style.space(16)
                radius: Style.cornerRadius
                color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.03)
                border.width: Style.spacing.hairline
                border.color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.07)

                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  anchors.margins: Style.space(8)
                  width: 3
                  radius: 1.5
                  color: modelData.color || Color.accent
                }

                Column {
                  id: upCardCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(20)
                  anchors.rightMargin: Style.space(12)
                  spacing: Style.space(3)

                  RowLayout {
                    width: parent.width

                    Text {
                      Layout.fillWidth: true
                      text: modelData.summary
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      color: root.contentForeground
                      elide: Text.ElideRight
                    }

                    Text {
                      text: modelData.dateHeader || modelData.startDateStr
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.caption
                      color: Qt.darker(root.contentForeground, 1.5)
                    }
                  }

                  Row {
                    spacing: Style.space(6)

                    Text {
                      text: "󰅐 " + modelData.displayTime
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.3)
                    }

                    Text {
                      visible: modelData.location !== ""
                      text: "· 󰍎 " + modelData.location
                      font.family: root.contentFontFamily
                      font.pixelSize: Style.font.bodySmall
                      color: Qt.darker(root.contentForeground, 1.5)
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }

            // More / Collapse button
            Button {
              visible: root.hiddenUpcomingCount > 0 || root.showAllUpcoming
              width: parent.width
              bordered: true
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              fontSize: Style.font.bodySmall
              iconText: root.showAllUpcoming ? "󰅃" : "󰅀"
              text: root.showAllUpcoming
                    ? "收起 (仅看未来 7 天)"
                    : ("查看更多 (未来 30 天 · 还有 " + root.hiddenUpcomingCount + " 项)")
              onClicked: root.showAllUpcoming = !root.showAllUpcoming
            }
          }

        }
      }
    }
  }
}
