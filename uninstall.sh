#!/bin/sh
# Remove quadcast-knob, its udev rule and the optional mic level lock.
set -u
systemctl --user disable --now quadcast-knob.service 2>/dev/null
rm -f "$HOME/.local/bin/quadcast-knob" "$HOME/.config/systemd/user/quadcast-knob.service"
systemctl --user daemon-reload
lock="$HOME/.config/pipewire/pipewire-pulse.conf.d/90-quadcast-knob-mic-lock.conf"
if [ -f "$lock" ]; then rm -f "$lock"; systemctl --user restart pipewire-pulse.service; fi
if [ -f /etc/udev/rules.d/70-quadcast-knob.rules ]; then
    sudo rm -f /etc/udev/rules.d/70-quadcast-knob.rules && sudo udevadm control --reload
fi
echo "Removed. The knob goes back to being a speaker volume key."
