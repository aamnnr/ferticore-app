import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/data/models/agronomy.dart';
import 'package:alburdat_dashboard/services/expert_system_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = ExpertSystemService();
  final jagung = commodities.firstWhere((c) => c.name == 'Jagung');
  final npk = fertilizers.firstWhere((f) => f.name == 'NPK');
  final urea = fertilizers.firstWhere((f) => f.name == 'Urea');

  group('matchRule', () {
    test('memilih aturan sesuai rentang HST', () {
      expect(engine.matchRule(jagung.id, 0).rule.dose, 3.6);
      expect(engine.matchRule(jagung.id, 20).rule.dose, 3.6);
      expect(engine.matchRule(jagung.id, 21).rule.dose, 2.9);
      expect(engine.matchRule(jagung.id, 500).rule.dose, 2.9);
    });

    test('HST pecahan di antara dua aturan tidak lagi jatuh ke aturan terakhir', () {
      // Kopi: 0–14 → 106, 15–120 → 80, ...; dulu 14,5 jatuh ke aturan terakhir (20).
      expect(engine.matchRule(10, 14.5).rule.dose, 106.0);
    });

    test('menyertakan batas atas aturan untuk penjelasan', () {
      final m = engine.matchRule(jagung.id, 5);
      expect(m.rule.fromHst, 0);
      expect(m.toHst, 20);
      expect(engine.matchRule(jagung.id, 30).toHst, isNull);
    });

    test('menolak input tidak valid', () {
      expect(() => engine.matchRule(999, 10), throwsArgumentError);
      expect(() => engine.matchRule(jagung.id, -1), throwsArgumentError);
    });
  });

  group('calculate', () {
    test('menghitung dosis per tanaman dan total', () {
      final r = engine.calculate(CalculationInput(
        commodity: jagung,
        fertilizer: urea,
        hst: 10,
        landArea: 100,
        plantCount: 200,
      ));
      expect(r.dosePerPlant, closeTo(3.6 * 0.7, 1e-9));
      expect(r.totalGrams, closeTo(3.6 * 0.7 * 200, 1e-9));
      expect(r.totalKg, closeTo(r.totalGrams / 1000, 1e-9));
    });

    test('menolak jumlah tanaman 0', () {
      expect(
        () => engine.calculate(CalculationInput(
          commodity: jagung,
          fertilizer: npk,
          hst: 10,
          landArea: 1,
          plantCount: 0,
        )),
        throwsArgumentError,
      );
    });
  });

  group('estimatePlants', () {
    test('rentang ±10% dari luas / jarak²', () {
      final e = engine.estimatePlants(jagung, 49); // 49 / 0.49 = 100
      expect(e.min, 90);
      expect(e.max, 110);
      expect(e.suggested, 100);
    });

    test('lahan sangat kecil tetap minimal 1 tanaman', () {
      final durian = commodities.firstWhere((c) => c.name == 'Durian');
      final e = engine.estimatePlants(durian, 1);
      expect(e.min, greaterThanOrEqualTo(1));
      expect(e.max, greaterThanOrEqualTo(e.min));
      expect(e.suggested, inInclusiveRange(e.min, e.max));
    });
  });

  test('basis pengetahuan konsisten: setiap komoditas punya aturan terurut mulai 0', () {
    for (final c in commodities) {
      final rules = doseRules[c.id];
      expect(rules, isNotNull, reason: c.name);
      expect(rules!.first.fromHst, 0, reason: c.name);
      for (var i = 1; i < rules.length; i++) {
        expect(rules[i].fromHst, greaterThan(rules[i - 1].fromHst), reason: c.name);
      }
    }
  });
}
