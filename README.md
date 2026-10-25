# Roku-ESP32-Remote
ESP32 Wi-Fi remote for Roku, built to be wired into a box as a standalone, headless remote.

It talks to the Roku over the local network using Roku's External Control Protocol (ECP). **No IP address setup is needed:** on boot the remote finds the Roku automatically (SSDP discovery) and remembers it. If the Roku later gets a new IP from your router, the remote notices the next time a button press fails and finds it again.

Developed for an ESP32-WROOM-32 (38-pin dev board) in the Arduino IDE, with a Roku Streambar. Compiles on the ESP32 Arduino core 3.x.

## Setup

1. Open `roku_remote/roku_remote.ino` in the Arduino IDE.
2. Copy `roku_remote/secrets.example.h` to `roku_remote/secrets.h` and fill in your Wi-Fi name and password. `secrets.h` is git-ignored, so your credentials stay off GitHub.
3. On the Roku, set **Settings > System > Advanced system settings > Control by mobile apps** to **Enabled**. Since Roku OS 14.1 the Roku ignores network key presses without this.
4. For input switching and TV power, turn on CEC on the TV and on the Roku (**Settings > System > Control other devices (CEC)**).
5. Flash the ESP32. The serial monitor (115200 baud) shows the Roku it found and the result of each key press.

If you have more than one Roku, set `ROKU_SERIAL` at the top of the sketch to the one this remote should control.

## Buttons

Each button connects its GPIO pin to GND; internal pull-ups are used. Arrows and volume auto-repeat while held.

| Button | Pin | ECP key |
|---|---|---|
| Up | 23 | `Up` |
| Down | 21 | `Down` |
| Left | 4 | `Left` |
| Right | 5 | `Right` |
| Select | 15 | `Select` |
| Home | 26 | `Home` (also switches the TV back to the Roku) |
| Back | 25 | `Back` |
| Play | 32 | `Play` |
| Rewind | 33 | `Rev` |
| Fast Forward | 27 | `Fwd` |
| Volume Up | 14 | `VolumeUp` |
| Volume Down | 12 | `VolumeDown` |
| Power Off | 2 | `PowerOff` |
| Info (Star) | 19 | `Info` |
| TV input HDMI 1 | 13 | `InputHDMI1` |
| TV input HDMI 2 | 16 | `InputHDMI2` |
| TV input HDMI 3 | 17 | `InputHDMI3` |
| TV input HDMI 4 | 18 | `InputHDMI4` |

To change the layout, edit the `buttons[]` table in the sketch. Each line is just a pin, a key name, and whether it repeats when held. Other useful keys: `VolumeMute`, `InstantReplay`, `Backspace`, `Search`.

### TV input switching
Recent Roku OS versions can switch the TV's HDMI inputs over HDMI-CEC, and ECP accepts the `InputHDMI1`–`InputHDMI4` keys on a Streambar even though Roku's ECP documentation still lists them as Roku TV-only. All four have been confirmed on a Streambar running Roku OS 16.0.4. Press **Home** to come back to the Roku. If your TV has fewer inputs, delete the extra lines from `buttons[]`.

### Pin notes
GPIO 2, 12 and 15 are ESP32 "strapping" pins that are read at power-up. They're fine for buttons, but holding one of those buttons while the board boots can cause odd startup behavior. Avoid GPIO 34–39 for buttons: they are input-only and have no internal pull-ups.

## Reference
Roku's External Control Protocol documentation: https://developer.roku.com/docs/developer-program/dev-tools/external-control-api.md
