#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "DHT.h"

// --- MAPPING HARDWARE ---
#define PIN_PM25 34       // Potentiometer 1 simulates PM2.5 Sensor
#define PIN_CO2 35        // Potentiometer 2 simulates CO2 Sensor
#define PIN_DHT 15        // Temperature Sensor
#define PIN_ALARM_LED 4   // Red LED
#define PIN_FAN_LED 5     // Green LED

// --- CONSTANTS (From your Assembly Logic) ---
#define PM_SAFE_LIMIT 75
#define PM_HAZARD_LIMIT 150
#define CO2_SAFE_LIMIT 1000
#define CO2_HAZARD_LIMIT 2000

// Initialize Hardware
LiquidCrystal_I2C lcd(0x27, 20, 4); // 20 chars, 4 lines
DHT dht(PIN_DHT, DHT22);

void setup() {
  Serial.begin(115200);
  
  // Setup Pins
  pinMode(PIN_ALARM_LED, OUTPUT);
  pinMode(PIN_FAN_LED, OUTPUT);
  pinMode(PIN_PM25, INPUT);
  pinMode(PIN_CO2, INPUT);

  // Start Screen and Sensors
  lcd.init();
  lcd.backlight();
  dht.begin();

  // Intro Screen (Matches your Assembly Header)
  lcd.setCursor(0, 0);
  lcd.print("SMART AIR MONITORING");
  lcd.setCursor(0, 1);
  lcd.print("SDG 3: Good Health");
  lcd.setCursor(0, 2);
  lcd.print("System Initializing...");
  delay(2000);
  lcd.clear();
}

void loop() {
  // --- STEP 1: READ SENSORS (Simulated Hardware) ---
  
  // Read Temperature from DHT22
  float temp = dht.readTemperature();
  
  // Read PM2.5 from Potentiometer (Map 0-4095 input to 0-300 ug/m3)
  int raw_pm = analogRead(PIN_PM25);
  int pm25 = map(raw_pm, 0, 4095, 0, 300);

  // Read CO2 from Potentiometer (Map 0-4095 input to 400-3000 ppm)
  int raw_co2 = analogRead(PIN_CO2);
  int co2 = map(raw_co2, 0, 4095, 400, 3000);

  // --- STEP 2: LOGIC CLASSIFICATION (Same as Assembly) ---
  
  String pmStatus = "SAFE";
  if (pm25 >= PM_HAZARD_LIMIT) pmStatus = "HAZARD";
  else if (pm25 >= PM_SAFE_LIMIT) pmStatus = "MODERATE";

  String co2Status = "SAFE";
  if (co2 >= CO2_HAZARD_LIMIT) co2Status = "HAZARD";
  else if (co2 >= CO2_SAFE_LIMIT) co2Status = "MODERATE";

  // --- STEP 3: UPDATE DISPLAY ---
  // We treat the LCD like the memory mapped IO in your project
  
  lcd.setCursor(0, 0);
  lcd.print("T:" + String(temp, 1) + "C ");
  lcd.print("PM2.5:" + String(pm25));
  
  lcd.setCursor(0, 1);
  lcd.print("CO2: " + String(co2) + " ppm");

  lcd.setCursor(0, 2);
  lcd.print("ST: " + pmStatus + " / " + co2Status);

  // --- STEP 4: ACTUATORS (LEDs) ---
  
  lcd.setCursor(0, 3);
  
  // Alarm Logic: If ANY sensor is HAZARDOUS -> ALARM ON
  if (pmStatus == "HAZARD" || co2Status == "HAZARD") {
    digitalWrite(PIN_ALARM_LED, HIGH); // Turn Red LED ON
    lcd.print("ALARM: ON  ");
  } else {
    digitalWrite(PIN_ALARM_LED, LOW);  // Turn Red LED OFF
    lcd.print("ALARM: OFF ");
  }

  // Fan Logic: If PM is MOD/HAZ or CO2 is MOD/HAZ -> FAN ON
  if (pmStatus != "SAFE" || co2Status != "SAFE") {
    digitalWrite(PIN_FAN_LED, HIGH); // Turn Green Fan LED ON
    lcd.print("FAN: ON ");
  } else {
    digitalWrite(PIN_FAN_LED, LOW);
    lcd.print("FAN: OFF");
  }

  delay(500); // Update speed
}