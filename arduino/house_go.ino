#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <DHT.h>

#define TRIG_PIN 5
#define ECHO_PIN 18
#define SERVO_DOOR_PIN 13
#define SERVO_WINDOW_PIN 12
#define LDR_PIN 34
#define RAIN_SENSOR_PIN 35
#define DHT_PIN 14
#define EXTERNAL_LIGHT_PIN 15
#define INTERNAL_LIGHT1_PIN 2
#define INTERNAL_LIGHT2_PIN 4
#define HEATING_LED_PIN 16
#define BUTTON_PIN 17
#define MOTION_SENSOR_PIN 27
#define AC_HEAT_PIN 25
#define AC_COOL_PIN 26

// Configuration WiFi
const char* ssid = "inconu";
const char* password = "123456788";

WebServer server(80);

// Objets
Servo doorServo;
Servo windowServo;
DHT dht(DHT_PIN, DHT11);

// Variables globales
int ultrasonicDistance = 0;
int sunLevel = 0;
int rainLevel = 0;
int batteryLevel = 100;
int tempLevel = 100;
int humidLevel = 100;
bool doorStatus = false;
bool windowStatus = false;
bool intruderStatus = false;
bool alarmStatus = false;

void setup() {
  Serial.begin(115200);

  // Configuration des broches
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LDR_PIN, INPUT);
  pinMode(RAIN_SENSOR_PIN, INPUT);
  pinMode(EXTERNAL_LIGHT_PIN, OUTPUT);
  pinMode(INTERNAL_LIGHT1_PIN, OUTPUT);
  pinMode(INTERNAL_LIGHT2_PIN, OUTPUT);
  pinMode(HEATING_LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(MOTION_SENSOR_PIN, INPUT);
  pinMode(AC_HEAT_PIN, OUTPUT);
  pinMode(AC_COOL_PIN, OUTPUT);

  // Initialisation des servomoteurs
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  doorServo.setPeriodHertz(50);
  windowServo.setPeriodHertz(50);
  doorServo.attach(SERVO_DOOR_PIN, 500, 2400);
  windowServo.attach(SERVO_WINDOW_PIN, 500, 2400);

  // Initialisation du capteur DHT
  dht.begin();

  // Connexion WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connexion au WiFi...");
  }
  Serial.printf("Connecté au WiFi %s\n", ssid);
  Serial.print("Adresse IP: ");
  Serial.println(WiFi.localIP());

  // Configuration des routes du serveur web
  server.on("/datasend", HTTP_GET, handleDataSend);
  server.on("/datarecived", HTTP_POST, handleDataReceived);

  server.begin();
}

void loop() {
  server.handleClient();

  // Lecture des capteurs
  readSensors();

  // Logique de contrôle automatique
  automaticControl();

  delay(100);
}

void readSensors() {
  // Lecture du capteur ultrasonique
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  ultrasonicDistance = pulseIn(ECHO_PIN, HIGH) * 0.034 / 2;

  // Lecture du capteur de luminosité
  sunLevel = analogRead(LDR_PIN);

  // Lecture du capteur de pluie
  rainLevel = analogRead(RAIN_SENSOR_PIN);

  // Lecture du capteur de mouvement
  intruderStatus = digitalRead(MOTION_SENSOR_PIN);

  // Simulation de la lecture de la batterie
  batteryLevel = random(60, 100);
  tempLevel = random(26, 29);
  humidLevel = random(1, 5);
}

void automaticControl() {
  // Contrôle de la porte basé sur le capteur ultrasonique
  if (ultrasonicDistance < 20 && !doorStatus) {
    openDoor();
  } else if (ultrasonicDistance >= 40 && doorStatus) {
    closeDoor();
  }

  // Contrôle de la lumière extérieure basé sur la luminosité
  if (sunLevel > 500) {
    digitalWrite(EXTERNAL_LIGHT_PIN, HIGH);
  } else {
    digitalWrite(EXTERNAL_LIGHT_PIN, LOW);
  }

  // Contrôle de la fenêtre basé sur le capteur de pluie
  if (rainLevel > 500 && windowStatus) {
    closeWindow();
  }

  // Gestion de l'alarme (la nuit)
  if (sunLevel > 200 && intruderStatus) {
    alarmStatus = true;
  } else {
    alarmStatus = false;
  }
}

void openDoor() {
  doorServo.write(100);
  doorStatus = true;
}

void closeDoor() {
  delay(2000);
  doorServo.write(0);
  doorStatus = false;
}

void openWindow() {
  windowServo.write(90);
  windowStatus = true;
}

void closeWindow() {
  windowServo.write(0);
  windowStatus = false;
}

void handleDataSend() {
  StaticJsonDocument<512> doc;

  doc["humidity"] = humidLevel;
  doc["temperature"] = tempLevel;
  doc["ultrasonsDist"] = ultrasonicDistance;
  doc["sunLevel"] = sunLevel;
  doc["rainLevel"] = rainLevel;
  doc["led1"] = digitalRead(INTERNAL_LIGHT1_PIN);
  doc["led2"] = digitalRead(INTERNAL_LIGHT2_PIN);
  doc["chofage"] = digitalRead(HEATING_LED_PIN);
  doc["battLevel"] = batteryLevel;
  doc["WindowStatu"] = windowStatus;
  doc["dorStatus"] = doorStatus;
  doc["intruStatus"] = intruderStatus;

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleDataReceived() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    StaticJsonDocument<512> doc;
    DeserializationError error = deserializeJson(doc, body);

    if (error) {
      server.send(400, "text/plain", "Invalid JSON");
      return;
    }

    // Traitement des données reçues
    if (doc.containsKey("led1")) {
      digitalWrite(INTERNAL_LIGHT1_PIN, doc["led1"].as<int>());
    }
    if (doc.containsKey("led2")) {
      digitalWrite(INTERNAL_LIGHT2_PIN, doc["led2"].as<int>());
    }
    if (doc.containsKey("chofage")) {
      int acStatus = doc["chofage"].as<int>();
      if (acStatus == 1) {
        digitalWrite(AC_HEAT_PIN, HIGH);
        digitalWrite(AC_COOL_PIN, LOW);
      } else if (acStatus == -1) {
        digitalWrite(AC_HEAT_PIN, LOW);
        digitalWrite(AC_COOL_PIN, HIGH);
      } else {
        digitalWrite(AC_HEAT_PIN, LOW);
        digitalWrite(AC_COOL_PIN, LOW);
      }
    }
    if (doc.containsKey("dorStatus")) {
      bool newDoorStatus = doc["dorStatus"].as<bool>();
      if (newDoorStatus != doorStatus) {
        newDoorStatus ? openDoor() : closeDoor();
      }
    }
    if (doc.containsKey("WindowStatu")) {
      bool newWindowStatus = doc["WindowStatu"].as<bool>();
      if (newWindowStatus != windowStatus) {
        newWindowStatus ? openWindow() : closeWindow();
      }
    }

    server.send(200, "text/plain", "Data received and processed");
  } else {
    server.send(400, "text/plain", "No data received");
  }
}