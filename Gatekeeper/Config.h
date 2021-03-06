/****************************************************	
 * sketch = Gatekeeper
 *
 * Nottingham Hackspace
 * CC-BY-SA
 *
 * Source = http://wiki.nottinghack.org.uk/wiki/Gatekeeper
 * Target controller = Arduino 328 (Nanode v5)
 * Clock speed = 16 MHz
 * Development platform = Arduino IDE 0022
 * C compiler = WinAVR from Arduino IDE 0022
 * 
 * 
 * This code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 *
 * Gatekeeper is the access control system at 
 * Nottingham Hackspace and is part of the 
 * Hackspace Instrumentation Project
 *
 * 
 ****************************************************/

/*
  These are the global config parameters for Gatekeeper
  Including Pin Outs, IP's, TimeOut's etc
  
  Arduino Wiznet sheild uses pings 10, 11, 12, 13 for the ethernet
  Nanode v5 uses pins 8, 11, 12, 13 for the ethernet
  
*/


// Update these with values suitable for your network.
byte mac[]    = {  0xDE, 0xED, 0xBA, 0xFE, 0xFE, 0xED }; // ***LWK*** should randomise this, or use nanode on chip mac, if we have pins :/ and code
// Gatekeeper's Reserved IP
byte ip[]     = { 192, 168, 0, 10 }; 

// Display is a 20x2 character LCD
#define LCD_X 20
#define LCD_Y 2

// Door Bell Relay
// Volt Free switching
// ***LWK*** use pin 10 for nanode v5 or pin 8 for wiznet, dont forget to move soldered line on the proto sheild (needs a jumper)
#define DOOR_BELL 8 
#define DOOR_BELL_LENGTH 250


// Door Bell Button
// HIGH = PUSHED
// Interrupt PIN
#define DOOR_BUTTON 3
// timeout in mills for how often the doorbell can be rang
#define DOOR_BUTTON_TIMEOUT 5000
unsigned long doorTimeOut = 0;
uint8_t doorButtonState = 0;
bool doorLocked = false;

// Status Indicator's 
// BLUE = UNLOCKED
// RED = LOCKED
#define BLUE_LED 5
#define RED_LED 6

// Magnetic Door Contact
#define MAG_CON 9
#define CLOSED HIGH
#define OPEN LOW
boolean magConState = CLOSED;
#define MAG_CON_TIMEOUT 1000
unsigned long magTimeOut = 0;

// Magnetic Door Release
#define MAG_REL 4
#define UNLOCK HIGH
#define LOCK LOW
#define UNLOCK_STRING "Unlock:"
#define UNLOCK_DELIM ":"  

// timeout in millis for the how long the magnetic release will stay unlocked
#define MAG_REL_TIMEOUT 5000

// RFID module Serial 9600N1
#define RFID_TX 0
#define RFID_RX 1
// timeout in mills for how often the same card is read
#define CARD_TIMEOUT 3000
unsigned long cardTimeOut = 0;

// Keypad INT
#define KEYPAD A3
#define EEPROMRESET "EEReset"

// LCD
// timeout in mills for how long a msg is displayed
#define LCD_DEFAULT_0 "     Welcome to     "
#define LCD_DEFAULT_1 "Nottingham Hackspace"
#define LCD_TIMEOUT 5000
unsigned long lcdTimeOut = 0;
byte lcdState = 2;
#define DEFAULT 0
#define CUSTOM 1

//Speaker
#define SPEAKER A2

//Last Man Out
#define LAST_MAN A1
#define IN HIGH
#define OUT LOW
boolean lastManState = OUT;
boolean lastManStateOld = OUT;
boolean lastManStateSent = false;
#define LAST_MAN_TIMEOUT 15000
unsigned long lastManTimeOut = 0;

// MQTT 

// MQTT server on holly
byte server[] = { 192, 168, 0, 1 };
#define MQTT_PORT 1883

// ClientId for connecting to MQTT
#define CLIENT_ID "Gatekeeper"

// Subscribe to topics
#define S_UNLOCK		"nh/gk/1/Unlock"
#define S_DOOR_BELL          "nh/gk/bell/ComfyArea"

// Publish Topics
#define P_DOOR_STATE		"nh/gk/1/DoorState"
#define P_KEYPAD		"nh/gk/1/Keypad"
#define P_DOOR_BUTTON		"nh/gk/1/DoorButton"
#define P_RFID			"nh/gk/1/RFID"
#define P_LAST_MAN_STATE	"nh/gk/LastManState"

// Status Topic, use to say we are alive or DEAD (will)
#define S_STATUS "nh/status/req"
#define P_STATUS "nh/status/res"
#define STATUS_STRING "STATUS"
#define RUNNING "Running: Gatekeeper"
#define RESTART "Restart: Gatekeeper"

#define DOOR_STATE_NONE 0
#define DOOR_STATE_INNER 1
#define DOOR_STATE_OUTER 2
#define DOOR_STATE_REAR 3
#define DOOR_INNER "1"
#define DOOR_OUTER "2"
#define DOOR_REAR "3"


enum door_state_t
{
   DS_UNKNOWN,
   DS_OPEN,
   DS_CLOSED,
   DS_LOCKED,
   DS_FAULT
};







