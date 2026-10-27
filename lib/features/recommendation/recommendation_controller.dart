import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/utils/validators.dart';
import 'package:alburdat_dashboard/data/models/agronomy.dart';
import 'package:alburdat_dashboard/services/expert_system_service.dart';
import 'package:flutter/foundation.dart';

/// State form rekomendasi, terpisah dari widget agar:
/// - isian tidak hilang saat berpindah tab,
/// - Beranda bisa tahu apakah rekomendasi sudah dihitung,
/// - logika dapat diuji tanpa UI.
class RecommendationController extends ChangeNotifier {
  RecommendationController({ExpertSystemService engine = const ExpertSystemService()}) : _engine = engine;

  final ExpertSystemService _engine;

  Commodity? _commodity;
  Fertilizer? _fertilizer;
  double? _landArea;
  double? _hst;
  PlantEstimate? _estimate;
  int? _plantCount;
  CalculationResult? _result;

  Commodity? get commodity => _commodity;
  Fertilizer? get fertilizer => _fertilizer;
  PlantEstimate? get estimate => _estimate;
  int? get plantCount => _plantCount;
  CalculationResult? get result => _result;

  bool get isResultSendable {
    final r = _result;
    return r != null &&
        r.dosePerPlant >= AppConfig.minDeviceDose &&
        r.dosePerPlant <= AppConfig.maxDeviceDose;
  }

  void setCommodity(Commodity? value) {
    _commodity = value;
    _recomputeEstimate();
    _invalidate();
  }

  void setFertilizer(Fertilizer? value) {
    _fertilizer = value;
    _invalidate();
  }

  void setLandArea(String raw) {
    _landArea = Validators.landArea(raw) == null ? Validators.parseDecimal(raw) : null;
    _recomputeEstimate();
    _invalidate();
  }

  void setHst(String raw) {
    _hst = Validators.plantAge(raw) == null ? Validators.parseDecimal(raw) : null;
    _invalidate();
  }

  void setPlantCount(int value) {
    final e = _estimate;
    if (e == null) return;
    _plantCount = value.clamp(e.min, e.max);
    _invalidate();
  }

  /// Mengembalikan pesan error pertama, atau `null` bila berhasil.
  String? calculate() {
    if (_commodity == null) return 'Pilih komoditas terlebih dahulu';
    if (_fertilizer == null) return 'Pilih jenis pupuk terlebih dahulu';
    if (_landArea == null) return 'Isi luas lahan dengan benar';
    if (_plantCount == null) return 'Jumlah tanaman belum ditentukan';
    if (_hst == null) return 'Isi umur tanaman (HST) dengan benar';

    _result = _engine.calculate(CalculationInput(
      commodity: _commodity!,
      fertilizer: _fertilizer!,
      hst: _hst!,
      landArea: _landArea!,
      plantCount: _plantCount!,
    ));
    notifyListeners();
    return null;
  }

  void _recomputeEstimate() {
    final c = _commodity;
    final area = _landArea;
    if (c == null || area == null) {
      _estimate = null;
      _plantCount = null;
      return;
    }
    _estimate = _engine.estimatePlants(c, area);
    _plantCount = _estimate!.suggested;
  }

  void _invalidate() {
    _result = null;
    notifyListeners();
  }
}
