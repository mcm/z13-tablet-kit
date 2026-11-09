# z13-tablet-kit for Hyprland (Omarchy)

A Hyprland port of the kit for the 2025 ROG Flow Z13 (GZ302). It reuses the
upstream daemons unchanged and replaces only the parts that talked to KDE.

| Piece | Upstream (Plasma) | This variant |
|---|---|---|
| Posture detection + virtual `SW_TABLET_MODE` | `bin/z13-tablet-switch` | same file, unchanged |
| Apply posture | `bin/dock` (KWin D-Bus, z13ctl-plus) | `hyprland/bin/dock` (hyprctl) |
| Touchscreen on/off | KWin `InputDevice.enabled` | `hyprctl keyword device[…]:enabled` |
| Scale per posture | z13ctl-plus + KScreen | `hyprctl keyword monitor` |
| Auto-rotate | Plasma, gated by tablet switch | `iio-hyprland`, run in tablet posture only |
| On-screen keyboard | plasma-keyboard / maliit | `wvkbd`, hidden in tablet posture, toggled by `z13-osk` |
| Two-finger scroll | `bin/z13-touch-scroll` | same file, unchanged |
| Two-finger-hold right-click | kscreen-doctor + relative pointer | `hyprland/bin/z13-touch-scroll-hyprland` (hyprctl, `movecursor`) |
| Folio touchpad off, touchscreen access | udev rules | same rules |
| z13ctl-plus | required | optional |

## Install

```sh
sudo pacman -S python-evdev iio-sensor-proxy
yay -S iio-hyprland-git wvkbd
./hyprland/install.sh
```

Then bind the keyboard toggle in `~/.config/hypr/bindings.conf`:

```
bind = SUPER CTRL, K, exec, z13-osk
```

If you followed the ib99 or Cliffback Z13 guide, remove their
`exec-once = iio-hyprland` / `wvkbd` lines; the installer warns if it finds them.

## Settings

`~/.config/z13-tablet-kit/hyprland.env`: monitor, mode, per-posture scale, and the
rotate/keyboard commands. If z13ctl-plus and z13gui-plus are installed, the GUI's
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
