/*
@Title  ESP32-WROOM-32 Roku Remote (v2)
@Author Mike Gierhart
@Date   May 6th, 2023 (v1) / October 2026 (v2)

@Hardware Conceivably any ESP32 dev board would work

v2 changes:
  - Finds the Roku automatically (SSDP discovery) -- no IP address to configure.
    The last-known IP is saved in flash, and discovery re-runs if the Roku moves.
  - HDMI input switching buttons (InputHDMI1..4, confirmed on a Roku OS 16 Streambar).
  - Wi-Fi credentials live in secrets.h so they never get committed to GitHub.
  - Non-blocking debounce; arrows and volume auto-repeat while held.
  - Reconnects to Wi-Fi automatically if the router drops.
*/

#include <WiFi.h>
#include <WiFiUdp.h>
#include <HTTPClient.h>
#include <Preferences.h>

// Copy secrets.example.h to secrets.h and fill in your network.
// secrets.h is listed in .gitignore so your password stays off GitHub.
#include "secrets.h"

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

// Optional: if there's more than one Roku on the network, put this one's serial
// number here (Settings > System > About, or /query/device-info). Leave "" to
// use the first Roku that answers.
const char* ROKU_SERIAL = "";

const uint32_t DEBOUNCE_MS        = 30;   // switch must be stable this long
const uint32_t REPEAT_DELAY_MS    = 500;  // hold this long before auto-repeat starts
const uint32_t REPEAT_INTERVAL_MS = 150;  // then repeat this often
const uint32_t DISCOVERY_WAIT_MS  = 3000; // how long to listen for Roku replies

// Each button: GPIO pin, ECP key name, and whether it auto-repeats when held.
// Buttons wire from the pin to GND (internal pull-ups are enabled).
// Full key list: https://developer.roku.com/docs/developer-program/dev-tools/external-control-api.md
struct Button {
  uint8_t     pin;
  const char* key;
  bool        repeats;
  // runtime state
  bool        lastRaw;
  bool        pressed;
  uint32_t    changedAt;
  uint32_t    nextRepeatAt;
};

Button buttons[] = {
  // Original v1 wiring -- unchanged, so existing builds keep working.
  {23, "Up",         true},
  {21, "Down",       true},
  { 4, "Left",       true},
  { 5, "Right",      true},
  {15, "Select",     false},
  {26, "Home",       false},  // also returns the TV to the Roku from another input
  {25, "Back",       false},
  {32, "Play",       false},
  {33, "Rev",        false},
  {27, "Fwd",        false},
  {14, "VolumeUp",   true},
  {12, "VolumeDown", true},
  { 2, "PowerOff",   false},
  {19, "Info",       false},

  // New in v2: TV input switching over HDMI-CEC. Change pins/inputs to match
  // your TV, or delete lines you don't need. Other options: InputTuner, InputAV1.
  {13, "InputHDMI1", false},
  {16, "InputHDMI2", false},
  {17, "InputHDMI3", false},
  {18, "InputHDMI4", false},
};
const size_t NUM_BUTTONS = sizeof(buttons) / sizeof(buttons[0]);

// ---------------------------------------------------------------------------
// Roku discovery and ECP
// ---------------------------------------------------------------------------

Preferences prefs;
IPAddress   rokuIP;          // 0.0.0.0 until discovered
bool        haveRoku = false;

void saveRokuIP() {
  prefs.putString("ip", rokuIP.toString());
}

