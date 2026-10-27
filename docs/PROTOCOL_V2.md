# Protokol MQTT v2 & Panduan Migrasi Firmware

Versi aplikasi 2.0.0 mengubah cara aplikasi berkomunikasi dengan alat agar
**alat tidak bisa dikendalikan oleh pihak lain**. Firmware ESP32 perlu
disesuaikan sebelum dipakai bersama aplikasi v2.

## Ringkasan perubahan

| Aspek | v1 (lama) | v2 (baru) |
|---|---|---|
| Topik status | `alburdat/status` (sama untuk semua alat) | `ferticore/<DEVICE_ID>/status` |
| Topik perintah | `alburdat/command` | `ferticore/<DEVICE_ID>/command` |
| Broker | Tetap di kode: `broker.emqx.io:1883` | Diatur pengguna di aplikasi |
| Enkripsi | Tidak ada (TCP polos) | TLS bawaan (8883 / WSS 8084) |
| Autentikasi | Tidak ada | Username/password broker (opsional, disarankan) |
| Perintah | `{"set_dosis": 15}` | `{"set_dosis": 15, "id": "a1b2…", "ts": 1730000000000}` |
| Konfirmasi | Tidak ada | Alat mengirim `ack` = id perintah pada status berikutnya |
| Batas dosis | Tidak divalidasi | 5–50 g, divalidasi aplikasi (firmware juga wajib) |

## DEVICE_ID

- 4–32 karakter: `A–Z a–z 0–9 - _`. Tidak boleh mengandung `/ + #`.
- Gunakan ID unik & sulit ditebak, mis. `FC-7Q2K9`, cetak di label alat dan
  tampilkan di OLED saat boot.

## Payload

### Status (alat → aplikasi), `ferticore/<ID>/status`

```json
{
  "gramasi": 15.0,
  "isMotorRunning": false,
  "totalVolume": 320.5,
  "totalSesi": 12,
  "rataRata": 26.7,
  "ack": "a1b2c3d4e5f60718"
}
```

- Kirim minimal tiap **10 detik** (aplikasi menganggap alat offline setelah 30 detik tanpa data).
- `ack` (opsional tetapi disarankan): `id` perintah terakhir yang berhasil dieksekusi.
  Kirim status segera setelah mengeksekusi perintah.
- Payload > 2 KB diabaikan aplikasi.

### Perintah (aplikasi → alat), `ferticore/<ID>/command`

```json
{ "id": "a1b2c3d4e5f60718", "ts": 1730000000000, "set_dosis": 15.0 }
{ "id": "…", "ts": …, "reset_stats": true }
{ "id": "…", "ts": …, "reset_wifi": true }
```

Kunci lama (`set_dosis`, `reset_stats`, `reset_wifi`) dipertahankan sehingga
parser lama tetap bekerja; `id` dan `ts` hanya tambahan.

## Yang wajib dilakukan firmware

1. Ganti topik ke `ferticore/<DEVICE_ID>/status|command`.
2. Validasi `set_dosis` di sisi alat: tolak di luar 5–50 g (jangan hanya mengandalkan aplikasi).
3. Simpan `id` 8–16 perintah terakhir; abaikan perintah dengan `id` yang sama (anti duplikasi/replay sederhana).
4. Setelah mengeksekusi perintah, publish status dengan `"ack": "<id>"`.
5. Koneksi ke broker dengan TLS (`WiFiClientSecure` + CA broker) dan username/password.
6. Ganti password AP konfigurasi `FERTICORE_CONFIG` dari nilai bawaan; tampilkan di OLED/label, bukan di aplikasi.

## Rekomendasi keamanan tambahan

- **Broker pribadi + ACL**: tiap alat hanya boleh publish ke `ferticore/<ID>/status` dan
  subscribe `ferticore/<ID>/command`; akun aplikasi hanya ke alat miliknya.
- Broker publik (`broker.emqx.io`) hanya untuk uji coba — siapa pun yang tahu ID alat dapat
  mengirim perintah walau sudah memakai TLS.
- Untuk tingkat lanjut: tanda tangan HMAC-SHA256 atas `id|ts|payload` dengan kunci per-alat,
  dan tolak `ts` yang berselisih > 60 detik dari jam alat (NTP).
