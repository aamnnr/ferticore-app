/// Snapshot status yang dipublikasikan alat ke topik `.../status`.
class DeviceStatus {
  final double dose;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSessions;
  final double average;

  /// ID perintah terakhir yang dieksekusi alat (opsional, firmware v2).
  final String? ackId;

  final DateTime receivedAt;

  const DeviceStatus({
    required this.dose,
    required this.isMotorRunning,
    required this.totalVolume,
    required this.totalSessions,
    required this.average,
    required this.receivedAt,
    this.ackId,
  });

  /// Parsing defensif: payload datang dari jaringan sehingga tipe tidak
  /// dipercaya begitu saja. Angka negatif/NaN dinormalkan ke 0, string
  /// angka diterima, dan payload non-objek ditolak dengan [FormatException].
  factory DeviceStatus.fromJson(Object? json, {DateTime? receivedAt}) {
    if (json is! Map) {
      throw const FormatException('Payload status bukan objek JSON');
    }
    final ack = json['ack'];
    return DeviceStatus(
      dose: _toDouble(json['gramasi']),
      isMotorRunning: _toBool(json['isMotorRunning']),
      totalVolume: _toDouble(json['totalVolume']),
      totalSessions: _toDouble(json['totalSesi']).round(),
      average: _toDouble(json['rataRata']),
      ackId: ack is String && ack.length <= 64 ? ack : null,
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }

  static double _toDouble(Object? v) {
    final d = switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0.0,
      _ => 0.0,
    };
    if (d.isNaN || d.isInfinite || d < 0) return 0.0;
    return d;
  }

  static bool _toBool(Object? v) => switch (v) {
    bool b => b,
    num n => n != 0,
    String s => s == 'true' || s == '1',
    _ => false,
  };
}
