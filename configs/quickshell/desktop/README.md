# Susnix desktop

The existing Quickshell process now owns the desktop background, folder shortcuts,
bottom dock, application drawer, and Files browser, alongside the original top
bar and control center. The mockup's rain-soaked neon city is a generated raster
wallpaper; the folder icons and geometric wordmark are live themed vectors.
No desktop UI is baked into the wallpaper.

## Usage

- Drag the Files/Terminal header to move the window.
- **Alt + left drag** or **Super + left drag**: move any window.
- **Alt + right drag** or **Super + right drag**: resize a window.
- **Super+V**: toggle floating mode for free positioning of tiled applications.
- **Super+E**: open or focus Files.
- **Super** or **Super+R**: toggle [Susnix Launch](../../../apps/launcher/README.md),
  with app/file/command search, favorites, folders, recents and app information.
- **Super+Q**: launch a themed terminal.
- **Super+A**: toggle the existing control center.
- Click a desktop folder to open it. In Files, double click folders/files to open
  them; use the sidebar, Back and Up buttons, or the editable absolute path.
- The file-name filter is case insensitive. Clear it to restore all entries.
- Files supports Ctrl+L (path), Ctrl+H (hidden files), Alt+Left (back), Alt+Up
  (parent), Escape (close), and a Terminal button for the current directory.
- Files now includes Copy, Move, Rename, new folder, and Trash operations;
  see [the application notes](../../../apps/README.md). Source/text files open in the installed editor (Vim is provided by core);
  other files use the system's default application through `xdg-open`.

Manual commands inside Hyprland:

```bash
bash ~/.config/quickshell/susnix/bar.sh reload
bash ~/.config/quickshell/susnix/bar.sh files
bash ~/.config/quickshell/susnix/bar.sh applications
quickshell ipc -p ~/.config/quickshell/susnix call bar theme Sakura
quickshell ipc -p ~/.config/quickshell/susnix call bar theme Nyx
```

The global palette remains `~/.config/susnix/colors.json`. All new shell colors
come from Theme; a palette switch updates the desktop, vector icons, wordmark,
dock, application drawer, Files and window borders. It also regenerates the
Susnix-only terminal config at `~/.config/susnix/foot.ini` for fallback Foot windows, without overwriting an existing `~/.config/foot/foot.ini`.
The native terminal watches the same global palette and recolors live.
Hyprland config reloads restore the current border palette through shell IPC.
The city wallpaper itself stays static across theme changes.

## Installation

Bootstrap includes the desktop assets automatically. For a shell-only update:

```bash
bash scripts/setup-shell-desktop.sh
```

This preserves the current user state and global palette, copies the shell into
the existing configuration location, and creates standard personal folders.
The repository-linked Hyprland config remains linked. Bootstrap installs the
recommended Hyprland shortcuts for users using the copy-based installation.
There are no additional processes or independent autostart entries for the dock
or wallpaper.

The current VM lacks browser/media applications and sudo requires a password.
Their dock buttons are disabled until installed. Bootstrap's desktop package
list now includes Firefox, imv, mpv and xdg-user-dirs. To add them to this VM:

```bash
sudo pacman -S --needed firefox imv mpv xdg-user-dirs
xdg-user-dirs-update
```

## Assets and performance

`../assets/desktop/nyx-city.png` was generated with the built-in imagegen tool.
The exact prompt and provenance are in `../assets/desktop/README.md`.
`NeonFolder.qml` and `SusnixWordmark.qml` construct native SVGs from Theme colors
and render them at the current pixel ratio. The wallpaper scales with preserved
aspect ratio and cropping. There are no animated rain particles, blur passes,
continuously repainted canvases, or decorative timers on the desktop.
Folder listing uses Qt's event-driven FolderListModel. Native theme application
runs only at shell startup, palette changes and explicit configuration reloads.

## Validation

- All repository QML passes qmllint; shell scripts and Hyprland Lua parse cleanly.
- `python tests/test-desktop-appearance.py -v` verifies all six palettes produce
  valid Foot configurations, and rejects invalid color input.
- Existing desktop-control regression tests pass.
- Live mouse tests verified desktop Home, folder entry/parent navigation, Files
  close, app drawer opening and dock terminal launch. Existing Files windows can
  be focused again from the dock.
- A case-insensitive README filter and double-click opening were verified live;
  Vim opened the actual repository README inside the themed terminal.
- Runtime switching to Sakura recolored the desktop and Files; the generated
  terminal palette and Hyprland border values changed. NYX was restored.
- The desktop and Files were inspected at 640×480 and the normal 958×967 VM mode.
  An already-open file window clamps to the new viewport and recenters on resize;
  its sidebar/footer use a compact layout. Vector rendering was also inspected
  at 1920×1080 with 2× scaling.
- Hyprland reports one background, one dock and one top bar on the monitor, with
  36 px reserved above and 52 px below. The existing control center remains an
  overlay with its full-height layout.
- Quickshell idle CPU measured **0.65% of one core over 15 seconds** in the VM,
  with the control center closed. This is a process measurement, not total VM
  CPU or a hardware performance guarantee.
- No VM reboot was performed during desktop implementation.

## Exact file changes

Created:

```text
configs/quickshell/assets/desktop/nyx-city.png
configs/quickshell/assets/desktop/README.md
configs/quickshell/desktop/DesktopBackground.qml
configs/quickshell/desktop/DesktopDock.qml
configs/quickshell/desktop/AppDrawer.qml
configs/quickshell/desktop/FilesWindow.qml
configs/quickshell/desktop/NeonFolder.qml
configs/quickshell/desktop/SusnixWordmark.qml
configs/quickshell/desktop/README.md
configs/quickshell/services/DesktopState.qml
configs/quickshell/services/DesktopAppearance.qml
configs/quickshell/services/desktop-paths.sh
configs/quickshell/services/desktop-appearance.sh
configs/quickshell/services/open-terminal.sh
scripts/setup-shell-desktop.sh
tests/test-desktop-appearance.py
```

Modified:

```text
configs/quickshell/shell.qml
configs/quickshell/bar.sh
configs/quickshell/components/Icon.qml
configs/quickshell/components/QuickLauncher.qml
configs/quickshell/services/LauncherService.qml
configs/quickshell/services/qmldir
configs/hypr/hyprland.lua
packages/desktop.txt
scripts/bootstrap.sh
README.md
```
