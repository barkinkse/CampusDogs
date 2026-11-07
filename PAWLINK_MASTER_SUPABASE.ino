
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <time.h>
#include <NimBLEDevice.h>

// =====================================
// SUPABASE KOK SERTIFIKASI
// =====================================

const char* SUPABASE_ROOT_CA = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAwVzELMAkGA1UEBhMCQkUx
GTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNVBAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkds
b2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNV
BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYD
VQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDa
DuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6arymAZavpxy0Sy6sc
THAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCOXkNz8kHp1Wrjsok6Vjk4bwY8iGlb
Kk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6TRGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNP
c1STE4U6G7weNLWLBYy5d4ux2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrX
gzT/LCrBbBlDSgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUF
AAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoRSLblCKOzyj1hTdNGCbM+w6Dj
Y1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQLcFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyG
j/8N7yy5Y0b2qvzfvGn9LhJIZJrglfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhH
hm4qxFYxldBniYUr+WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveC
X4XSQRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4A==
-----END CERTIFICATE-----
)EOF";

// =====================================
// PAWLINK AYARLARI
// =====================================

#define SERVICE_UUID "9f8c1000-6d2b-4baf-9e81-62f4d09c0001"
#define STATUS_UUID  "9f8c1001-6d2b-4baf-9e81-62f4d09c0001"
#define TARGET_DOG   "DOG-001"

// Kendi guncel bilgilerini burada doldur.
// Bunlari sohbet veya GitHub uzerinde paylasma.
const char* WIFI_SSID = "M.Halil'in iPhone'u";
const char* WIFI_PASSWORD = "Muhammed12";
const char* DEVICE_KEY = "af9795dd7d79e69e4fc205f86fcae425e503d207d395fcabe261958d0c9410c5";

// Son basarili testte calisan adres korunuyor.
const char* SUPABASE_URL =
  "https://aiihwhpgfrnevpnudahp.supabase.co/functions/v1/smart-task?collar_id=DOG-001";

const unsigned long POLL_INTERVAL = 15000UL;

unsigned long lastPoll = 0;
unsigned long lastWifiLog = 0;

int lastSentStatus = -1;
bool previousWifiConnected = false;
bool clockReady = false;

NimBLEScan* bleScan = nullptr;

// =====================================
// BELLEK
// =====================================

void printMemory(const char* stage) {
  Serial.print(stage);
  Serial.print(" | BOS HEAP: ");
  Serial.print(ESP.getFreeHeap());
  Serial.print(" | EN BUYUK BLOK: ");
  Serial.println(ESP.getMaxAllocHeap());
}

// =====================================
// SAAT SENKRONIZASYONU
// =====================================

bool syncClock() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }

  Serial.println("NTP SAAT SENKRONIZASYONU");

  configTime(
    0,
    0,
    "pool.ntp.org",
    "time.google.com"
  );

  struct tm timeinfo;

  if (!getLocalTime(&timeinfo, 10000)) {
    Serial.println("SAAT SENKRONIZASYONU BASARISIZ");
    return false;
  }

  Serial.println("SAAT SENKRONIZASYONU BASARILI");
  Serial.print("UTC TARIH/SAAT: ");
  Serial.println(&timeinfo, "%Y-%m-%d %H:%M:%S");

  return true;
}

// =====================================
// SUPABASE BITMASK OKUMA
// =====================================

