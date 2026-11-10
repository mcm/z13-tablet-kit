#!/bin/bash
# z13-tablet-kit, Hyprland variant — installer (Omarchy and other Hyprland setups).
# Reuses the upstream posture daemon (bin/z13-tablet-switch) and touch-scroll
# daemon (bin/z13-touch-scroll) unchanged, and swaps in Hyprland versions of the
# KDE-specific pieces: dock, the touch-scroll display lookup, and the keyboard.
# z13ctl-plus is optional here (fans, TDP, RGB, the z13gui-plus settings card).
# Idempotent — safe to re-run. Run as your normal user.
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
HYP="$KIT/hyprland"
BIN="$HOME/.local/bin"
UNITS="$HOME/.config/systemd/user"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/z13-tablet-kit"

echo "==> z13-tablet-kit (Hyprland) install"

# --- dependencies ---
command -v python3 >/dev/null || { echo "ERROR: python3 required"; exit 1; }
python3 -c 'import evdev' 2>/dev/null || { echo "ERROR: python-evdev required  ->  sudo pacman -S python-evdev"; exit 1; }
command -v hyprctl >/dev/null || { echo "ERROR: hyprctl not found (is this a Hyprland system?)"; exit 1; }
command -v iio-hyprland >/dev/null || echo "NOTE: iio-hyprland not installed (auto-rotate)  ->  yay -S iio-hyprland-git"
command -v monitor-sensor >/dev/null || echo "NOTE: iio-sensor-proxy not installed (iio-hyprland needs it)  ->  sudo pacman -S iio-sensor-proxy"
command -v wvkbd-deskintl >/dev/null || command -v wvkbd-mobintl >/dev/null || \
	echo "NOTE: wvkbd not installed (on-screen keyboard)  ->  yay -S wvkbd-deskintl"
command -v z13ctl-plus >/dev/null || [ -x "$BIN/z13ctl-plus" ] || \
	echo "NOTE: z13ctl-plus not installed. Optional here; posture works without it (expect harmless 'tablet integration report failed' log lines)."
id -nG | grep -qw users || echo "NOTE: folio touchpad opt-in needs 'sudo usermod -aG users $USER' and a re-login"

# --- user components ---
install -Dm755 "$KIT/bin/z13-tablet-switch"              "$BIN/z13-tablet-switch"
install -Dm755 "$KIT/bin/z13-touch-scroll"               "$BIN/z13-touch-scroll"
install -Dm755 "$HYP/bin/dock"                           "$BIN/dock"
install -Dm755 "$HYP/bin/z13-touch-scroll-hyprland"      "$BIN/z13-touch-scroll-hyprland"
install -Dm755 "$HYP/bin/z13-osk"                        "$BIN/z13-osk"
install -Dm644 "$KIT/systemd/z13-tablet-switch.service"  "$UNITS/z13-tablet-switch.service"
install -Dm644 "$HYP/systemd/z13-touch-scroll.service"   "$UNITS/z13-touch-scroll.service"
if [ ! -e "$CONF_DIR/hyprland.env" ]; then
	install -Dm644 "$HYP/hyprland.env.example" "$CONF_DIR/hyprland.env"
fi

# --- system components (udev rules only, same as upstream) ---
# Must sort before systemd's 73-seat-late.rules, which applies the uaccess ACL.
sudo install -Dm644 "$KIT/udev/70-elan-touchscreen-uaccess.rules" /etc/udev/rules.d/70-elan-touchscreen-uaccess.rules
sudo install -Dm644 "$KIT/udev/99-disable-asus-touchpad.rules"    /etc/udev/rules.d/99-disable-asus-touchpad.rules

# --- conflicts with other Z13 guides ---
# Autostart lines (exec-once in hyprland.conf, launch_on_start in Lua). Files that
# already know about this kit (omarchy-rog-z13-setup's z13.lua checks for
# z13-touch-scroll-hyprland and steps aside) are skipped.
autostart_re='^[[:space:]]*(exec-once|o\.launch_on_start|hl\.exec_once).*(iio-hyprland|wvkbd)'
conflicts=$(grep -rlsE "$autostart_re" "$HOME/.config/hypr" | while read -r f; do
	grep -q 'z13-touch-scroll-hyprland' "$f" || echo "$f"
done)
if [ -n "$conflicts" ]; then
	echo "WARNING: your Hyprland config starts iio-hyprland or wvkbd at login."
	echo "         Remove those lines; dock now runs them in tablet posture only:"
	for f in $conflicts; do
		grep -nsE "$autostart_re" "$f" | sed "s|^|           $f:|"
	done
fi

# --- reload + enable ---
systemctl --user daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=input
systemctl --user enable z13-tablet-switch.service z13-touch-scroll.service
systemctl --user restart z13-tablet-switch.service z13-touch-scroll.service

echo "==> Done. Active now:"
echo "    • desktop/laptop/tablet posture, touch toggle, per-posture scale (z13-tablet-switch + dock)"
echo "    • auto-rotate and on-screen keyboard in tablet posture only"
echo "    • 2-finger touch scroll                           (z13-touch-scroll)"
echo "    • folio touchpad disabled (jumping-cursor bug)    (udev inhibited)"
if [ -f "$HOME/.config/hypr/z13.lua" ] && grep -q 'z13-osk' "$HOME/.config/hypr/z13.lua"; then
	echo "    Keyboard toggle: SUPER+V (from omarchy-rog-z13-setup's z13.lua; run 'hyprctl reload' once)"
elif [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
	echo "    Add a keyboard toggle to your Lua config, e.g.:"
	echo "        o.bind(\"SUPER + CTRL + K\", \"Virtual keyboard\", os.getenv(\"HOME\") .. \"/.local/bin/z13-osk\")"
else
	echo "    Add a keyboard toggle to ~/.config/hypr/bindings.conf, e.g.:"
	echo "        bind = SUPER CTRL, K, exec, z13-osk"
fi
echo "    Settings: $CONF_DIR/hyprland.env"
echo "    Log: journalctl --user -u z13-tablet-switch   |   posture: cat ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/z13-tablet-kit/posture"
