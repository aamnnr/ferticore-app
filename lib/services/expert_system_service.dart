import 'package:alburdat_dashboard/data/knowledge_base.dart' as kb;
import 'package:alburdat_dashboard/data/models/agronomy.dart';

/// Mesin inferensi sistem pakar (forward chaining sederhana berbasis aturan).
/// Murni (tanpa state/UI) sehingga mudah diuji dan dipakai ulang.
class ExpertSystemService {
  const ExpertSystemService({
    Map<int, List<DoseRule>> rules = kb.doseRules,
  }) : _rules = rules;

  final Map<int, List<DoseRule>> _rules;

  /// Mencari aturan yang berlaku: aturan terakhir dengan `fromHst <= hst`.
  ({DoseRule rule, double? toHst}) matchRule(int commodityId, double hst) {
    final rules = _rules[commodityId];
    if (rules == null || rules.isEmpty) {
      throw ArgumentError('Komoditas $commodityId tidak ada di basis pengetahuan');
    }
    if (hst < 0 || hst.isNaN) throw ArgumentError('HST tidak valid: $hst');

    var index = 0;
    for (var i = 0; i < rules.length; i++) {
      if (hst >= rules[i].fromHst) index = i;
    }
    final next = index + 1 < rules.length ? rules[index + 1].fromHst : null;
    return (rule: rules[index], toHst: next == null ? null : next - 1);
  }

  CalculationResult calculate(CalculationInput input) {
    if (input.plantCount <= 0) {
      throw ArgumentError('Jumlah tanaman harus lebih dari 0');
    }
    final match = matchRule(input.commodity.id, input.hst);
    final perPlant = match.rule.dose * input.fertilizer.multiplier;
    return CalculationResult(
      input: input,
      dosePerPlant: perPlant,
      totalGrams: perPlant * input.plantCount,
      ruleFromHst: match.rule.fromHst,
      ruleToHst: match.toHst,
    );
  }

  /// Estimasi populasi = luas / (jarak tanam²), rentang ±10%, minimal 1.
  PlantEstimate estimatePlants(Commodity commodity, double landArea) {
    if (landArea <= 0) throw ArgumentError('Luas lahan harus > 0');
    final base = landArea / (commodity.plantSpacing * commodity.plantSpacing);
    // Epsilon menahan galat floating point (0,7² = 0,48999…) agar
    // 100 tanaman tidak menjadi rentang 90–111.
    const eps = 1e-6;
    final min = (base * 0.9 + eps).floor().clamp(1, 1 << 31);
    final max = (base * 1.1 - eps).ceil().clamp(min, 1 << 31);
    final suggested = base.round().clamp(min, max);
    return PlantEstimate(min: min, max: max, suggested: suggested);
  }
}