// Ask the network "any Rokus out there?" (SSDP M-SEARCH, ST: roku:ecp) and take
// the first reply that matches ROKU_SERIAL (or any reply if it's blank).
bool discoverRoku() {
  if (WiFi.status() != WL_CONNECTED) return false;
  Serial.println("Searching for Roku...");

  WiFiUDP udp;
  udp.begin(1901);
  const char* msearch =
    "M-SEARCH * HTTP/1.1\r\n"
    "Host: 239.255.255.250:1900\r\n"
    "Man: \"ssdp:discover\"\r\n"
    "ST: roku:ecp\r\n"
    "MX: 2\r\n"
    "\r\n";

  String serial = String(ROKU_SERIAL);
  serial.toLowerCase();

  uint32_t start = millis();
  uint32_t lastSend = 0;
  bool found = false;
  char buf[512];

  while (!found && millis() - start < DISCOVERY_WAIT_MS) {
    // UDP can drop packets, so re-send the search once a second.
    if (lastSend == 0 || millis() - lastSend >= 1000) {
      udp.beginPacket(IPAddress(239, 255, 255, 250), 1900);
      udp.write((const uint8_t*)msearch, strlen(msearch));
      udp.endPacket();
      lastSend = millis();
    }

    int len = udp.parsePacket();
    if (len > 0) {
      int n = udp.read(buf, sizeof(buf) - 1);
      buf[n > 0 ? n : 0] = '\0';
      String reply(buf);
      reply.toLowerCase();
      // Replies carry "USN: uuid:roku:ecp:<SERIAL>"
      if (reply.indexOf("roku:ecp") >= 0 &&
          (serial.length() == 0 || reply.indexOf(serial) >= 0)) {
        rokuIP = udp.remoteIP();
        found = true;
      }
    }
    delay(10);
  }
  udp.stop();

  if (found) {
    haveRoku = true;
    saveRokuIP();
    Serial.print("Found Roku at ");
    Serial.println(rokuIP);
  } else {
    Serial.println("No Roku found. Is it on the same network?");
  }
  return found;
}

// POST to an ECP path (e.g. "/keypress/Home"). Returns the HTTP status code,
// or a negative number if the Roku couldn't be reached at all.
int ecpPost(const String& path) {
  HTTPClient http;
  http.setConnectTimeout(1000);
  http.setTimeout(1500);
  if (!http.begin("http://" + rokuIP.toString() + ":8060" + path)) return -1;
  int code = http.POST("");
  http.end();
  return code;
}

void sendKey(const char* key) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Not on Wi-Fi yet; key ignored.");
    return;
  }
  if (!haveRoku && !discoverRoku()) return;

  String path = String("/keypress/") + key;
  int code = ecpPost(path);

  // Couldn't connect: the Roku probably got a new IP. Find it and try once more.
  if (code < 0) {
    Serial.println("Roku not answering at saved address; rediscovering.");
    if (discoverRoku()) code = ecpPost(path);
  }

  Serial.printf("%s -> %d\n", key, code);
  if (code == 403) {
    Serial.println("Roku refused the command. On the Roku, set Settings > System >"
                   " Advanced system settings > Control by mobile apps to Enabled.");
  }
}

// ---------------------------------------------------------------------------
// Wi-Fi
// ---------------------------------------------------------------------------

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);          // modem sleep adds noticeable button lag
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.print("\nConnected, ESP32 IP: ");
  Serial.println(WiFi.localIP());
}

void maintainWiFi() {
  static uint32_t lastAttempt = 0;
  if (WiFi.status() == WL_CONNECTED) return;
  if (millis() - lastAttempt < 10000) return;
  lastAttempt = millis();
  Serial.println("WiFi lost; reconnecting...");
  WiFi.reconnect();
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

void pollButtons() {
  uint32_t now = millis();
  for (size_t i = 0; i < NUM_BUTTONS; i++) {
    Button& b = buttons[i];
    bool raw = digitalRead(b.pin) == LOW;  // LOW = pressed (pull-up)

    if (raw != b.lastRaw) {
      b.lastRaw = raw;
      b.changedAt = now;
    }

    if (now - b.changedAt >= DEBOUNCE_MS && raw != b.pressed) {
      b.pressed = raw;
      if (b.pressed) {
        sendKey(b.key);
        b.nextRepeatAt = millis() + REPEAT_DELAY_MS;
      }
    } else if (b.pressed && b.repeats && (int32_t)(now - b.nextRepeatAt) >= 0) {
      sendKey(b.key);
      b.nextRepeatAt = millis() + REPEAT_INTERVAL_MS;
    }
  }
}

// ---------------------------------------------------------------------------

void setup() {
  Serial.begin(115200);

  for (size_t i = 0; i < NUM_BUTTONS; i++) {
    pinMode(buttons[i].pin, INPUT_PULLUP);
    buttons[i].lastRaw = buttons[i].pressed = false;
    buttons[i].changedAt = buttons[i].nextRepeatAt = 0;
  }

  connectWiFi();

  // Start from the last Roku we found, if any; sendKey() rediscovers if it moved.
  prefs.begin("roku", false);
  String saved = prefs.getString("ip", "");
  if (saved.length() && rokuIP.fromString(saved)) {
    haveRoku = true;
    Serial.print("Using saved Roku address ");
    Serial.println(rokuIP);
  } else {
    discoverRoku();
  }
}

void loop() {
  maintainWiFi();
  pollButtons();
  delay(5);
}
