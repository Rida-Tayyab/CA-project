#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include "DHT.h"

// --- MAPPING HARDWARE ---
#define PIN_PM25 34       // Potentiometer 1 simulates PM2.5 Sensor (or actual PM2.5 sensor)
#define PIN_PM10 33       // Potentiometer 2 simulates PM10 Sensor
#define PIN_CO 35         // Potentiometer 3 simulates CO Sensor (MQ-7) or actual MQ-7
#define PIN_NO2 32        // Potentiometer 4 simulates NO2 Sensor (MQ-135)
#define PIN_O3 39         // Potentiometer 5 simulates O3 Sensor
#define PIN_SO2 36        // Potentiometer 6 simulates SO2 Sensor (MQ-136)
#define PIN_DHT 15        // DHT22 Sensor (Temperature + Humidity)
#define PIN_ALARM_LED 4   // Red LED - Alarm
#define PIN_FAN_LED 5     // Green LED - Fan
#define PIN_VENT_LED 2    // Blue LED - Ventilation

// --- CONSTANTS (From your Assembly Logic) ---
#define PM_SAFE_LIMIT 75
#define PM_HAZARD_LIMIT 150
#define PM10_SAFE_LIMIT 50     // PM10 safe: < 50 µg/m³
#define PM10_HAZARD_LIMIT 100 // PM10 hazardous: >= 100 µg/m³
#define CO_SAFE_LIMIT 50      // CO safe: < 50 ppm
#define CO_HAZARD_LIMIT 200   // CO hazardous: >= 200 ppm
#define NO2_SAFE_LIMIT 100    // NO2 safe: < 100 µg/m³
#define NO2_HAZARD_LIMIT 200  // NO2 hazardous: >= 200 µg/m³
#define O3_SAFE_LIMIT 100     // O3 safe: < 100 µg/m³
#define O3_HAZARD_LIMIT 200   // O3 hazardous: >= 200 µg/m³
#define SO2_SAFE_LIMIT 50     // SO2 safe: < 50 µg/m³
#define SO2_HAZARD_LIMIT 150  // SO2 hazardous: >= 150 µg/m³
#define TEMP_LOW_LIMIT 20     // Temperature low threshold: < 20 C
#define TEMP_HIGH_LIMIT 30    // Temperature high threshold: >= 30 C
#define HUMIDITY_LOW_LIMIT 30 // Humidity low threshold: < 30%
#define HUMIDITY_HIGH_LIMIT 70 // Humidity high threshold: >= 70%

// Initialize Hardware
LiquidCrystal_I2C lcd(0x27, 20, 4); // 20 chars, 4 lines
DHT dht(PIN_DHT, DHT22);

