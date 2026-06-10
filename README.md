# FERTICORE AI (Alburdat Presisi) - Sistem Pupuk IoT Presisi

[![Flutter](https://img.shields.io/badge/Flutter-3.11.1+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![MQTT](https://img.shields.io/badge/MQTT-Secure%20(TLS/SSL)-3C82A6?style=for-the-badge&logo=mqtt&logoColor=white)](https://mqtt.org)

**FERTICORE AI (Alburdat Presisi)** adalah sistem IoT komersial terintegrasi untuk mengontrol dan memantau perangkat pemberi pupuk presisi berbasis mikrokontroler ESP32. Proyek dashboard Flutter ini dirancang sebagai pusat kendali multi-platform yang terhubung ke cloud database secara real-time dan berkomunikasi secara langsung ke perangkat fisik melalui protokol komunikasi MQTT yang aman.

---

## 📚 Hub Dokumentasi

### Untuk Pengguna Akhir (Petani / Operator)
- **[USER_GUIDE.md](docs/USER_GUIDE.md)** — Panduan instalasi fisik, konfigurasi WiFi, dan pengoperasian dashboard.

### Untuk Pengembang / Developer
- **[DOCUMENTATION_OVERVIEW.md](docs/DOCUMENTATION_OVERVIEW.md)** — Peta jalan panduan dan ringkasan seluruh berkas dokumentasi.
- **[QUICK_START.md](docs/QUICK_START.md)** — Mempersiapkan workspace dan menjalankan aplikasi dalam 15 menit ⚡
- **[SETUP.md](docs/SETUP.md)** — Konfigurasi lingkungan pengembangan (OS, SDK, flutter doctor).
- **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** — Pedoman gaya penulisan kode, penanganan state, dan kontribusi.
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** — Detail arsitektur sistem, aliran data, keamanan, dan integrasi hardware.
- **[API_REFERENCE.md](docs/API_REFERENCE.md)** — Struktur payload MQTT, skema tabel Supabase, dan routing HTTP.
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** — Panduan penanganan kegagalan koneksi, masalah pairing, dan error sistem.

---

## ✨ Fitur Utama Dashboard

- 🔐 **Autentikasi Pengguna Aman**: Pendaftaran dan login terenkripsi menggunakan layanan cloud **Supabase Auth**.
- 📱 **Manajemen Multi-Device (Pairing)**: Tambahkan dan kelola lebih dari satu perangkat tabur pupuk dalam satu akun pengguna.
- 📊 **Pemantauan Telemetri Real-time**: Visualisasi data live dari ESP32 (status motor, volume pupuk, gramasi aktif, sesi tabur, dan rata-rata dosis).
- 🧠 **Sistem Rekomendasi AI Agronomi**: Perhitungan otomatis dosis optimal berdasarkan jenis tanaman, umur tanaman (Hari Setelah Tanam / HST), dan basis pengetahuan keahlian agronomi.
- ⚙️ **Kontrol Dosis Manual Presisi**: Penyesuaian dosis secara instan melalui slider atau input numerik dengan respons kilat via MQTT.
- 📷 **QR Code Scanner**: Pendaftaran perangkat baru super praktis menggunakan scanner QR camera bawaan aplikasi (`mobile_scanner`).
- 🌐 **Onboarding & WiFi Provisioning**: Panduan langkah demi langkah untuk mengonfigurasi WiFi lokal perangkat ESP32 secara nirkabel langsung dari HP.

---

## 🏗️ Arsitektur Sistem & Aliran Data

```
┌────────────────────────────────────────────────────────┐
│               FERTICORE AI Flutter App                 │
│      (Android, iOS, Web, Windows, macOS, Linux)        │
└────────────┬──────────────────────────────┬────────────┘
             │                               │
             │ HTTPS / WebSockets            │ Secure MQTT (Port 8883)
             │ (Otentikasi & Database)       │ (Telemetri & Kontrol Instan)
┌────────────▼────────────┐        ┌─────────▼────────────┐
│      Cloud Backend      │        │      MQTT Broker     │
│   (Supabase Database)   │        │ (HiveMQ / EMQX TLS)  │
└─────────────────────────┘        └─────────┬────────────┘
                                             │
                                             │ WiFi / TCP
                                   ┌─────────▼────────────┐
                                   │  ESP32 Ferticore AP  │
                                   │ (DC Motor & Sensors) │
                                   └──────────────────────┘
```

### Stack Teknologi Aplikasi:
- **Core Framework**: Flutter 3.11.1+ (Dart SDK)
- **State Management**: `Provider` (Pendekatan reaktif dan modular)
- **Cloud Gateway**: `Supabase Flutter SDK` (Auth & Real-time Database dengan skema RLS yang aman)
- **Protokol Komunikasi**: Secure MQTT (TLS/SSL aktif, port 8883) via `mqtt_client`
- **Integrasi Hardware**: HTTP client (`http`) untuk provisioning dan `mobile_scanner` untuk QR-based setup.

---

## 📁 Struktur Direktori `lib/`

```
lib/
├── main.dart                      # Inisialisasi Supabase, Auth Gate, dan Entry Point
├── models/                        # Representasi struktur data (Strongly-typed Models)
│   ├── calculation_input.dart     # Parameter input rekomendasi dosis
│   ├── calculation_result.dart    # Output kalkulasi dosis AI
│   ├── commodity.dart             # Jenis tanaman/komoditas (Padi, Jagung, dll.)
│   ├── device_status.dart         # Status live perangkat (MAC, gramasi, motor, stats)
│   ├── fertilizer.dart            # Data referensi jenis pupuk
│   └── rule.dart                  # Aturan logika sistem pakar (HST → Dosis)
├── data/
│   └── knowledge_base.dart        # Kumpulan aturan & knowledge base sistem rekomendasi
├── services/                      # Logika bisnis dan integrasi API luar
│   ├── device_onboarding_service.dart # WiFi provisioning lokal & pendaftaran ke Supabase
│   ├── expert_system_service.dart # Mesin inferensi AI dosis agronomi presisi
│   └── mqtt_service.dart          # Penghubung, Listener, & Publisher data MQTT (TLS/SSL)
├── screens/                       # Halaman visual antarmuka pengguna (UI Screens)
│   ├── splash_screen.dart         # Halaman loading pembuka aplikasi
│   ├── login_screen.dart          # Gerbang otentikasi login & registrasi
│   ├── home_screen.dart           # Navigasi shell utama dashboard
│   ├── dashboard_page.dart        # Pemantau telemetri & dropdown pemilih perangkat aktif
│   ├── rekomendasi_page.dart      # Formulir rekomendasi dosis berbasis AI
│   ├── manual_page.dart           # Panel kontrol dosis manual slider & tombol
│   ├── add_device_screen.dart     # Aliran onboarding 5 langkah (QR Scan -> Provision -> Success)
│   ├── wifi_page.dart             # Reset koneksi WiFi perangkat aktif
│   └── info_page.dart             # Pengaturan akun, status MQTT/ESP32, & opsi logout
├── widgets/                       # Komponen antarmuka modular yang dapat digunakan kembali
└── theme/
    └── theme.dart                 # Konfigurasi Token Desain (warna, font, bentuk, border)
```

---

## 🔧 Dependensi Aktif

Berikut adalah daftar pustaka utama yang digunakan dalam pengembangan aplikasi ini (sesuai spesifikasi [pubspec.yaml](pubspec.yaml)):

| Pustaka | Versi | Fungsi / Kegunaan |
| :--- | :--- | :--- |
| **`supabase_flutter`** | `^2.4.0` | Otentikasi pengguna, sinkronisasi cloud, dan penyimpanan data perangkat aman. |
| **`mqtt_client`** | `^10.11.9` | Protokol pengiriman perintah instan dan penangkap telemetri real-time. |
| **`provider`** | `^6.1.1` | Pengelola status aplikasi terpusat (state management). |
| **`mobile_scanner`** | `^4.0.0` | Memindai stiker QR MAC Address untuk identifikasi cepat alat. |
| **`google_fonts`** | `^8.0.2` | Menyediakan antarmuka premium dengan tipografi *Plus Jakarta Sans*. |
| **`http`** | `^1.2.2` | Pengiriman data WiFi ke server web lokal ESP32 (`192.168.4.1`). |

---

## ⚡ Langkah Memulai (Panduan Cepat Developer)

### 1. Prasyarat Sistem
Pastikan komputer Anda telah terpasang:
- Flutter SDK (Versi `>=3.11.1`)
- Koneksi internet stabil untuk unduhan dependensi

### 2. Kloning Repository & Unduh Paket
```bash
# Kloning repositori proyek
git clone <repository-url>
cd alburdat_dashboard

# Unduh paket dependensi yang dideklarasikan
flutter pub get
```

### 3. Konfigurasi Kredensial Lingkungan (`secrets.json`)
Aplikasi ini membaca kredensial cloud secara aman pada compile-time. Pastikan Anda memiliki berkas `secrets.json` di root folder proyek Anda dengan format sebagai berikut:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1Ni...",
  "MQTT_BROKER": "<broker-address>.hivemq.cloud",
  "MQTT_PORT": "8883",
  "MQTT_USER": "nama_pengguna_mqtt",
  "MQTT_PASS": "sandi_aman_mqtt"
}
```

### 4. Menjalankan Aplikasi
Jalankan aplikasi di perangkat target (Web, Android, iOS, Windows, macOS) dengan mengaitkan konfigurasi `secrets.json` Anda:

```bash
# Menjalankan di Google Chrome (Web)
flutter run -d chrome --dart-define-from-file=secrets.json

# Menjalankan di Android/iOS/Desktop
flutter run --dart-define-from-file=secrets.json
```

---

## 🔌 Alur Onboarding Alat Baru

Untuk menghubungkan mesin tabur pupuk **FERTICORE** baru milik pengguna ke dashboard cloud:
1. **Pindai QR**: Masuk ke menu "Tambah Alat Baru" di aplikasi, lalu pindai kode QR fisik pada alat untuk mendapatkan `mac_address`.
2. **Koneksi AP**: Sambungkan WiFi ponsel Anda ke hotspot lokal yang dipancarkan alat (SSID: `FERTICORE_[4_angka_MAC]`, sandi default: `12345678`).
3. **Kirim WiFi**: Masukkan SSID & kata sandi WiFi rumah/kebun Anda di form aplikasi, lalu tekan "Sinkronisasi Alat". Aplikasi akan mengirimkan kredensial tersebut ke alat fisik via IP lokal `192.168.4.1`.
4. **Klaim Cloud**: Aplikasi secara otomatis mendaftarkan kepemilikan alat ke akun Supabase Anda secara aman. Alat kini siap dipantau dari manapun!

---

## 📊 Status Komponen Proyek

| Komponen | Status Layanan | Target Rilis / Versi |
| :--- | :--- | :--- |
| **Flutter Dashboard** | Stable / Production-Ready | `1.0.1` |
| **MQTT Gateway (TLS)** | Aktif / Terenkripsi | Port `8883` |
| **Supabase Cloud Layer** | Aktif / RLS Secures | Live Database |
| **ESP32 Firmware** | Repositori Terpisah | Kompatibel v1.0 |

---

**⭐ Sukses Mengembangkan Ferticore AI!**  
*Jika Anda menghadapi kesulitan atau menemukan bug selama pengembangan, silakan merujuk ke panduan [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) atau buat laporan pada tim kontributor.*

---
**Last Updated**: May 2026  
**Maintainer**: [Aamiin / Development Team]
