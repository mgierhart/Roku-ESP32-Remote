/*
@Title ESP32-WROOM-32 Roku Remote
@Author Mike Gierhart
@Date May 6th, 2023

@Hardware Conceivably any ESP32 dev board would work
*/

#include <WiFi.h>
#include <WiFiClient.h>

//Define Wifi login and Roku's IP on the internal network--match the Roku IP to the one found in your Roku's settings
const char* ssid = "YOUR_SSID_HERE";
const char* password ="YOUR_WIFI_PASSWORD_HERE";
const char* rokuIP = "ROKU_IP_ON_LOCAL_NETWORK";

// Define the pins for the buttons
int UPPin = 23;
int DOWNPin = 21;
int LEFTPin = 4;
int RIGHTPin = 5;
int SELECTPin = 15;
int HOMEPin = 26;
int BACKPin = 25;
int PLAYPin = 32;
int REVPin = 33;
int FWDPin = 27;
int VOLUMEUPPin = 14;
int VOLUMEDOWNPin = 12;
int POWEROFFPin = 2;
int INFOPin = 19;

//Roku-specific wifi stuff
WiFiClient client;

void sendCommand(String command) {
  if (client.connect(rokuIP, 8060)) {
    client.print("POST /keypress/");
    client.print(command);
    client.println(" HTTP/1.1");
    client.print("Host: ");
    client.println(rokuIP);
    client.println("Content-Length: 0");
    client.println();
    client.stop();
  }
}

//enable pullup resistor for each pin
void setup() {
  Serial.begin(115200);
  pinMode(UPPin, INPUT_PULLUP);
  pinMode(DOWNPin, INPUT_PULLUP);
  pinMode(LEFTPin, INPUT_PULLUP);
  pinMode(RIGHTPin, INPUT_PULLUP);
  pinMode(SELECTPin, INPUT_PULLUP);
  pinMode(HOMEPin, INPUT_PULLUP);
  pinMode(BACKPin, INPUT_PULLUP);
  pinMode(PLAYPin, INPUT_PULLUP);
  pinMode(REVPin, INPUT_PULLUP);
  pinMode(FWDPin, INPUT_PULLUP);
  pinMode(VOLUMEUPPin, INPUT_PULLUP);
  pinMode(VOLUMEDOWNPin, INPUT_PULLUP);
  pinMode(POWEROFFPin, INPUT_PULLUP);
  pinMode(INFOPin, INPUT_PULLUP);

//login to wifi with the const char variables defined above
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi!");
}

//commands sent by buttons to Roku; I set each button to have a delay(100) so I'd have variables to mess with if needed, then a global delay(50) at the end just because
void loop() {
  if (digitalRead(UPPin) == LOW) {
    delay(100);
    sendCommand("Up");
  }
  if (digitalRead(DOWNPin) == LOW) {
    delay(100);
    sendCommand("Down");
  }
  if (digitalRead(LEFTPin) == LOW) {
    delay(100);
    sendCommand("Left");
  }
  if (digitalRead(RIGHTPin) == LOW) {
    delay(100);
    sendCommand("Right");
  }
  if (digitalRead(SELECTPin) == LOW) {
    delay(100);
    sendCommand("Select");
  }
  if (digitalRead(HOMEPin) == LOW) {
    delay(100);
    sendCommand("Home");
  }
  if (digitalRead(BACKPin) == LOW) {
    delay(100);
    sendCommand("Back");
  }
  if (digitalRead(PLAYPin) == LOW) {
    delay(100);
    sendCommand("Play");
  }
  if (digitalRead(REVPin) == LOW) {
    delay(100);
    sendCommand("Rev");
  }
  if (digitalRead(FWDPin) == LOW) {
    delay(100);
    sendCommand("Fwd");
  }
  if (digitalRead(VOLUMEUPPin) == LOW) {
    delay(100);
    sendCommand("VolumeUp");
  }
  if (digitalRead(VOLUMEDOWNPin) == LOW) {
    delay(100);
    sendCommand("VolumeDown");
  }
  if (digitalRead(POWEROFFPin) == LOW) {
    delay(100);
    sendCommand("PowerOff");
  }
  if (digitalRead(INFOPin) == LOW) {
    delay(100);
    sendCommand("Info");
  }
  delay(200);
}
