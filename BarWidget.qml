import QtQuick
import Quickshell
import Quickshell.Io

// Compact bar control for Wallpaper Blur.
// Shows the letter "B". Left-click toggles the blurred underlay on/off.
// Dimmed when off so the bar state is obvious at a glance.
Item {
  id: root

  // Injected by the Omarchy bar / plugin loader.
  property var bar: null
  property var shell: null
  property var manifest: null
  property var settings: null
  property string moduleName: "wallpaper.blur"

  property bool blurOn: true

  implicitWidth: 28
  implicitHeight: bar ? (bar.barSize || 26) : 26

  // Keep local state in sync with the panel's IpcHandler.
  Process {
    id: query
    command: ["omarchy-shell", "-q", "wallpaper.blur", "getEnabled"]
    stdout: StdioCollector {
      onStreamFinished: {
        const t = text.trim().toLowerCase()
        if (t === "true" || t === "1") root.blurOn = true
        else if (t === "false" || t === "0") root.blurOn = false
      }
    }
  }

  Process {
    id: toggler
    command: ["omarchy-shell", "-q", "wallpaper.blur", "toggle"]
    onExited: Qt.callLater(() => { query.running = true })
  }

  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: query.running = true
  }

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: root.blurOn ? (bar && bar.accent ? bar.accent : "#6c9ef8") : "transparent"
    opacity: root.blurOn ? 0.22 : 0
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  Text {
    anchors.centerIn: parent
    text: "B"
    color: bar && bar.foreground ? bar.foreground : "#e8e8e8"
    opacity: root.blurOn ? 1.0 : 0.45
    font.family: bar && bar.fontFamily ? bar.fontFamily : "sans-serif"
    font.pixelSize: 13
    font.bold: true
    Behavior on opacity { NumberAnimation { duration: 120 } }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: toggler.running = true
  }
}
