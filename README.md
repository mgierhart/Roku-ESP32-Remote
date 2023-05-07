# Roku-ESP32-Remote
ESP32 Wifi Remote for Roku

This code was developed for an ESP32-WROOM-32 board in the Arduino IDE.  It's configured for my Roku Streambar to use the following buttons:
Up              = Pin 23
Down            = Pin 21
Left            = Pin  4
Right           = Pin  5
Select          = Pin 15
Home            = Pin 26
Back            = Pin 25
Play            = Pin 32
Rewind          = Pin 33
Fast Forward    = Pin 27
Volume Up       = Pin 14
Volume Down     = Pin 12
Power Off       = Pin  2

I wrote it for the 38 Pin Development board (https://raw.githubusercontent.com/AchimPieters/esp32-homekit-camera/master/Images/ESP32-38%20PIN-DEVBOARD.png) but it could be adapted for any ESP32 board.

Roku's External Control Protocol (ECP) API documentation can be found here:  https://developer.roku.com/docs/developer-program/dev-tools/external-control-api.md

Within the documentation you'll find options for other controls that I chose not to use in my project; these can easily be modified into the existing code.
