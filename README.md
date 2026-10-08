# Susnix
My attempt at an Arch-based Linux distribution with a cyberpunk-inspired design and a focus on aesthetics, coolness, and productivity.

## Desktop startup

The bootstrap configures tty1 to log in to the selected desktop user and start
Hyprland automatically. Hyprland then starts the Susnix bar. This takes effect
at the next boot; setup does not restart the active login or desktop.

Apply to an existing installation:

```bash
sudo bash ~/susnix/scripts/setup-desktop-start.sh "$USER" --autologin
```

Set `SUSNIX_AUTOLOGIN=false` when running bootstrap to retain password login.
The Bash login profile is preserved and backed up before its first edit. The
startup guard only runs on interactive local tty1 logins; other consoles, SSH,
and desktop terminal windows keep their usual behavior. An existing display
manager is preserved rather than replaced.

Files: `configs/session/start-hyprland.sh`, `scripts/setup-desktop-start.sh`,
`scripts/bootstrap.sh`, and this README. The setup installs the guard under
`~/.config/susnix/`, adds one source line to `~/.bash_profile`, and writes the
systemd drop-in `/etc/systemd/system/getty@tty1.service.d/susnix-autologin.conf`.
To disable automatic login, remove that drop-in and run `sudo systemctl daemon-reload`.
To disable tty1 desktop startup, remove the Susnix source line from `~/.bash_profile`.

References: [Hyprland launch instructions](https://wiki.hypr.land/Getting-Started/Master-Tutorial/),
[agetty automatic login](https://man7.org/linux/man-pages/man8/agetty.8.html).

## VirtualBox clipboard startup

Hyprland starts `~/.config/susnix/clipboard.sh` once at desktop login. Bootstrap
installs this helper from `configs/virtualbox/clipboard.sh`. The launcher replaces
legacy clipboard clients from earlier desktop sessions, then creates the user
service `susnix-clipboard.service` with foreground VBoxClient and crash recovery.
The supervised service waits for the Wayland socket, guest device, and Hyprland
session PID file before launching VBoxClient; boot-time missing or empty files
do not cause a silent exit. Readiness timeouts are retried automatically.
It passes the current Wayland/Hyprland environment explicitly and ends the bridge
when that compositor process exits. Every new login starts a fresh connection,
rather than accepting “already running” from a stale client. Display resizing
clients are preserved. Non-VirtualBox machines skip this startup.

Manual recovery and logs (normally unnecessary):

```bash
bash ~/.config/susnix/clipboard.sh restart
bash ~/.config/susnix/clipboard.sh logs
```

Validated delayed startup using `python tests/test-clipboard-startup.py` (inside
a VirtualBox guest), including missing and empty session PID files. Also checked
shell/Lua syntax, live Wayland clipboard initialization, automatic
recovery after terminating the clipboard client, and repeat startup with exactly
one clipboard client tied to the current compositor. No reboot or host-side
Windows clipboard round trip was performed. VirtualBox must have shared clipboard
enabled on the host; Susnix cannot change the host VM setting from inside the guest.

Files: `configs/virtualbox/clipboard.sh` (new), `configs/hypr/hyprland.lua`,
`scripts/bootstrap.sh`, `tests/test-clipboard-startup.py` (new boot-race regression
test), and this README. No additional packages or sudo were needed
for the current user installation. The installed Hyprland config remains linked
to the repository.

Reference: [VirtualBox's Wayland clipboard implementation](https://github.com/VirtualBox/virtualbox/issues/33).