bool fetchSupabaseStatus(uint8_t &status) {

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("SUPABASE: WIFI BAGLI DEGIL");
    return false;
  }

  if (!clockReady) {
    clockReady = syncClock();

    if (!clockReady) {
      Serial.println("SUPABASE: SAAT HAZIR DEGIL");
      return false;
    }
  }

  Serial.println();
  Serial.println("SUPABASE DURUM SORGULANIYOR");

  WiFiClientSecure secureClient;
  secureClient.setCACert(SUPABASE_ROOT_CA);
  secureClient.setHandshakeTimeout(15);

  HTTPClient http;
  http.setTimeout(15000);

  if (!http.begin(secureClient, SUPABASE_URL)) {
    Serial.println("SUPABASE HTTPS BASLATILAMADI");
    return false;
  }

  http.addHeader("x-device-key", DEVICE_KEY);

  int httpCode = http.GET();

  Serial.print("SUPABASE HTTP KODU: ");
  Serial.println(httpCode);

  if (httpCode != 200) {

    if (httpCode > 0) {
      Serial.print("SUPABASE HATA YANITI: ");
      Serial.println(http.getString());
    } else {
      Serial.print("HTTP BAGLANTI HATASI: ");
      Serial.println(http.errorToString(httpCode));
    }

    http.end();
    return false;
  }

  // JSON yanitini baglanti acikken oku.
  String response = http.getString();
  http.end();

  JsonDocument doc;
  DeserializationError error =
      deserializeJson(doc, response);

  if (error) {
    Serial.println("SUPABASE JSON OKUMA HATASI");
    return false;
  }

  const char* collarId = doc["collar_id"] | "";

  if (strcmp(collarId, TARGET_DOG) != 0) {
    Serial.println("SUPABASE: COLLAR ID UYUSMUYOR");
    return false;
  }

  if (!doc["bitmask"].is<int>()) {
    Serial.println("SUPABASE: BITMASK BULUNAMADI");
    return false;
  }

  int value = doc["bitmask"].as<int>();

  if (value < 0 || value > 63) {
    Serial.println("SUPABASE: GECERSIZ BITMASK");
    return false;
  }

  status = (uint8_t)value;

  Serial.print("SUPABASE BITMASK: ");
  Serial.println(status);

  return true;
}

// =====================================
// NIMBLE ILE TASMAYA DURUM GONDER
// =====================================

bool sendStatus(uint8_t status) {

  if (bleScan == nullptr) {
    Serial.println("BLE tarayici hazir degil.");
    return false;
  }

  Serial.println("Tasma araniyor...");

  NimBLEScanResults results =
      bleScan->getResults(5000, false);

  bool found = false;
  NimBLEAddress targetAddress;

  for (int i = 0; i < results.getCount(); i++) {

    const NimBLEAdvertisedDevice* device =
        results.getDevice(i);

    if (device == nullptr ||
        !device->haveManufacturerData()) {
      continue;
    }

    std::string data = device->getManufacturerData();

    if (data.length() < 3) {
      continue;
    }

    if ((uint8_t)data[0] != 0xFF ||
        (uint8_t)data[1] != 0xFF) {
      continue;
    }

    std::string dogId = data.substr(2);

    if (dogId == TARGET_DOG) {

      found = true;
      targetAddress = device->getAddress();

      Serial.print("Tasma bulundu: ");
      Serial.println(TARGET_DOG);

      Serial.print("RSSI: ");
      Serial.println(device->getRSSI());

      break;
    }
  }

  bleScan->clearResults();

  if (!found) {
    Serial.println("DOG-001 bulunamadi.");
    return false;
  }

  NimBLEClient* client =
      NimBLEDevice::createClient();

  if (client == nullptr) {
    Serial.println("BLE istemcisi olusturulamadi.");
    return false;
  }

  Serial.println("Tasmaya baglaniliyor...");

  if (!client->connect(targetAddress)) {
    Serial.println("BLE baglanti hatasi!");
    NimBLEDevice::deleteClient(client);
    return false;
  }

  NimBLERemoteService* service =
      client->getService(SERVICE_UUID);

  if (service == nullptr) {
    Serial.println("Servis bulunamadi!");
    client->disconnect();
    NimBLEDevice::deleteClient(client);
    return false;
  }

  NimBLERemoteCharacteristic* characteristic =
      service->getCharacteristic(STATUS_UUID);

  if (characteristic == nullptr ||
      !characteristic->canWrite()) {

    Serial.println("Yazilabilir karakteristik yok!");

    client->disconnect();
    NimBLEDevice::deleteClient(client);
    return false;
  }

  uint8_t payload[1] = {status};

  bool written = characteristic->writeValue(
    payload,
    sizeof(payload),
    true
  );

  if (written) {
    Serial.print("GONDERILEN DURUM: ");
    Serial.println(status);
  } else {
    Serial.println("BLE yazma basarisiz.");
  }

  client->disconnect();
  NimBLEDevice::deleteClient(client);

  Serial.println("BLE baglantisi kapatildi.");

  return written;
}

// =====================================
// SETUP
// =====================================

