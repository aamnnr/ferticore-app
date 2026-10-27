import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/features/recommendation/recommendation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecommendationController filled(String commodity) {
    return RecommendationController()
      ..setCommodity(commodities.firstWhere((c) => c.name == commodity))
      ..setFertilizer(fertilizers.first)
      ..setLandArea('49')
      ..setHst('10');
  }

  test('memberi pesan bila data belum lengkap', () {
    final c = RecommendationController();
    expect(c.calculate(), isNotNull);
    expect(c.result, isNull);
  });

  test('menghitung dan menandai hasil yang bisa dikirim', () {
    final c = filled('Buah Naga'); // 15 g/tanaman → dalam rentang alat
    expect(c.calculate(), isNull);
    expect(c.result, isNotNull);
    expect(c.isResultSendable, isTrue);
  });

  test('hasil di luar rentang alat tidak bisa dikirim', () {
    final c = filled('Jagung'); // 3,6 g < 5 g
    expect(c.calculate(), isNull);
    expect(c.isResultSendable, isFalse);
  });

  test('mengubah input membatalkan hasil lama', () {
    final c = filled('Buah Naga')..calculate();
    c.setHst('20');
    expect(c.result, isNull);
  });

  test('input tidak valid dianggap kosong', () {
    final c = filled('Buah Naga')..setLandArea('-3');
    expect(c.estimate, isNull);
    expect(c.calculate(), isNotNull);
  });

  test('jumlah tanaman dibatasi ke rentang estimasi', () {
    final c = filled('Jagung');
    c.setPlantCount(100000);
    expect(c.plantCount, c.estimate!.max);
  });
}
