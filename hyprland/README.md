# z13-tablet-kit for Hyprland (Omarchy)

A Hyprland port of the kit for the 2025 ROG Flow Z13 (GZ302). It reuses the
upstream daemons unchanged and replaces only the parts that talked to KDE.

Works with both Hyprland config providers: the Lua config (Hyprland 0.55+,
Omarchy 4 "Quattro"), where changes go through `hyprctl eval` and Lua
dispatchers, and the classic `hyprland.conf`, where they go through
`hyprctl keyword` and `hyprctl dispatch <name>`. The Lua path is used whenever
`~/.config/hypr/hyprland.lua` exists, which is when Hyprland itself uses it.

| Piece | Upstream (Plasma) | This variant |
|---|---|---|
| Posture detection + virtual `SW_TABLET_MODE` | `bin/z13-tablet-switch` | same file, unchanged |
| Apply posture | `bin/dock` (KWin D-Bus, z13ctl-plus) | `hyprland/bin/dock` (hyprctl) |
| Touchscreen on/off | KWin `InputDevice.enabled` | `hl.device({ name, enabled })` / `device[…]:enabled` |
| Rotation reset outside tablet, optional scale per posture | z13ctl-plus + KScreen | `hl.monitor(…)` / `keyword monitor` |
| Auto-rotate | Plasma, gated by tablet switch | `iio-hyprland`, run in tablet posture only |
| On-screen keyboard | plasma-keyboard / maliit | `wvkbd`, hidden in tablet posture, toggled by `z13-osk` |
| Two-finger scroll | `bin/z13-touch-scroll` | same file, unchanged |
| Two-finger-hold right-click | kscreen-doctor + relative pointer | `hyprland/bin/z13-touch-scroll-hyprland` (`hl.dsp.cursor.move` / `movecursor`) |
| Folio touchpad off, touchscreen access | udev rules | same rules |
| z13ctl-plus | required | optional |

## Install

```sh
sudo pacman -S python-evdev iio-sensor-proxy
yay -S iio-hyprland-git wvkbd-deskintl
./hyprland/install.sh
```

### With omarchy-rog-z13-setup

The `no-cachy-kernel` branch of [mcm/omarchy-rog-z13-setup](https://github.com/mcm/omarchy-rog-z13-setup)
already installs `iio-hyprland-git` (plus its `~/.local/bin/iio-hyprland` wrapper) and
`wvkbd-deskintl`, and its `z13.lua` steps aside when this kit is installed: it stops
starting `iio-hyprland` at login and binds `SUPER+V` to `z13-osk`. Run that setup first,
then this installer, then `hyprctl reload` once.

### Other setups

Bind the keyboard toggle yourself. Lua config:

```lua
o.bind("SUPER + CTRL + K", "Virtual keyboard", os.getenv("HOME") .. "/.local/bin/z13-osk")
```

`hyprland.conf`:

```
bind = SUPER CTRL, K, exec, z13-osk
```

If another guide starts `iio-hyprland` or `wvkbd` at login (`exec-once` or
`o.launch_on_start`), remove those lines; the installer warns if it finds them.

## Settings

`~/.config/z13-tablet-kit/hyprland.env`: monitor, mode, optional per-posture scale, and
the rotate/keyboard commands. If z13ctl-plus and z13gui-plus are installed, the GUI's
"Disable touchscreen on desktop", scroll sliders and two-finger-hold toggle still
work, because the upstream daemons read them.

## Known gaps

- Untested on hardware so far. Check `journalctl --user -u z13-tablet-switch -u z13-touch-scroll`.
- A Hyprland config reload resets the touchscreen to enabled; dock re-applies within 5 minutes
  or on the next posture change.
- If the two-finger-hold right-click lands mirrored when rotated, swap the `1` and `3`
  entries in `TRANSFORM_TO_KSCREEN` in `z13-touch-scroll-hyprland`.
- Apps with native touch scrolling (Firefox, GTK4) may scroll twice from a two-finger swipe.
- wvkbd doesn't pop up on text focus the way plasma-keyboard does; use `z13-osk`.