void setup() {

  Serial.begin(115200);
  Serial.setTimeout(100);
  delay(1000);

  Serial.println();
  Serial.println("PAWLINK MASTER - OTOMATIK SISTEM");

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Hotspot baglantisi bekleniyor");

  unsigned long wifiStart = millis();

  while (
    WiFi.status() != WL_CONNECTED &&
    millis() - wifiStart < 20000UL
  ) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("WIFI BAGLANDI | IP: ");
    Serial.println(WiFi.localIP());

    clockReady = syncClock();
  } else {
    Serial.println("WIFI HENUZ BAGLANMADI");
  }

  previousWifiConnected =
      (WiFi.status() == WL_CONNECTED);

  printMemory("NIMBLE ONCESI");

  NimBLEDevice::init("PAWLINK-MASTER");

  bleScan = NimBLEDevice::getScan();

  bleScan->setActiveScan(true);
  bleScan->setInterval(100);
  bleScan->setWindow(80);

  printMemory("NIMBLE SONRASI");

  Serial.println();
  Serial.println("PAWLINK MASTER READY");
  Serial.println("OTOMATIK SUPABASE KONTROLU AKTIF");
  Serial.println("MANUEL KOMUT: 0-63");

  // Ilk sorguyu loop icinde hemen baslat.
  lastPoll = millis() - POLL_INTERVAL;
}

// =====================================
// LOOP
// =====================================

void loop() {

  bool wifiConnected =
      (WiFi.status() == WL_CONNECTED);

  if (wifiConnected != previousWifiConnected) {

    previousWifiConnected = wifiConnected;

    if (wifiConnected) {
      Serial.print("WIFI BAGLANDI | IP: ");
      Serial.println(WiFi.localIP());

      // Baglanti geri geldiyse saat kontrolu yap.
      clockReady = syncClock();

      // Sonraki sorguyu bekletme.
      lastPoll = millis() - POLL_INTERVAL;

    } else {
      Serial.println("WIFI BAGLANTISI KESILDI");
      clockReady = false;
    }
  }

  if (millis() - lastWifiLog >= 10000UL) {

    lastWifiLog = millis();

    if (wifiConnected) {

      Serial.print("WIFI AKTIF | IP: ");
      Serial.print(WiFi.localIP());

      Serial.print(" | RSSI: ");
      Serial.println(WiFi.RSSI());

    } else {
      Serial.println("WIFI BAGLANTISI YOK");
    }
  }

  // =====================================
  // OTOMATIK SUPABASE -> BLE
  // =====================================

  if (
    wifiConnected &&
    millis() - lastPoll >= POLL_INTERVAL
  ) {

    lastPoll = millis();

    uint8_t newStatus = 0;

    if (fetchSupabaseStatus(newStatus)) {

      if (lastSentStatus != (int)newStatus) {

        Serial.print("YENI DURUM: ");
        Serial.println(newStatus);

        bool success = sendStatus(newStatus);

        if (success) {

          lastSentStatus = newStatus;

          Serial.println(
            "OTOMATIK BLE GONDERIM BASARILI"
          );

        } else {

          Serial.println(
            "BLE GONDERIM BASARISIZ - TEKRAR DENENECEK"
          );
        }

      } else {

        Serial.println(
          "DURUM DEGISMEDI - BLE GONDERIMI GEREKMIYOR"
        );
      }

    } else {

      Serial.println(
        "SUPABASE OKUMA BASARISIZ - TEKRAR DENENECEK"
      );
    }
  }

  // =====================================
  // MANUEL SERIAL GONDERIM
  // =====================================

  if (Serial.available()) {

    String input =
        Serial.readStringUntil('\n');

    input.trim();

    if (input.length() == 0) {
      return;
    }

    bool valid = true;

    for (int i = 0; i < input.length(); i++) {
      if (!isDigit(input[i])) {
        valid = false;
        break;
      }
    }

    int value = input.toInt();

    if (!valid || value < 0 || value > 63) {
      Serial.println("HATA: 0-63 arasi sayi gir.");
      return;
    }

    Serial.print("Komut alindi: ");
    Serial.println(value);

    bool success =
        sendStatus((uint8_t)value);

    if (success) {
      // Manuel gonderim otomatik durumla da uyumlu kalsin.
      lastSentStatus = value;

      Serial.println("BLE yazma islemi tamamlandi.");
    } else {
      Serial.println("Gonderim basarisiz.");
    }
  }
}
