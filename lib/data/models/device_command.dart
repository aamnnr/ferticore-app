import 'dart:math';

import 'package:alburdat_dashboard/data/models/device_status.dart';

enum CommandType { setDose, resetStats, resetWifi }

/// Perintah ke alat. Payload tetap memakai kunci lama (`set_dosis`,
/// `reset_stats`, `reset_wifi`) agar parser firmware lama tetap jalan,
/// ditambah `id` (acak) dan `ts` (epoch ms) supaya firmware bisa menolak
/// perintah duplikat/replay dan mengirim balik `ack`.
class DeviceCommand {
  final CommandType type;
  final double? value;
  final String id;
  final DateTime createdAt;

  DeviceCommand._(this.type, this.value)
    : id = _newId(),
      createdAt = DateTime.now();

  DeviceCommand.setDose(double grams) : this._(CommandType.setDose, grams);
  DeviceCommand.resetStats() : this._(CommandType.resetStats, null);
  DeviceCommand.resetWifi() : this._(CommandType.resetWifi, null);

  static final Random _rng = Random.secure();

  static String _newId() =>
      List.generate(8, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();

  /// `reset_wifi` membuat alat restart sehingga tidak mungkin mengirim ack.
  bool get expectsAck => type != CommandType.resetWifi;

  Map<String, Object> toJson() => {
    'id': id,
    'ts': createdAt.millisecondsSinceEpoch,
    ...switch (type) {
      CommandType.setDose => {'set_dosis': double.parse(value!.toStringAsFixed(2))},
      CommandType.resetStats => {'reset_stats': true},
      CommandType.resetWifi => {'reset_wifi': true},
    },
  };

  /// Apakah [status] membuktikan perintah ini sudah dieksekusi.
  /// Firmware v2 mengirim `ack` = id perintah. Untuk firmware yang belum
  /// mendukung ack, dipakai heuristik dari isi status.
  bool isConfirmedBy(DeviceStatus status) {
    if (status.ackId != null) return status.ackId == id;
    if (status.receivedAt.isBefore(createdAt)) return false;
    return switch (type) {
      CommandType.setDose => (status.dose - value!).abs() < 0.05,
      CommandType.resetStats =>
        status.totalSessions == 0 && status.totalVolume == 0,
      CommandType.resetWifi => false,
    };
  }
}

enum CommandOutcome {
  /// Alat mengonfirmasi perintah.
  confirmed,

  /// Terkirim ke broker, tidak ada ack yang diharapkan (reset WiFi).
  sent,

  /// Terkirim tetapi alat tidak mengonfirmasi dalam batas waktu.
  timeout,

  /// Tidak terkirim (tidak terhubung / alat offline / nilai tidak valid).
  rejected,
}

class CommandResult {
  final CommandOutcome outcome;
  final String message;

  const CommandResult(this.outcome, this.message);

  bool get isSuccess =>
      outcome == CommandOutcome.confirmed || outcome == CommandOutcome.sent;
}
