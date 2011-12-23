
/****************************************************	
 * sketch = MatrixMQTT
 *
 * Nottingham Hackspace
 * CC-BY-SA
 *
 * Source = http://wiki.nottinghack.org.uk/wiki/...
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
 * Large LED Matrix Display Board at 
 * Nottingham Hackspace and is part of the 
 * Hackspace Instrumentation Project
 *
 * 
 ****************************************************/

/*  
 History
    000 - Started 27/06/2011
 	001 - Initial release
	002 - changes to work with libary rewirte
	003 - changes to genric nh/status usage and added checkMQTT() 
	004 - adding temp dallas
 
 Known issues:
	All code is based on official Ethernet library not the nanode's ENC28J60, we need to port the MQTT PubSubClient
	
 
 Future changes:
 
 
 ToDo:
	Add Last Will and Testament
	
	
 Authors:
 'RepRap' Matt      dps.lwk at gmail.com
  John Crouchley    johng at crouchley.me.uk
 
 */

#define VERSION_NUM 004
#define VERSION_STRING "MatrixMQTT ver: 004"

// Uncomment for debug prints
#define DEBUG_PRINT

// Uncomment for LT1441M debug prints
//#define DEBUG_PRINT1


#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>
#include <LT1441M.h>			// Class for LT1441M
#include <OneWire.h>
#include <DallasTemperature.h>
#include "Config.h"

// function prototypes
void callbackMQTT(char*, byte*, int);
void printAddress(DeviceAddress deviceAddress);

// compile on holly need this befor callbackMQTT
LT1441M myMatrix(GSI, GAEO, LATCH, CLOCK, RAEO, RSI);
// compile on holly needs this after callbackMQTT
PubSubClient client(server, MQTT_PORT, callbackMQTT);
char pmsg[141];

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature dallas(&oneWire);

// Number of temperature devices found
int numberOfDevices;
// array to store found address
DeviceAddress tempAddress[10]; 

void callbackMQTT(char* topic, byte* payload, int length) {

  // handle message arrived
	if (!strcmp(S_RX, topic)) {
	// check for ***LWK***,
	if (strncmp(DISPLAY_STRING, (char*)payload, strlen(DISPLAY_STRING)) == 0) {
			// strip DISPLAY_STRING, send rest to Matrix
			//char msg[length - sizeof(DISPLAY_STRING) + 2];
			memset(pmsg, 0, 141);
			for(int i = 0; i < (length - strlen(DISPLAY_STRING)); i++) {
				pmsg[i] = (char)payload[i + sizeof(DISPLAY_STRING) -1];
			} // end for
	
			//myMatrix.clrScreen();
			myMatrix.selectFont(1,DEFAULT_FONT);
			myMatrix.setLine(1, pmsg, 1, 1, 0);
			
			
			// return msg that has been displayed 
			client.publish(P_TX, pmsg);
#ifdef DEBUG_PRINT
			Serial.print("Displayed Message: ");
			Serial.print(pmsg);
			Serial.print(" sizeof:");
			Serial.println(strlen(pmsg), DEC);
#endif
			
		} else if (strncmp(NICK_STRING, (char*)payload, strlen(NICK_STRING)) == 0) {
			// strip DISPLAY_STRING, send rest to Matrix
			//char msg[length - sizeof(NICK_STRING) + 2];
			memset(pmsg, 0, 141);
			for(int i = 0; i < (length - strlen(NICK_STRING)); i++) {
				pmsg[i] = (char)payload[i + sizeof(NICK_STRING) -1];
			} // end for
			
			//myMatrix.clrScreen();
			myMatrix.selectFont(0,DEFAULT_FONT);
			myMatrix.setLine(0, pmsg, 1, 0, 1);
			
			
			// return msg that has been displayed 
			client.publish(P_TX, pmsg);
#ifdef DEBUG_PRINT
			Serial.print("Displayed Nick: ");
			Serial.print(pmsg);
			Serial.print(" sizeof nick:");
			Serial.println(strlen(pmsg), DEC);
#endif
			
		} else if (strcmp(CLRSCREEN_STRING, (char*)payload) <= 0) {
			if (length > strlen(CLRSCREEN_STRING)) {
				// stript out which line to clear
				//myMatrix.clrLine(line);
			} else {
				myMatrix.clrLine(0);
				myMatrix.clrLine(1);
				myMatrix.clrLine(2);
				myMatrix.clrScreen();
				
				// return mag to say screen cleard
				client.publish(P_TX, CLRSCREEN_DONE_STRING);
#ifdef DEBUG_PRINT
				Serial.println("Screen Cleared");
#endif
			}
	// } else if (strncmp(XXX, (char*)payload, sizeof(XXX)) == 0) {
		} else {
		  // send the whole payload to 
		  
		}// end if else
	} else  if (!strcmp(S_STATUS, topic)) {
		// check for Status request,
		if (strncmp(STATUS_STRING, (char*)payload, strlen(STATUS_STRING)) == 0) {
#ifdef DEBUG_PRINT
			Serial.println("Status Request");
#endif
			client.publish(P_STATUS, RUNNING);
		} // end if
	} // end if else
  
} // end void callback(char* topic, byte* payload,int length)

