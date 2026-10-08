# Susnix Terminal and Files

Terminal is a real Qt 6/QTermWidget PTY application, with compact angular
controls, tabs, translucent glass, live semantic theme colors, and static edge
lighting. It starts the user's actual shell and reports actual machine details;
the mockup's hardware and distro version are not fabricated. QTermWidget is the
only new package. Foot remains the fallback when the native terminal is absent.

Files keeps the same Quickshell process. It now has Details, Grid, and Compact
grid views; folder icons in every view and the sidebar; clickable breadcrumbs;
an editable path; search/sort/filter; a collapsible details panel with image or
small source previews; and Open, Copy, Move, Rename, Terminal, Code, and Trash
actions. Operations refuse overwrites. Trash follows the freedesktop layout;
it does not permanently delete files. Network shows guidance for mounted
shares; automatic SMB discovery is not implemented.

## Install and use

Bootstrap installs everything. To update this desktop separately:

```bash
bash scripts/setup-terminal.sh
bash scripts/setup-window-controls.sh
bash scripts/setup-shell-desktop.sh
bash ~/.config/susnix/window-controls.sh
hyprctl reload
```

For a normal build, install the Arch `qtermwidget` package first. The build script
also accepts `SUSNIX_QTERMWIDGET_ROOT` pointing to an extracted Arch package for
local testing; that route copies its library beside the user-installed binary.
No compiled binaries are committed.

- **Super+Q**: Terminal. **Super+E**: Files.
- Drag Files' header, Terminal's header/tab area, or another app's titlebar.
- **Super+left drag**: move; **Super+right drag**: resize any window.
- **Super+V**: switch a window between tiling and floating. Terminal/Files start
  floating; tiled app movement rearranges the layout.
- **Super+Shift+M**: show windows minimized to the dedicated special workspace.
- Terminal: **Ctrl+Shift+T/W** new/close tab, **Ctrl+Shift+C/V** copy/paste,
  **Ctrl+Shift+F** search, **Ctrl+Shift++/−/0** font zoom/reset, **Ctrl+PageUp/Down** tabs.
- Files: **Ctrl+L** path, **Ctrl+H** hidden files, **Alt+Left/Right** back/forward,
  **Alt+Up** parent, **F2** rename. Double-click opens a file or folder.

Manual launch: `~/.local/bin/susnix-terminal` or
`~/.local/bin/susnix-terminal --working-directory ~/Projects`.
Use `-- command arguments` to run a program directly. `susfetch` in the Bash
terminal prints real system information. Existing `.bashrc` is sourced, not
replaced. Theme switching updates existing terminal sessions and shell widgets:

```bash
quickshell ipc -p ~/.config/quickshell/susnix call bar theme Sakura
quickshell ipc -p ~/.config/quickshell/susnix call bar theme Nyx
```

The shared settings remain `~/.config/susnix/colors.json`. Native terminal assets
contain the same six semantic palettes as the shell. Terminal rendering has no
idle decorative frame loop; only the clock updates once per second. Files uses
inotify while open rather than repeatedly scanning folders. Individual file
icons do not run the top bar's electrical hover animation.

## VirtualBox pointer performance

On VirtualBox only, the existing Hyprland config disables compositor blur,
uses flat pointer acceleration for its three virtual pointer devices, and
shortens window animations to 150–180 ms with a restrained easing curve. Glass
surfaces and semantic outlines remain. Physical hardware settings are preserved.
These reduce rendering/acceleration causes of lag; host load or guest integration
can still affect pointer responsiveness. Borders now support mouse resizing.

## Validation

`bash scripts/test-terminal.sh` checks a real PTY, clipboard paste, Unicode,
resize, atomic palette updates, and invalid-settings retention.
`python tests/test-explorer-backend.py -v` checks copy/move/rename without
clobbering files, folder/symlink behavior, Trash metadata, source previews,
and an idle inotify watcher reacting to real changes. QML is checked with
`/usr/lib/qt6/bin/qmllint`; shell/Lua syntax and existing appearance/action tests
are checked separately. Live Wayland checks cover folder icons, header dragging,
compact native controls, theme changes, and clean runtime logs.

The compositor decoration's source, version check, and license are documented in
[window-controls/README.md](window-controls/README.md).

## Files changed in this implementation

Created:

```text
apps/README.md
apps/terminal/main.cpp
apps/terminal/palette.hpp
apps/terminal/pty-smoke.cpp
apps/terminal/susnix-terminal.desktop
apps/terminal/theme-smoke.cpp
apps/terminal/window.hpp
apps/window-controls/BarPassElement.cpp
apps/window-controls/BarPassElement.hpp
apps/window-controls/LICENSE
apps/window-controls/README.md
apps/window-controls/barDeco.cpp
apps/window-controls/barDeco.hpp
apps/window-controls/globals.hpp
apps/window-controls/main.cpp
configs/hypr/window-controls.lua
configs/hypr/window-controls.sh
configs/quickshell/components/ThemeDialog.qml
configs/quickshell/components/ThemeMenu.qml
configs/quickshell/components/WindowControls.qml
configs/quickshell/services/ExplorerService.qml
configs/quickshell/services/explorer-backend.py
configs/terminal/bashrc
configs/terminal/susfetch.py
scripts/build-terminal.sh
scripts/setup-terminal.sh
scripts/setup-window-controls.sh
scripts/test-terminal.sh
tests/test-explorer-backend.py
```

Modified:

```text
README.md
configs/hypr/hyprland.lua
configs/quickshell/components/ElectricShock.qml
configs/quickshell/components/Icon.qml
configs/quickshell/components/QuickLauncher.qml
configs/quickshell/desktop/DesktopBackground.qml
configs/quickshell/desktop/DesktopDock.qml
configs/quickshell/desktop/FilesWindow.qml
configs/quickshell/desktop/README.md
configs/quickshell/services/DesktopState.qml
configs/quickshell/services/LauncherService.qml
configs/quickshell/services/desktop-appearance.sh
configs/quickshell/services/desktop-paths.sh
configs/quickshell/services/open-terminal.sh
configs/quickshell/services/qmldir
packages/desktop.txt
scripts/bootstrap.sh
scripts/setup-shell-desktop.sh
```
