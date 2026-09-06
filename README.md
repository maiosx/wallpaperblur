# Wallpaper Blur

A blurred copy of your current wallpaper, drawn on Omarchy's desktop — above
the real background, beneath every window and every other widget.

| | |
|---|---|
| **Plugin id** | `wallpaper.blur` |
| **Requires** | Omarchy 4 (the Quickshell shell) |
| **Where** | Every screen, the Bottom layer, click-through |
| **Network** | None |

## Install

```bash
omarchy plugin add https://github.com/maiosx/wallpaperblur.git
omarchy plugin enable wallpaper.blur
```
Suggested keybind in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + B", "wallpaper.blur", "omarchy-shell wallpaper.blur toggle")
```

Or let the install script do both and restart the shell for you:

```bash
curl -fsSL https://raw.githubusercontent.com/maiosx/wallpaperblur/main/install | bash -s -- --yes
```

> **`omarchy plugin add` does not upgrade.** It refuses when the plugin is
> already installed. Use `update` (below) or re-run the install script, which
> picks `add` or `update` for you.

### From a local copy (no GitHub repo needed)

```bash
cp -r wallpaper-blur ~/.config/omarchy/plugins/wallpaper.blur
omarchy plugin enable wallpaper.blur
omarchy restart shell
```

## Updating

```bash
~/.config/omarchy/plugins/wallpaper.blur/update
```

Or by hand:

```bash
omarchy plugin update wallpaper.blur
omarchy restart shell
```

## Uninstall

```bash
omarchy plugin disable wallpaper.blur   # off, nothing removed
omarchy plugin remove wallpaper.blur    # gone
```

## Tuning the blur

Two properties at the top of `Surface.qml`:

| | |
|---|---|
| `blurAmount` | 0–1, how strong the blur looks |
| `blurRadiusPx` | how far it reaches, in pixels |

Edit, then `~/.config/omarchy/plugins/wallpaper.blur/update` if you
installed from git, or just `omarchy restart shell` if you edited the local
copy directly.

## How it finds the wallpaper

Omarchy has relocated the "current wallpaper" symlink before — from
`~/.config/omarchy/current/background` to
`~/.local/state/omarchy/current/background`. The plugin checks both and uses
whichever exists, polling every 2 seconds so it follows theme and wallpaper
changes without needing an IPC hook into the shell.

## How it behaves on the desktop

Same contract as omarchy-widgets: layer-shell on `WlrLayer.Bottom`, an empty
input mask (nothing here ever takes a click), `exclusiveZone: 0` so it
reserves no space. It is only ever something you see.

## Development

```bash
omarchy plugin validate .   # manifest against the Omarchy schema
```

There's no `dev/preview` script here (unlike omarchy-widgets) since this
plugin has no bar widget or config UI to iterate on — restarting the shell
after an edit is fast enough on its own.
