import 'package:alburdat_dashboard/core/utils/validators.dart';
import 'package:alburdat_dashboard/data/models/broker_config.dart';
import 'package:alburdat_dashboard/data/models/device_command.dart';
import 'package:alburdat_dashboard/data/models/device_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceStatus.fromJson', () {
    test('membaca payload firmware', () {
      final s = DeviceStatus.fromJson({
        'gramasi': 12.5,
        'isMotorRunning': true,
        'totalVolume': 300,
        'totalSesi': 4,
        'rataRata': 75.0,
      });
      expect(s.dose, 12.5);
      expect(s.isMotorRunning, isTrue);
      expect(s.totalVolume, 300.0);
      expect(s.totalSessions, 4);
      expect(s.average, 75.0);
      expect(s.ackId, isNull);
    });

    test('defensif terhadap tipe salah, negatif, dan field hilang', () {
      final s = DeviceStatus.fromJson({'gramasi': '7.5', 'isMotorRunning': 1, 'totalVolume': -5, 'rataRata': 'x'});
      expect(s.dose, 7.5);
      expect(s.isMotorRunning, isTrue);
      expect(s.totalVolume, 0);
      expect(s.average, 0);
      expect(s.totalSessions, 0);
    });

    test('menolak payload non-objek', () {
      expect(() => DeviceStatus.fromJson([1, 2]), throwsFormatException);
      expect(() => DeviceStatus.fromJson(null), throwsFormatException);
    });
  });

  group('DeviceCommand', () {
    test('payload kompatibel firmware lama + id & ts', () {
      final c = DeviceCommand.setDose(12.346);
      final json = c.toJson();
      expect(json['set_dosis'], 12.35);
      expect(json['id'], isA<String>());
      expect((json['id']! as String).length, 16);
      expect(json['ts'], isA<int>());
    });

    test('id acak unik', () {
      expect(DeviceCommand.resetStats().id, isNot(DeviceCommand.resetStats().id));
    });

    test('konfirmasi lewat ack id', () {
      final c = DeviceCommand.setDose(10);
      final other = DeviceStatus.fromJson({'gramasi': 10, 'ack': 'lain'});
      final mine = DeviceStatus.fromJson({'gramasi': 3, 'ack': c.id});
      expect(c.isConfirmedBy(other), isFalse);
      expect(c.isConfirmedBy(mine), isTrue);
    });

    test('konfirmasi heuristik untuk firmware tanpa ack', () {
      final c = DeviceCommand.setDose(10);
      final later = DateTime.now().add(const Duration(seconds: 1));
      expect(c.isConfirmedBy(DeviceStatus.fromJson({'gramasi': 10}, receivedAt: later)), isTrue);
      expect(c.isConfirmedBy(DeviceStatus.fromJson({'gramasi': 9}, receivedAt: later)), isFalse);
      final earlier = DateTime.now().subtract(const Duration(minutes: 1));
      expect(c.isConfirmedBy(DeviceStatus.fromJson({'gramasi': 10}, receivedAt: earlier)), isFalse);
    });

    test('reset WiFi tidak menunggu ack', () {
      expect(DeviceCommand.resetWifi().expectsAck, isFalse);
      expect(DeviceCommand.setDose(10).expectsAck, isTrue);
    });
  });

  group('BrokerConfig', () {
    test('topik per-alat', () {
      final c = BrokerConfig.defaults.copyWith(deviceId: 'FC-01AB');
      expect(c.statusTopic, 'ferticore/FC-01AB/status');
      expect(c.commandTopic, 'ferticore/FC-01AB/command');
      expect(c.isComplete, isTrue);
    });

    test('bawaan aman (TLS) tetapi belum lengkap tanpa ID', () {
      expect(BrokerConfig.defaults.useTls, isTrue);
      expect(BrokerConfig.defaults.isComplete, isFalse);
    });

    test('serialisasi bolak-balik', () {
      final c = BrokerConfig.defaults.copyWith(deviceId: 'FC-01AB', username: 'tani', tcpPort: 1883);
      final back = BrokerConfig.fromJson(c.toJson());
      expect(back.deviceId, 'FC-01AB');
      expect(back.username, 'tani');
      expect(back.tcpPort, 1883);
      expect(back.toJson().containsKey('password'), isFalse);
    });
  });

  group('Validators', () {
    test('ID alat menolak wildcard dan pemisah topik MQTT', () {
      expect(Validators.deviceId('FC-01AB'), isNull);
      for (final bad in ['', 'ab', 'a/b/c', 'alat+', 'alat#', 'a b c d', 'x' * 33]) {
        expect(Validators.deviceId(bad), isNotNull, reason: bad);
      }
    });

    test('dosis alat 5–50 g dan koma desimal', () {
      expect(Validators.deviceDose('12,5'), isNull);
      expect(Validators.deviceDose('5'), isNull);
      expect(Validators.deviceDose('50'), isNull);
      expect(Validators.deviceDose('4.9'), isNotNull);
      expect(Validators.deviceDose('51'), isNotNull);
      expect(Validators.deviceDose('abc'), isNotNull);
      expect(Validators.parseDecimal('12,5'), 12.5);
    });

    test('host dan port', () {
      expect(Validators.host('broker.emqx.io'), isNull);
      expect(Validators.host('bad host'), isNotNull);
      expect(Validators.port('8883'), isNull);
      expect(Validators.port('0'), isNotNull);
      expect(Validators.port('70000'), isNotNull);
    });
  });
}
