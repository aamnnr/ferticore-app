import 'package:alburdat_dashboard/data/models/agronomy.dart';

/// Basis pengetahuan agronomi. Untuk menambah komoditas cukup tambahkan
/// entri di [commodities] dan aturannya di [doseRules] — tidak perlu
/// menyentuh logika atau UI.

const List<Fertilizer> fertilizers = [
  Fertilizer(id: 1, name: 'NPK', multiplier: 1.0),
  Fertilizer(id: 2, name: 'Urea', multiplier: 0.7),
];

const List<Commodity> commodities = [
  Commodity(id: 1, name: 'Jagung', plantSpacing: 0.7),
  Commodity(id: 2, name: 'Cabai Merah', plantSpacing: 0.5),
  Commodity(id: 3, name: 'Kentang', plantSpacing: 0.4),
  Commodity(id: 4, name: 'Alpukat', plantSpacing: 5.0),
  Commodity(id: 5, name: 'Buah Naga', plantSpacing: 3.0),
  Commodity(id: 6, name: 'Durian', plantSpacing: 8.0),
  Commodity(id: 7, name: 'Kakao', plantSpacing: 3.0),
  Commodity(id: 8, name: 'Karet', plantSpacing: 6.0),
  Commodity(id: 9, name: 'Sawit', plantSpacing: 9.0),
  Commodity(id: 10, name: 'Kopi', plantSpacing: 2.0),
  Commodity(id: 11, name: 'Pala', plantSpacing: 6.0),
  Commodity(id: 12, name: 'Pisang', plantSpacing: 3.0),
  Commodity(id: 13, name: 'Tebu', plantSpacing: 1.2),
];

/// Aturan per komoditas, WAJIB terurut naik berdasarkan `fromHst`
/// dan aturan pertama dimulai dari 0.
const Map<int, List<DoseRule>> doseRules = {
  1: [DoseRule(fromHst: 0, dose: 3.6), DoseRule(fromHst: 21, dose: 2.9)],
  2: [DoseRule(fromHst: 0, dose: 2.9)],
  3: [DoseRule(fromHst: 0, dose: 6.0), DoseRule(fromHst: 21, dose: 2.4)],
  4: [
    DoseRule(fromHst: 0, dose: 80.0),
    DoseRule(fromHst: 91, dose: 315.0),
    DoseRule(fromHst: 181, dose: 1325.0),
  ],
  5: [DoseRule(fromHst: 0, dose: 15.0)],
  6: [
    DoseRule(fromHst: 0, dose: 200.0),
    DoseRule(fromHst: 721, dose: 400.0),
    DoseRule(fromHst: 1441, dose: 600.0),
    DoseRule(fromHst: 2881, dose: 850.0),
  ],
  7: [
    DoseRule(fromHst: 0, dose: 25.0),
    DoseRule(fromHst: 361, dose: 45.0),
    DoseRule(fromHst: 721, dose: 90.0),
    DoseRule(fromHst: 1081, dose: 180.0),
    DoseRule(fromHst: 1441, dose: 220.0),
  ],
  8: [
    DoseRule(fromHst: 0, dose: 250.0),
    DoseRule(fromHst: 1081, dose: 300.0),
    DoseRule(fromHst: 1441, dose: 350.0),
    DoseRule(fromHst: 1801, dose: 200.0),
  ],
  9: [
    DoseRule(fromHst: 0, dose: 100.0),
    DoseRule(fromHst: 31, dose: 150.0),
    DoseRule(fromHst: 241, dose: 200.0),
  ],
  10: [
    DoseRule(fromHst: 0, dose: 106.0),
    DoseRule(fromHst: 15, dose: 80.0),
    DoseRule(fromHst: 121, dose: 53.0),
    DoseRule(fromHst: 211, dose: 26.0),
    DoseRule(fromHst: 331, dose: 20.0),
  ],
  11: [
    DoseRule(fromHst: 0, dose: 20.0),
    DoseRule(fromHst: 721, dose: 40.0),
    DoseRule(fromHst: 1441, dose: 80.0),
    DoseRule(fromHst: 2521, dose: 100.0),
    DoseRule(fromHst: 5401, dose: 120.0),
  ],
  12: [DoseRule(fromHst: 0, dose: 100.0), DoseRule(fromHst: 168, dose: 150.0)],
  13: [DoseRule(fromHst: 0, dose: 3.75)],
};
