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