/**************************************************** 
 * check we are still connected to MQTT
 * reconnect if needed
 *  
 ****************************************************/
void checkMQTT()
{
  	if(!client.connected()){
		if (client.connect(CLIENT_ID)) {
			client.publish(P_STATUS, RESTART);
			client.subscribe(S_RX);
			client.subscribe(S_STATUS);
#ifdef DEBUG_PRINT
			Serial.println("MQTT Reconect");
#endif
		} // end if
	} // end if
} // end checkMQTT()

/**************************************************** 
 * Poll 
 *  
 ****************************************************/
void poll()
{

} // end void poll()


/**************************************************** 
 * bufferNumber
 * tweaked from print.cpp to buffer ascii in pmsg
 * and pushed stright out over mqtt
 ****************************************************/
uint8_t bufferNumber(unsigned long n, uint8_t base, uint8_t p)
{
	unsigned char buf[8 * sizeof(long)]; // Assumes 8-bit chars. 
	unsigned long i = 0;
	
	if (n == 0) {
		pmsg[p++] = '0';
		return p;
	} 
	
	while (n > 0) {
		buf[i++] = n % base;
		n /= base;
	}
	
	for (; i > 0; i--) 
    pmsg[p++] = (char) (buf[i - 1] < 10 ?
				  '0' + buf[i - 1] :
				  'A' + buf[i - 1] - 10);
	
	return p;
} // end void bufferNumber(unsigned long n, uint8_t base, uint8_t *p)

/**************************************************** 
 * bufferNumber
 * tweaked from print.cpp to buffer ascii in pmsg
 * and pushed stright out over mqtt
 ****************************************************/
uint8_t bufferFloat(double number, uint8_t digits, uint8_t p) 
{ 
	// Handle negative numbers
	if (number < 0.0)
	{
		pmsg[p++] = '-';
		number = -number;
	}
	
	// Round correctly so that print(1.999, 2) prints as "2.00"
	double rounding = 0.5;
	for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
	
	number += rounding;
	
	// Extract the integer part of the number and print it
	unsigned long int_part = (unsigned long)number;
	double remainder = number - (double)int_part;
	p = bufferNumber(int_part, 10, p);
	
	// Print the decimal point, but only if there are digits beyond
	if (digits > 0)
		pmsg[p++] = '.';
	
	// Extract digits from the remainder one at a time
	while (digits-- > 0)
	{
		remainder *= 10.0;
		int toPrint = int(remainder);
		p = bufferNumber(toPrint, 10, p);
		remainder -= toPrint; 
	} 
	return p;
} // end void bufferFloat(double number, uint8_t digits, uint8_t *p) 


/**************************************************** 
 * getTemps
 * grabs all the temps from the dallas devices
 * and pushed stright out over mqtt
 ****************************************************/
