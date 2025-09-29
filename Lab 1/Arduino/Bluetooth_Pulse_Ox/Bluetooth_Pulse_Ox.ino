/*
 This example sketch gives you exactly what the SparkFun Pulse Oximiter and
 Heart Rate Monitor is designed to do: read heart rate and blood oxygen levels.
 This board requires I-squared-C connections but also connections to the reset
 and mfio pins. When using the device keep LIGHT and CONSISTENT pressure on the
 sensor. Otherwise you may crush the capillaries in your finger which results
 in bad or no results. A summary of the hardware connections are as follows: 
 SDA -> SDA
 SCL -> SCL
 RESET -> PIN 4
 MFIO -> PIN 5

 Author: Elias Santistevan
 Date: 8/2019
 SparkFun Electronics

 If you run into an error code check the following table to help diagnose your
 problem: 
 1 = Unavailable Command
 2 = Unavailable Function
 3 = Data Format Error
 4 = Input Value Error
 5 = Try Again
 255 = Error Unknown
*/

#include <ArduinoJson.h>
#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

// Reset pin, MFIO pin
int resPin = 7;
int mfioPin = 6;
const int Buzzer = 10;

// Takes address, reset pin, and MFIO pin.
SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin); 

bioData body;  
// ^^^^^^^^^
// body.heartrate  - Heartrate
// body.confidence - Confidence in the heartrate value
// body.oxygen     - Blood oxygen level
// body.status     - Has a finger been sensed?

// void sendData(string Data){
// /*
// +1+1+1
// DATA
// +2+2+2

// */


// }

//buzzer helper //TODO BROKEN
void beepTwice() {
  tone(Buzzer, 1200, 200);  // 1.2 kHz for 200 ms
  delay(260);               // small gap so calls don’t overlap
  tone(Buzzer, 1200, 200);
  delay(220);
  noTone(Buzzer);
}

//if buzzer   is active
// void beepTwice() {
//   digitalWrite(Buzzer, HIGH); delay(200);
//   digitalWrite(Buzzer, LOW);  delay(260);
//   digitalWrite(Buzzer, HIGH); delay(200);
//   digitalWrite(Buzzer, LOW);
// }

void setup(){

  Serial.begin(115200);


  
  Wire.begin();
  int result = bioHub.begin();  
  if (result == 0) // Zero errors!
    Serial.println("Sensor started!");
  else
    Serial.println("Could not communicate with the sensor!");
 
  Serial.println("Configuring Sensor...."); 
  int error = bioHub.configBpm(MODE_ONE); // Configuring just the BPM settings. 
  if(error == 0){ // Zero errors!
    Serial.println("Sensor configured.");
  }
  else {
    Serial.println("Error configuring sensor.");
    Serial.print("Error: "); 
    Serial.println(error); 
  }

  // Data lags a bit behind the sensor, if you're finger is on the sensor when
  // it's being configured this delay will give some time for the data to catch
  // up. 
  Serial.println("Loading up the buffer with data....");
  delay(4000); 
  
  // Set baseline (read for 30s average your heart rate )
  body = bioHub.readBpm();
  int avgSect = 0;
  int i = 0;

  pinMode(Buzzer, OUTPUT);
  // tone(Buzzer, 85);
  // delay(1000);
  // noTone(Buzzer);

//   while(body.status == 3 && i <= 30){
//     body.heartRate;
// // reading the sensor
//   }
}

int period_ms = 0;
int heartRate = 0;

void loop(){
    JsonDocument doc;
    // Information from the readBpm function will be saved to our "body"
    // variable.  
    body = bioHub.readBpm();
    doc["HR"] = body.heartRate;
    doc["Conf"] = body.confidence;
    doc["Stat"] = body.status;
    doc["SpO2"] = body.oxygen;
    serializeJson(doc, Serial);
    Serial.println("");

  // listen for a command from Processing and beep twice when requested
  while (Serial.available() > 0) {
    int c = Serial.read();
    if(c == 'b' || c == 'B'){
      beepTwice();
    }
  }

// small pacing delay
delay(500);

    
    //   tone(Buzzer, 10000);
    //   // digitalWrite(Buzzer, HIGH);
    // delay(1000);
    //   // digitalWrite(Buzzer, LOW);

    // noTone(Buzzer);
    // delay(500); 
}
