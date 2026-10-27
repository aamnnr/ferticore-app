/// Model domain untuk sistem pakar rekomendasi pupuk.
library;

class Commodity {
  final int id;
  final String name;

  /// Jarak tanam (meter) untuk pola persegi, dipakai mengestimasi populasi.
  final double plantSpacing;

  const Commodity({
    required this.id,
    required this.name,
    required this.plantSpacing,
  });

  @override
  bool operator ==(Object other) => other is Commodity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Fertilizer {
  final int id;
  final String name;

  /// Faktor pengali terhadap dosis dasar (NPK = 1.0).
  final double multiplier;

  const Fertilizer({
    required this.id,
    required this.name,
    required this.multiplier,
  });

  @override
  bool operator ==(Object other) => other is Fertilizer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Aturan dosis: berlaku mulai [fromHst] (inklusif) sampai aturan berikutnya.
/// Dengan hanya menyimpan batas bawah, tidak ada celah antar-rentang
/// (mis. HST 20,5 yang dulu jatuh di antara 0–20 dan 21–∞).
class DoseRule {
  final double fromHst;

  /// Dosis dasar gram per tanaman.
  final double dose;

  const DoseRule({required this.fromHst, required this.dose});
}

class CalculationInput {
  final Commodity commodity;
  final Fertilizer fertilizer;
  final double hst;
  final double landArea;
  final int plantCount;

  const CalculationInput({
    required this.commodity,
    required this.fertilizer,
    required this.hst,
    required this.landArea,
    required this.plantCount,
  });
}

class CalculationResult {
  final CalculationInput input;

  /// Gram per tanaman (per titik tabur).
  final double dosePerPlant;

  /// Total kebutuhan pupuk, gram.
  final double totalGrams;

  /// Rentang HST dari aturan yang dipakai, untuk penjelasan.
  final double ruleFromHst;
  final double? ruleToHst;

  const CalculationResult({
    required this.input,
    required this.dosePerPlant,
    required this.totalGrams,
    required this.ruleFromHst,
    required this.ruleToHst,
  });

  double get totalKg => totalGrams / 1000;
}

/// Rentang estimasi populasi tanaman (±10%).
class PlantEstimate {
  final int min;
  final int max;
  final int suggested;

  const PlantEstimate({
    required this.min,
    required this.max,
    required this.suggested,
  });
}
