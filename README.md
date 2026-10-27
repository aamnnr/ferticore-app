# FERTICORE AI — Dashboard Alat Tabur Pupuk Presisi

Aplikasi Flutter (Android, iOS, Web, Desktop) untuk memantau dan mengendalikan
alat tabur pupuk presisi berbasis ESP32 melalui MQTT, dilengkapi sistem pakar
rekomendasi dosis.

> **Versi 2.0** — refaktor arsitektur, keamanan koneksi, desain UI baru, dan
> panduan di dalam aplikasi. Firmware perlu disesuaikan: lihat
> **[docs/PROTOCOL_V2.md](docs/PROTOCOL_V2.md)**.

## Fitur

- **Beranda** — dosis aktif, status motor & alat, metrik penggunaan, status
  koneksi/keamanan, dan checklist "Langkah pemupukan".
- **Rekomendasi** — sistem pakar (13 komoditas, NPK/Urea) menghitung dosis per
  tanaman dan total kebutuhan; dosis di luar kemampuan alat (5–50 g) diblokir
  dengan penjelasan.
- **Kontrol** — atur dosis manual (±, slider, preset, ketik) dengan lembar
  konfirmasi dan **konfirmasi balik dari alat** (ack).
- **Statistik** — total volume, rata-rata, sesi, grafik selama sesi, reset
  statistik terkonfirmasi.
- **Pengaturan** — koneksi broker (TLS, username/password tersimpan terenkripsi),
  reset WiFi alat, panduan, hapus data koneksi.
- **Panduan dalam aplikasi** — onboarding saat pertama dibuka, halaman panduan
  yang bisa dicari, FAQ pemecahan masalah, dan tombol (?) kontekstual di setiap
  halaman.

## Keamanan (ringkas)

| Masalah di v1 | Perbaikan di v2 |
|---|---|
| Broker publik tanpa login, topik global `alburdat/command` — siapa pun bisa mengirim perintah | Broker dapat diatur, TLS bawaan, username/password, topik per-alat `ferticore/<ID>/…` |
| ID/topik bisa disusupi wildcard | ID divalidasi (`A–Z 0–9 - _`, 4–32) |
| Password AP `petanisukses` tertulis di aplikasi | Dihapus; dibaca dari label/OLED alat |
| Payload status dipercaya mentah | Parsing defensif, batas 2 KB, nilai negatif/NaN dinormalkan |
| Dosis tanpa batas, tanpa konfirmasi | Validasi 5–50 g, lembar konfirmasi, ack dari alat, satu perintah sekaligus + rate limit |
| Perintah bisa diputar ulang | `id` acak (CSPRNG) + `ts` pada setiap perintah |
| Kredensial/payload di log | Log hanya di mode debug; password di Keystore/Keychain; Android `allowBackup=false` |

## Menjalankan

```bash
flutter pub get
```

```bash
flutter test
```

```bash
flutter run
```

Saat pertama dibuka, ikuti onboarding lalu isi **ID alat** dan broker di
*Pengaturan → Koneksi alat*.

## Struktur

```
lib/
├── main.dart, app.dart          # entry point, providers, onboarding gate
├── core/
│   ├── config/app_config.dart   # konstanta (batas dosis, timeout, dll.)
│   ├── theme/app_theme.dart     # token desain: warna, jarak, radius, tema
│   └── utils/                   # validators, formatters, logger
├── data/
│   ├── knowledge_base.dart      # basis pengetahuan sistem pakar
│   ├── models/                  # agronomy, device_status, device_command, broker_config
│   └── repositories/            # settings_repository (prefs + secure storage)
├── services/
│   ├── expert_system_service.dart
│   └── mqtt/                    # device_service + client factory (io/web)
├── features/
│   ├── shell/                   # AppShell + navigasi mengambang
│   ├── home/ recommendation/ control/ stats/ settings/
│   └── guide/                   # konten panduan, halaman panduan, onboarding
└── widgets/                     # komponen UI yang dipakai ulang
test/                            # unit test sistem pakar, model, validator, controller
```

**Menambah komoditas**: cukup tambah entri di `commodities` dan `doseRules`
pada `lib/data/knowledge_base.dart` (aturan terurut naik, mulai HST 0).

**Mengubah teks panduan**: `lib/features/guide/guide_content.dart`.

## Dokumentasi lain

- [docs/PROTOCOL_V2.md](docs/PROTOCOL_V2.md) — protokol MQTT v2 & migrasi firmware
- Dokumen lama di `docs/` (USER_GUIDE, ARCHITECTURE, API_REFERENCE, dll.)
  menjelaskan arsitektur v1 dan dipertahankan sebagai referensi historis.
