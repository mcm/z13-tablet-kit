#!/bin/bash
# z13-tablet-kit, Hyprland variant — uninstaller. Leaves ~/.config/z13-tablet-kit in place.
set -uo pipefail
BIN="$HOME/.local/bin"
UNITS="$HOME/.config/systemd/user"

echo "==> z13-tablet-kit (Hyprland) uninstall"
systemctl --user disable --now z13-tablet-switch.service z13-touch-scroll.service 2>/dev/null
rm -f "$UNITS/z13-tablet-switch.service" "$UNITS/z13-touch-scroll.service"
rm -f "$BIN/dock" "$BIN/z13-tablet-switch" "$BIN/z13-touch-scroll" \
	"$BIN/z13-touch-scroll-hyprland" "$BIN/z13-osk"
systemctl --user daemon-reload

# Leave the session usable: touch on, rotation normal, helpers stopped.
pkill -u "$(id -u)" -x iio-hyprland 2>/dev/null
pkill -u "$(id -u)" -x wvkbd-mobintl 2>/dev/null
if command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
	hyprctl reload >/dev/null 2>&1
fi
rm -rf "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/z13-tablet-kit"

sudo rm -f /etc/udev/rules.d/70-elan-touchscreen-uaccess.rules /etc/udev/rules.d/99-disable-asus-touchpad.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=input
echo "==> Done."
