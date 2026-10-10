#!/bin/sh
# Install quadcast-knob for the current user.
#   ./install.sh                     knob -> mic gain
#   ./install.sh --lock-mic-volume   also stop other apps from changing the mic level
set -eu
here=$(cd "$(dirname "$0")" && pwd)
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1 ($2)"; exit 1; }; }
need python3 "install python3"
need pactl "install pipewire-pulse or pulseaudio-utils"
need systemctl "needs systemd"

install -Dm755 "$here/quadcast-knob" "$HOME/.local/bin/quadcast-knob"
install -Dm644 "$here/systemd/quadcast-knob.service" "$HOME/.config/systemd/user/quadcast-knob.service"

rule=/etc/udev/rules.d/70-quadcast-knob.rules
if ! cmp -s "$here/udev/70-quadcast-knob.rules" "$rule" 2>/dev/null; then
    echo "Installing the udev rule (device access for your login only); this needs sudo:"
    sudo install -Dm644 "$here/udev/70-quadcast-knob.rules" "$rule"
    sudo udevadm control --reload
    sudo udevadm trigger --subsystem-match=input --action=change
fi

if [ "${1:-}" = "--lock-mic-volume" ]; then
    install -Dm644 "$here/pipewire/90-quadcast-knob-mic-lock.conf" \
        "$HOME/.config/pipewire/pipewire-pulse.conf.d/90-quadcast-knob-mic-lock.conf"
    systemctl --user restart pipewire-pulse.service
    echo "Mic level lock on: other apps can no longer change the mic volume."
fi

systemctl --user daemon-reload
systemctl --user enable quadcast-knob.service >/dev/null 2>&1
systemctl --user restart quadcast-knob.service
sleep 1
journalctl --user -u quadcast-knob -n 2 --no-pager -o cat
echo "Done. Turn the knob and watch:  journalctl --user -u quadcast-knob -f"
