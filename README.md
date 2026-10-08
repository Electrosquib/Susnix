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

The cyberpunk desktop, folder browser and dock are documented in
[the desktop implementation notes](configs/quickshell/desktop/README.md),
including launch commands, generated assets, validation and the exact file list.

## VirtualBox clipboard startup

Bootstrap installs and enables the persistent user service
`configs/virtualbox/susnix-clipboard.service` under `default.target`. It starts
at user login, independently of the Hyprland autostart hook, using
`~/.config/susnix/clipboard.sh watch`. It discovers the current display from an
owned Hyprland lock file and validates the compositor PID and Wayland socket.
Missing display environment, late compositor startup, and missing or empty
session files keep the service waiting instead of silently skipping startup.
The foreground VBoxClient connection is supervised and restarted after failure;
when a compositor exits, the watcher reconnects to the next desktop session.
The Hyprland hook also requests a restart of this installed service. The helper
retains transient service startup for older installations without the user unit.
Before each connection, both startup paths stop only this user’s older clipboard
clients and clear their stale PID files. The watcher waits for the unprivileged
`/dev/vboxuser` device to become accessible, avoiding a Guest Additions boot race.
Display resizing clients are preserved. Non-VirtualBox machines skip startup.

Manual recovery and logs (normally unnecessary):

```bash
bash ~/.config/susnix/clipboard.sh restart
bash ~/.config/susnix/clipboard.sh logs
```

Validated delayed startup using `python tests/test-clipboard-startup.py` (inside
a VirtualBox guest), including missing and empty session PID files, startup with
no inherited display environment, rejection of non-compositor session PIDs,
retiring a legacy clipboard client, and reconnecting after a compositor restart. Also checked
shell/Lua syntax, live Wayland clipboard initialization, automatic
recovery after terminating the clipboard client, and repeat startup with exactly
one clipboard client tied to the current compositor. No reboot or host-side
Windows clipboard round trip was performed. VirtualBox must have shared clipboard
enabled on the host; Susnix cannot change the host VM setting from inside the guest.

Files: `configs/virtualbox/clipboard.sh`,
`configs/virtualbox/susnix-clipboard.service`, `scripts/bootstrap.sh`,
`tests/test-clipboard-startup.py`, and this README. No additional packages or sudo were needed
for the current user installation. The installed Hyprland config remains linked
to the repository.

Reference: [VirtualBox's Wayland clipboard implementation](https://github.com/VirtualBox/virtualbox/issues/33).
