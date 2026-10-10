# HyperX QuadCast S knob on Linux

On Windows, turning the knob on the HyperX QuadCast S changes the mic gain. On
Linux it doesn't, and on most desktops it changes your **speaker** volume
instead. This makes the knob control the mic again.

> **Status, 10 Oct 2026: the knob itself is not fixed yet.** A physical test
> on my own QuadCast S showed the knob sends **nothing** over USB (no keys, no
> reports) and does not change the recorded level on Linux. The explanation
> below was a wrong first guess, made from the mic's HID descriptor. What this
> tool really does today: it stops the mic's volume keys reaching the desktop,
> if your unit sends them, and `--lock-mic-volume` stops apps from changing the
> mic level, which works as described. The investigation is ongoing; watch
> this repo before installing for the knob alone.

## Why (first guess, disproved on the author's unit)

The knob doesn't change the gain inside the mic. It sends ordinary "volume
up / volume down" keys from the mic's own USB interface. Windows links a USB
audio device's volume keys to that device, so they move the mic level. Linux
has no such link, so the desktop treats them like the volume keys on a keyboard.

`quadcast-knob` is a small background service (Python, standard library only).
It:
- takes those keys from the mic exclusively, so the desktop no longer sees them;
- turns each click into a **1 dB step on the mic's source**, which PipeWire
  applies to the mic's hardware gain (one click = one hardware step);
- stops at 100 % (the hardware maximum), never amplifying in software;
- picks up again by itself when you unplug and replug the mic.

## Install

```sh
git clone https://github.com/ENC4YP7ED/hyperx-quadcast-s-knob.git
cd hyperx-quadcast-s-knob
./install.sh
```

It installs the script to `~/.local/bin`, a systemd user service, and a udev
rule that gives your login access to this one device. The udev rule needs sudo
once. You don't need to join the `input` group, which would let programs read
every keyboard.

### Optional: lock the mic level

Discord, browsers, Zoom and many games "automatically adjust" the mic level,
which moves it behind your back. To stop that:

```sh
./install.sh --lock-mic-volume
```

After that, apps going through PulseAudio (practically all of them) can no
longer change the mic volume. The knob still can, and so can tools that talk to
PipeWire natively (`wpctl`, DankMaterialShell). Most desktop sound panels (KDE,
GNOME) and pavucontrol use the PulseAudio protocol and are locked out too, so
skip the lock if that's where you set your mic level.

## Check that it works

```sh
journalctl --user -u quadcast-knob -f
```

Turn the knob. You should see lines like `knob down: mic 100% -> 96%`, and your
speaker volume should no longer move.

## Settings

Edit with `systemctl --user edit quadcast-knob` (add `Environment=` lines):

| Variable | Default | |
|---|---|---|
| `QUADCAST_KNOB_STEP_DB` | `1` | dB per click |
| `QUADCAST_KNOB_USB` | `03f0:0294` | vendor:product of the mic |
| `QUADCAST_KNOB_SOURCE` | auto | the PipeWire/PulseAudio source name (`pactl list short sources`) |
| `QUADCAST_KNOB_DEVICE` | auto | the input device (`/dev/input/eventN`) |

## Uninstall

```sh
./uninstall.sh
```

## Limits

- Built on one QuadCast S (`03f0:0294`) with PipeWire 1.6 and pipewire-pulse
  (Ubuntu 26.04, Hyprland). The key events were taken from the mic's own HID
  descriptor and tested by injecting them into its input device. It works at
  the input-device level, so the desktop doesn't matter. It needs `pactl` and
  systemd.
- Other mics that send volume keys from their own USB interface may work with
  `QUADCAST_KNOB_USB` and `QUADCAST_KNOB_SOURCE` set, but that is untested. If
  your knob sends something else, the log says `swallowed key <number>`. Open
  an issue with that line.
- Mute and media keys from the mic's interface are ignored, so they can't
  mute your speakers any more. The mic's tap-to-mute is not touched.
- The lock blocks *all* PulseAudio apps from changing *any* mic's volume, not
  only the QuadCast's.

## License

MIT