void getTemps()
{
	if ( (millis() - tempTimeout) > TEMPREATURE_TIMEOUT ) {
		tempTimeout = millis();
		dallas.requestTemperatures(); // Send the command to get temperatures
		
		for (int i=0; i < numberOfDevices; i++) {
			// build mqtt message in pmsg[] buffer, address:temp
			memset(pmsg, 0, 141);
			uint8_t p = 0;
			
			// address to pmsg first
			for(int j=0; j < 8; j++) {
				if (tempAddress[i][j] < 16)
					pmsg[p++] = '0';
				p = bufferNumber(tempAddress[i][j], 16, p);
			} 
			
			// seprator char
			pmsg[p++] = ':';
			
			// copy float to ascii char array
			p = bufferFloat(dallas.getTempC(tempAddress[i]), 2, p);
			
			// push each stright out via mqtt
			client.publish(P_TEMP_STATUS, pmsg);
#ifdef DEBUG_PRINT
			Serial.print("Temp sent: ");
			Serial.println(pmsg);
#endif
		}
	}
	
} // end void getTemps()

void findSensors() 
{
	// locate devices on the bus
#ifdef DEBUG_PRINT
	Serial.print("Locating devices...");
#endif
	// Grab a count of devices on the wire
	numberOfDevices = dallas.getDeviceCount();
	
#ifdef DEBUG_PRINT    
	Serial.print("Found ");
	Serial.print(numberOfDevices, DEC);
	Serial.println(" devices.");
#endif

	// Loop through each device, store address
	for(int i=0;i<numberOfDevices; i++)
	{
		// Search the wire for address
		if(dallas.getAddress(tempAddress[i], i))
		{
#ifdef DEBUG_PRINT
			Serial.print("Found device ");
			Serial.print(i, DEC);
			Serial.print(" with address: ");
			printAddress(tempAddress[i]);
			Serial.println();
			
			Serial.print("Setting resolution to ");
			Serial.println(TEMPERATURE_PRECISION, DEC);
#endif
			// set the resolution to TEMPERATURE_PRECISION bit (Each Dallas/Maxim device is capable of several different resolutions)
			dallas.setResolution(tempAddress[i], TEMPERATURE_PRECISION);
			
#ifdef DEBUG_PRINT
			Serial.print("Resolution actually set to: ");
			Serial.print(dallas.getResolution(tempAddress[i]), DEC); 
			Serial.println();
#endif
		}else{
#ifdef DEBUG_PRINT
			Serial.print("Found ghost device at ");
			Serial.print(i, DEC);
			Serial.print(" but could not detect address. Check power and cabling");
#endif
		}
	}
	
	
} // end void findSensors()

// function to print a device address
void printAddress(DeviceAddress deviceAddress)
{
	for (uint8_t i = 0; i < 8; i++) {
#ifdef DEBUG_PRINT
	if (deviceAddress[i] < 16) Serial.print("0");
		Serial.print(deviceAddress[i], HEX);
#endif
	}
} // end void printAdress()

void setup()
{
	// Start Serial
	Serial.begin(9600);
	Serial.println(VERSION_STRING);
	
	// Start ethernet
	Ethernet.begin(mac, ip);
  
	// Setup Pins
	pinMode(GROUND, OUTPUT);

	// Set default output's
	digitalWrite(GROUND, LOW);

	
	// Start matrix and display version
	myMatrix.begin();  
	myMatrix.selectFont(0,Tekton); 
	myMatrix.setLine(0,VERSION_STRING,1,1); //default font is goin to cause issue here
	myMatrix.loop();
	myMatrix.enable();
	
	// start the one wire bus and dallas stuff
	dallas.begin();
	findSensors();
	
	// Start MQTT and say we are alive
	if (client.connect(CLIENT_ID)) {
		client.publish(P_STATUS, RESTART);
		client.subscribe(S_RX);
		client.subscribe(S_STATUS);
	}
	
	// let everything else settle
	delay(100);
	
} // end void setup()


void loop()
{
	
	// Poll 
	//poll();
	
	// Poll MQTT
	// should cause callback if theres a new message
	client.loop();
	
	// Scroll display, Push new frame
	myMatrix.loop();
	
	// Get Latest Temps
	getTemps();
	
	// are we still connected to MQTT
	checkMQTT();
	
} // end void loop()