void setup() {
  Serial.begin(115200);
  
  // Setup Pins
  pinMode(PIN_ALARM_LED, OUTPUT);
  pinMode(PIN_FAN_LED, OUTPUT);
  pinMode(PIN_VENT_LED, OUTPUT);
  pinMode(PIN_PM25, INPUT);
  pinMode(PIN_PM10, INPUT);
  pinMode(PIN_CO, INPUT);
  pinMode(PIN_NO2, INPUT);
  pinMode(PIN_O3, INPUT);
  pinMode(PIN_SO2, INPUT);

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
  
  // Read Temperature and Humidity from DHT22
  float temp = dht.readTemperature();
  float humidity = dht.readHumidity();
  
  // Check if readings are valid (DHT22 may return NaN)
  if (isnan(temp) || isnan(humidity)) {
    temp = 25.0;  // Default fallback
    humidity = 50.0;
  }
  
  // Read PM2.5 from Potentiometer (Map 0-4095 input to 0-300 ug/m3)
  // User can manually adjust potentiometer to test different values
  int raw_pm = analogRead(PIN_PM25);
  int pm25 = map(raw_pm, 0, 4095, 0, 300);

  // Read PM10 from Potentiometer (Map 0-4095 input to 0-200 ug/m3)
  int raw_pm10 = analogRead(PIN_PM10);
  int pm10 = map(raw_pm10, 0, 4095, 0, 200);

  // Read CO from Potentiometer (Map 0-4095 input to 0-300 ppm)
  // For MQ-7: analogRead returns 0-4095, map to 0-300 ppm
  // User can manually adjust potentiometer to test different values
  int raw_co = analogRead(PIN_CO);
  int co = map(raw_co, 0, 4095, 0, 300);

  // Read NO2 from Potentiometer (Map 0-4095 input to 0-300 ug/m3)
  int raw_no2 = analogRead(PIN_NO2);
  int no2 = map(raw_no2, 0, 4095, 0, 300);

  // Read O3 from Potentiometer (Map 0-4095 input to 0-300 ug/m3)
  int raw_o3 = analogRead(PIN_O3);
  int o3 = map(raw_o3, 0, 4095, 0, 300);

  // Read SO2 from Potentiometer (Map 0-4095 input to 0-200 ug/m3)
  int raw_so2 = analogRead(PIN_SO2);
  int so2 = map(raw_so2, 0, 4095, 0, 200);

  // --- STEP 2: LOGIC CLASSIFICATION (Same as Assembly) ---
  
  // PM2.5 Classification
  String pmStatus = "SAFE";
  if (pm25 >= PM_HAZARD_LIMIT) pmStatus = "HAZARD";
  else if (pm25 >= PM_SAFE_LIMIT) pmStatus = "MODERATE";

  // PM10 Classification
  String pm10Status = "SAFE";
  if (pm10 >= PM10_HAZARD_LIMIT) pm10Status = "HAZARD";
  else if (pm10 >= PM10_SAFE_LIMIT) pm10Status = "MODERATE";

  // CO Classification
  String coStatus = "SAFE";
  if (co >= CO_HAZARD_LIMIT) coStatus = "HAZARD";
  else if (co >= CO_SAFE_LIMIT) coStatus = "MODERATE";

  // NO2 Classification
  String no2Status = "SAFE";
  if (no2 >= NO2_HAZARD_LIMIT) no2Status = "HAZARD";
  else if (no2 >= NO2_SAFE_LIMIT) no2Status = "MODERATE";

  // O3 Classification
  String o3Status = "SAFE";
  if (o3 >= O3_HAZARD_LIMIT) o3Status = "HAZARD";
  else if (o3 >= O3_SAFE_LIMIT) o3Status = "MODERATE";

  // SO2 Classification
  String so2Status = "SAFE";
  if (so2 >= SO2_HAZARD_LIMIT) so2Status = "HAZARD";
  else if (so2 >= SO2_SAFE_LIMIT) so2Status = "MODERATE";

  // Temperature Classification
  String tempStatus = "SAFE";
  if (temp >= TEMP_HIGH_LIMIT) tempStatus = "HAZARD";
  else if (temp < TEMP_LOW_LIMIT) tempStatus = "MODERATE";

  // Humidity Classification
  String humidityStatus = "SAFE";
  if (humidity >= HUMIDITY_HIGH_LIMIT) humidityStatus = "HAZARD";
  else if (humidity < HUMIDITY_LOW_LIMIT) humidityStatus = "MODERATE";

  // --- STEP 3: UPDATE DISPLAY ---
  // We treat the LCD like the memory mapped IO in your project
  
  lcd.setCursor(0, 0);
  lcd.print("PM:" + String(pm25) + " CO:" + String(co));
  
  lcd.setCursor(0, 1);
  lcd.print("T:" + String(temp, 1) + "C H:" + String(humidity, 0) + "%");

  lcd.setCursor(0, 2);
  lcd.print("PM:" + pmStatus + " CO:" + coStatus);

  // --- STEP 4: ACTUATORS (LEDs) ---
  
  lcd.setCursor(0, 3);
  
  // Alarm Logic: If ANY sensor is HAZARDOUS -> ALARM ON
  if (pmStatus == "HAZARD" || pm10Status == "HAZARD" || coStatus == "HAZARD" || 
      no2Status == "HAZARD" || o3Status == "HAZARD" || so2Status == "HAZARD" ||
      tempStatus == "HAZARD" || humidityStatus == "HAZARD") {
    digitalWrite(PIN_ALARM_LED, HIGH); // Turn Red LED ON
    lcd.print("ALARM:ON ");
  } else {
    digitalWrite(PIN_ALARM_LED, LOW);  // Turn Red LED OFF
    lcd.print("ALARM:OFF");
  }

  // Fan Logic: If PM is MODERATE or HAZARDOUS -> FAN ON
  if (pmStatus != "SAFE") {
    digitalWrite(PIN_FAN_LED, HIGH); // Turn Green Fan LED ON
  } else {
    digitalWrite(PIN_FAN_LED, LOW);
  }

  // Ventilation Logic: If CO is MOD/HAZ or Humidity is HIGH or Temp is HIGH -> VENT ON
  if (coStatus != "SAFE" || humidityStatus == "HAZARD" || tempStatus == "HAZARD") {
    digitalWrite(PIN_VENT_LED, HIGH); // Turn Blue Ventilation LED ON
  } else {
    digitalWrite(PIN_VENT_LED, LOW);
  }

  // Serial output for debugging and manual input override (optional)
  Serial.print("PM2.5:"); Serial.print(pm25);
  Serial.print(" PM10:"); Serial.print(pm10);
  Serial.print(" CO:"); Serial.print(co);
  Serial.print(" NO2:"); Serial.print(no2);
  Serial.print(" O3:"); Serial.print(o3);
  Serial.print(" SO2:"); Serial.print(so2);
  Serial.print(" T:"); Serial.print(temp, 1);
  Serial.print(" H:"); Serial.print(humidity, 1);
  Serial.print(" | ALARM:"); Serial.print(pmStatus == "HAZARD" || pm10Status == "HAZARD" || coStatus == "HAZARD" || no2Status == "HAZARD" || o3Status == "HAZARD" || so2Status == "HAZARD" || tempStatus == "HAZARD" || humidityStatus == "HAZARD" ? "ON" : "OFF");
  Serial.print(" FAN:"); Serial.print(pmStatus != "SAFE" ? "ON" : "OFF");
  Serial.print(" VENT:"); Serial.println(coStatus != "SAFE" || humidityStatus == "HAZARD" || tempStatus == "HAZARD" ? "ON" : "OFF");

  delay(500); // Update speed
}