import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:flutter/material.dart';

/// Topik panduan. Dipakai tombol bantuan (?) di setiap halaman untuk
/// langsung membuka bagian yang relevan.
enum GuideTopic { quickStart, connection, home, recommendation, control, stats, deviceWifi, security, troubleshooting }

class GuideSection {
  const GuideSection({
    required this.topic,
    required this.title,
    required this.icon,
    required this.summary,
    this.steps = const [],
    this.tips = const [],
    this.warning,
  });

  final GuideTopic topic;
  final String title;
  final IconData icon;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final String? warning;

  /// Teks gabungan untuk pencarian.
  String get searchText => [title, summary, ...steps, ...tips, warning ?? ''].join(' ').toLowerCase();
}

class FaqItem {
  const FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

final String _min = AppConfig.minDeviceDose.toStringAsFixed(0);
final String _max = AppConfig.maxDeviceDose.toStringAsFixed(0);

final List<GuideSection> guideSections = [
  const GuideSection(
    topic: GuideTopic.quickStart,
    title: 'Mulai cepat',
    icon: Icons.rocket_launch_rounded,
    summary: 'Empat langkah dari alat menyala sampai pupuk tertabur.',
    steps: [
      'Nyalakan alat FERTICORE dan pastikan sudah tersambung ke WiFi (lihat layar OLED).',
      'Buka Pengaturan → Koneksi alat, isi ID alat yang tertera di label/OLED, lalu Simpan & hubungkan.',
      'Buka tab Rekomendasi, isi komoditas, pupuk, luas lahan, dan umur tanaman (HST), lalu Hitung.',
      'Tekan Kirim ke alat, periksa ringkasan, lalu konfirmasi. Tunggu tanda "Dikonfirmasi oleh alat".',
    ],
    tips: ['Di Beranda, kartu "Langkah pemupukan" menunjukkan langkah mana yang sudah selesai.'],
  ),
  const GuideSection(
    topic: GuideTopic.connection,
    title: 'Menghubungkan alat',
    icon: Icons.settings_input_antenna_rounded,
    summary: 'Aplikasi dan alat berkomunikasi lewat broker MQTT. Keduanya harus memakai broker dan ID alat yang sama.',
    steps: [
      'Buka tab Pengaturan → Koneksi alat.',
      'ID alat: 4–32 karakter (huruf, angka, "-" atau "_"), sama persis dengan yang tertera di alat.',
      'Alamat broker & port: isi sesuai broker yang dipakai alat. Bawaan: broker.emqx.io, port TLS 8883 (web: 8084).',
      'Aktifkan TLS dan isi username/password broker bila tersedia, lalu tekan Simpan & hubungkan.',
      'Status di Beranda berubah menjadi "Alat online" setelah alat mengirim data (maks. ±30 detik).',
    ],
    tips: [
      'Password disimpan terenkripsi di perangkat (Keystore/Keychain), tidak ditampilkan ulang.',
      'Jika koneksi terputus, aplikasi mencoba menyambung ulang otomatis tanpa batas, dengan jeda yang makin panjang.',
    ],
  ),
  const GuideSection(
    topic: GuideTopic.home,
    title: 'Membaca Beranda',
    icon: Icons.home_rounded,
    summary: 'Ringkasan kondisi alat secara langsung.',
    steps: [
      'Kartu utama: dosis aktif di alat (gram per titik) dan status motor.',
      'Ubin hijau "Status alat": Online/Offline beserta kualitas sinyal data.',
      'Ubin lainnya: total volume, rata-rata per sesi, jumlah sesi, dan status motor. Ketuk panah ↗ untuk detail.',
      'Kartu Perangkat: ID alat, broker, dan kapan data terakhir diterima. Peringatan kuning muncul bila sinyal hilang.',
    ],
    tips: ['Tarik layar ke bawah untuk mencoba menyambung ulang.'],
  ),
  GuideSection(
    topic: GuideTopic.recommendation,
    title: 'Rekomendasi dosis',
    icon: Icons.auto_awesome_rounded,
    summary: 'Sistem pakar menghitung dosis per tanaman dari basis pengetahuan agronomi.',
    steps: [
      'Pilih komoditas dan jenis pupuk (Urea = 0,7× dosis NPK).',
      'Isi luas lahan (m²). Aplikasi memperkirakan jumlah tanaman dari jarak tanam baku komoditas.',
      'Geser untuk menyesuaikan jumlah tanaman (rentang ±10%) bila jumlah sebenarnya berbeda.',
      'Isi umur tanaman dalam HST (Hari Setelah Tanam), lalu tekan Hitung rekomendasi.',
      'Hasil: dosis per tanaman, total kebutuhan pupuk, dan aturan yang dipakai.',
      'Tekan Kirim ke alat untuk menerapkan dosis per tanaman.',
    ],
    warning: 'Alat hanya dapat menabur $_min–$_max gram per titik. Jika rekomendasi di luar rentang ini, tombol kirim dinonaktifkan. Untuk dosis besar (mis. tanaman tahunan), bagi menjadi beberapa kali tabur melalui Kontrol manual atau taburkan secara manual.',
  ),
  GuideSection(
    topic: GuideTopic.control,
    title: 'Kontrol dosis manual',
    icon: Icons.tune_rounded,
    summary: 'Atur dosis alat secara langsung tanpa perhitungan.',
    steps: [
      'Buka tab Kontrol. Gunakan tombol −/+, slider, pilihan cepat, atau ketik angka.',
      'Rentang yang diizinkan: $_min–$_max gram. Desimal boleh memakai koma (12,5).',
      'Tekan Terapkan dosis, periksa ringkasan, lalu konfirmasi.',
      'Aplikasi menunggu konfirmasi dari alat hingga ${AppConfig.commandAckTimeout.inSeconds} detik.',
    ],
    tips: [
      '"Dikonfirmasi oleh alat" = dosis baru sudah aktif di alat.',
      '"Alat belum mengonfirmasi" = perintah terkirim tetapi belum terlihat di status; cek dosis di Beranda sebelum mengirim ulang.',
    ],
  ),
  const GuideSection(
    topic: GuideTopic.stats,
    title: 'Statistik',
    icon: Icons.insights_rounded,
    summary: 'Pantau penggunaan pupuk yang dicatat alat.',
    steps: [
      'Total volume: jumlah pupuk yang sudah ditabur sejak reset terakhir.',
      'Rata-rata: volume rata-rata per sesi. Total sesi: jumlah sesi tabur.',
      'Grafik menampilkan perubahan selama aplikasi terbuka (tidak disimpan setelah aplikasi ditutup).',
      'Reset statistik menghapus catatan di alat secara permanen — gunakan saat memulai musim tanam baru.',
    ],
  ),
  const GuideSection(
    topic: GuideTopic.deviceWifi,
    title: 'Mengganti WiFi alat',
    icon: Icons.router_rounded,
    summary: 'Gunakan bila alat pindah lokasi atau password WiFi berubah.',
    steps: [
      'Pengaturan → WiFi alat → Reset WiFi alat, lalu konfirmasi. Alat akan restart.',
      'Di ponsel, sambungkan ke WiFi "FERTICORE_CONFIG". Password tertera pada label alat / layar OLED.',
      'Buka browser ke alamat 192.168.4.1.',
      'Pilih jaringan WiFi baru, masukkan password, lalu simpan. Alat restart dan kembali online.',
      'Sambungkan kembali ponsel ke internet; status alat akan kembali "Alat online".',
    ],
    warning: 'Selama proses ini alat offline dan tidak dapat menerima perintah.',
  ),
  const GuideSection(
    topic: GuideTopic.security,
    title: 'Keamanan',
    icon: Icons.shield_rounded,
    summary: 'Cara menjaga alat dari perintah pihak lain.',
    steps: [
      'Gunakan broker pribadi dengan username & password, dan aktifkan TLS. Broker publik bisa diakses siapa saja.',
      'Gunakan ID alat yang unik dan sulit ditebak (mis. FC-7Q2K9), bukan "alat1".',
      'Jangan bagikan tangkapan layar halaman Koneksi alat.',
      'Ubah password WiFi konfigurasi (AP) bawaan pada firmware alat.',
      'Gunakan "Hapus data koneksi" di Pengaturan saat menyerahkan ponsel ke orang lain.',
    ],
    tips: [
      'Setiap perintah membawa ID acak dan waktu kirim sehingga firmware dapat menolak perintah ganda/rekaman ulang.',
      'Data dari alat divalidasi; payload rusak atau terlalu besar diabaikan.',
    ],
  ),
  const GuideSection(
    topic: GuideTopic.troubleshooting,
    title: 'Pemecahan masalah',
    icon: Icons.build_circle_rounded,
    summary: 'Solusi untuk kendala yang paling sering terjadi.',
  ),
];

const List<FaqItem> faqItems = [
  FaqItem(
    'Status "Terputus" terus-menerus',
    'Periksa koneksi internet ponsel, alamat broker, port, dan TLS. Jika muncul "Username/password broker ditolak", perbarui kredensial di Koneksi alat. Di web, gunakan port WebSocket (WSS) misalnya 8084.',
  ),
  FaqItem(
    '"Broker OK, menunggu data dari alat"',
    'Aplikasi sudah terhubung ke broker tetapi alat belum mengirim status. Pastikan alat menyala, tersambung WiFi, dan ID alat di aplikasi sama dengan di alat.',
  ),
  FaqItem(
    'Tombol kirim tidak aktif',
    'Perintah hanya bisa dikirim saat alat online. Pada Rekomendasi, tombol juga nonaktif bila dosis di luar rentang alat.',
  ),
  FaqItem(
    '"Alat belum mengonfirmasi"',
    'Perintah sudah terkirim ke broker tetapi status alat belum berubah dalam batas waktu. Cek dosis di Beranda; jika belum berubah, kirim ulang. Firmware lama mungkin belum mengirim konfirmasi.',
  ),
  FaqItem(
    'Rekomendasi sangat besar (ratusan gram)',
    'Wajar untuk tanaman tahunan (alpukat, durian, sawit). Dosis tersebut melebihi kapasitas alat per titik sehingga perlu dibagi beberapa kali tabur.',
  ),
  FaqItem(
    'Setelah update aplikasi, alat tidak terbaca',
    'Versi 2 memakai topik per-alat (ferticore/<ID>/status). Pastikan firmware alat sudah diperbarui ke protokol v2.',
  ),
];
