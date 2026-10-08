# Susnix Launch

Tap **Super** (left or right Windows key), press **Super+R**, or click the dock's
Apps button. The existing Quickshell process owns this overlay; no second bar
or permanent indexing daemon is started.

## Browse and search

The centered glass panel shows favorites, installed apps, recents and quick
actions. The rail filters Development, Internet, Media, System, Games, Files,
Favorites and Recent. **App info** lists installed desktop entries; selecting
one shows its category, executable, Arch package/version and desktop-entry path.
Version is “Not provided” for unpackaged apps.

Type to switch immediately to grouped **APPS / FILES / COMMANDS / WEB / AI**
results. Up/Down selects a result; Enter opens it. Escape closes an action menu,
clears a query, then closes the overlay. Right click a tile/result, press Menu
on a focused tile, or use a result's ellipsis to access actions.

Drag favorite tiles onto one another to reorder, or drag an app onto **+ PIN**.
Drag two apps together in All to create a folder; drop another app on the
folder to add it. Click the folder to expand inline. Its context menu supports
rename and ungroup. These changes survive shell restart.

App actions include Open, Pin/Unpin, App info, Open in workspace 2 and Open as
root. Root launch opens a visible terminal for sudo authentication; Terminal's
root action opens a root shell. Files' internal shell view has no root action.

File actions include Open, Open in Code/editor, Open folder, Copy path, Run in
Terminal and Ask AI about file. Editor uses an installed Code/Codium/Kate/Vim;
Vim is the minimal installation fallback. Run accepts Python, shell scripts or
executable files, and starts them in the parent directory. Output stays visible
until Enter is pressed after the program exits.

Searchable commands include Bluetooth off, Dark theme, all six global themes,
Restart audio, Open radar project in Code, Open radar workspace and Update
Susnix. Radar uses `~/Radar`; its workspace command opens Terminal on workspace
2. Update opens `sudo pacman -Syu` in a terminal for review/authentication.

The existing AI head remains a placeholder. AI actions hand off to ChatGPT in
the installed browser and copy the prompt to the clipboard. File requests
include an explicitly selected UTF-8 excerpt of at most 4096 bytes (binary
files provide metadata). This is a web handoff, not local inference. Without a
browser, Web/AI actions show an installation notice and leave Launch open.

## State, search scope and cost

- Favorites, app folders and recents: `~/.local/state/susnix/launcher.json`
  (or `$XDG_STATE_HOME/susnix/launcher.json`), atomic writes, mode 0600.
- Apps come from Quickshell's XDG desktop entries; `NoDisplay` apps are hidden.
- Recent apps/files track Susnix launches; existing local GTK XBEL recents are
  also imported. Deleted files are removed on load.
- File cache: `$XDG_CACHE_HOME/susnix/launcher-files.sqlite`, default
  `~/.cache/susnix/launcher-files.sqlite`. Personal XDG directories plus
  `~/Projects`, `~/Radar`, `~/susnix` are indexed; hidden directories, `.git`,
  dependencies and build output are skipped. Symlink directories are not
  followed. Search is bounded to 50,000 entries / two seconds per refresh;
  refresh happens on demand, at most once per minute. Browse returns 48 recent
  entries; search returns at most 60. A footer reports a limited index.
- `SUSNIX_LAUNCHER_ROOTS` can override roots for direct helper invocations
  (colon-separated absolute paths); there is no whole-filesystem scan.
- One quarter-resolution `grim` capture is blurred with a tiny Qt image helper
  when opening. The resulting static image is retained in the runtime directory
  (latest two captures only). There is no continuously running blur shader,
  decorative frame loop or screenshot polling. Missing capture falls back to
  a dark panel. Searches are debounced and cancelled when the overlay closes.
- All UI colors use the existing global semantic Theme palette.

## Install and operate

Bootstrap includes the helper and shell. Update an existing desktop as its user:

```bash
bash scripts/setup-launcher.sh
bash scripts/setup-shell-desktop.sh
hyprctl reload
```

The Hyprland config uses the repository's existing symlink/copy installation
model. For custom configs, add the two Super release bindings from
`configs/hypr/hyprland.lua`; Super+R remains an alternate shortcut.

```bash
bash ~/.config/quickshell/susnix/bar.sh applications  # toggle Launch
bash ~/.config/quickshell/susnix/bar.sh reload
quickshell ipc -p ~/.config/quickshell/susnix call bar isLauncherOpen
```

The helper uses Python's standard library and existing Qt6Gui/Grim/wl-clipboard/
Hyprland packages; no new runtime dependency is required. Build needs the
existing C++ compiler and pkg-config. Quickshell IPC may return exit zero while
not ready: the bar helper retries readiness and dispatches the toggle once.

## Implementation files

Created: `apps/launcher/backdrop.cpp`, this README,
`configs/quickshell/desktop/LauncherTile.qml`,
`configs/quickshell/services/LauncherModel.qml`,
`configs/quickshell/services/launcher-backend.py`, `scripts/setup-launcher.sh`,
`tests/test-launcher-backend.py`, `tests/test-launcher-ipc.py`.

Modified: `configs/quickshell/desktop/AppDrawer.qml`,
`configs/quickshell/services/{DesktopState.qml,LauncherService.qml,qmldir}`,
`configs/quickshell/{shell.qml,bar.sh}`, `configs/hypr/hyprland.lua`,
`scripts/bootstrap.sh`, `configs/quickshell/desktop/README.md`, root `README.md`.

Validation combines QML/Lua/Bash syntax checks, backend boundary tests and a
fake-provider IPC regression test with live Hyprland checks of Super toggling,
drag/reorder/group persistence, metadata, clipboard paths, editor routing,
workspace launch, resolution changes, scrolling and palette switching.
Privileged updates and audio restarts are tested with fake providers so checks
do not update packages or interrupt the user's audio.
