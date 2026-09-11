import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// One layer-shell surface per output, each showing a blurred copy of the
// current wallpaper image.
//
// It sits on the Background layer (one step below Bottom), so it lives under
// the real wallpaper and any Bottom-layer desktop widgets.
// `exclusiveZone: 0` reserves no space, and an empty `mask` means every
// click passes straight through to whatever is underneath. Nothing here is
// interactive; it is only ever something you see.
//
// Toggle on/off from the bar "B" widget (or via IPC: wallpaper.blur toggle).
Item {
  id: root

  // Injected by the Omarchy shell when the plugin loads. Unused here, but
  // kept so the plugin loader's usual injection doesn't warn.
  property var shell: null
  property var manifest: null

  // How strong the blur is. blurAmount is 0-1 (QtQuick.Effects MultiEffect's
  // own scale); blurRadiusPx is roughly how far it reaches, in pixels.
  // Edit these two to taste.
  property real blurAmount: 0.7
  property int blurRadiusPx: 96

  // Runtime on/off. The bar "B" widget and IPC flip this.
  property bool blurEnabled: true

  // Omarchy has relocated this symlink before (config/ moved to
  // local/state/ at some point), so this resolves whichever one exists
  // rather than betting on one path. `readlink -f` also follows it through
  // to the real image file Image{} needs.
  property string wallpaperPath: ""

  Process {
    id: resolver
    command: ["bash", "-c",
      "for p in \"$HOME/.local/state/omarchy/current/background\" " +
      "\"$HOME/.config/omarchy/current/background\"; do " +
      "[ -e \"$p\" ] && readlink -f \"$p\" && exit 0; done; " +
      "for cmdline in /proc/[0-9]*/cmdline; do " +
      "[[ -r \"$cmdline\" ]] || continue; " +
      "mapfile -d '' -t args < \"$cmdline\" 2>/dev/null || true; " +
      "[[ \"${args[0]##*/}\" == swaybg ]] || continue; " +
      "for ((i=1; i<${#args[@]}; i++)); do " +
      "case \"${args[i]}\" in -i|--image) p=\"${args[i+1]}\"; " +
      "[[ -f \"$p\" ]] && printf '%s\\n' \"$p\" && exit 0 ;; esac; " +
      "done; done"]
    stdout: SplitParser {
      onRead: data => {
        const p = data.trim()
        if (p.length > 0 && p !== root.wallpaperPath) root.wallpaperPath = p
      }
    }
  }

  // Polls rather than watching the symlink directly: `ln -nsf` swaps the
  // link atomically, which file watchers don't reliably report as a change
  // on every filesystem. Two seconds is often enough to feel instant next
  // to a theme or wallpaper switch without running the process constantly.
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: resolver.running = true
  }

  // IPC so the bar widget (and keybinds) can toggle without sharing objects.
  IpcHandler {
    target: "wallpaper.blur"

    function toggle(): void {
      root.blurEnabled = !root.blurEnabled
    }

    function enable(): void {
      root.blurEnabled = true
    }

    function disable(): void {
      root.blurEnabled = false
    }

    function getEnabled(): bool {
      return root.blurEnabled
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: surface
        required property var modelData

        screen: modelData
        visible: root.blurEnabled && root.wallpaperPath.length > 0
        color: "transparent"

        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "wallpaper-blur"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0

        // Empty region: nothing here ever takes a click.
        mask: Region {}

        Image {
          id: source
          anchors.fill: parent
          source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          cache: false
          sourceSize.width: surface.width
          sourceSize.height: surface.height
          // Hidden: MultiEffect below reads it as a texture rather than it
          // being drawn twice.
          visible: false
        }

        MultiEffect {
          anchors.fill: source
          source: source
          blurEnabled: true
          blur: root.blurAmount
          blurMax: root.blurRadiusPx
          autoPaddingEnabled: false
        }
      }
    }
  }
}
