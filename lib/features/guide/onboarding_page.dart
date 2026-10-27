import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:flutter/material.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    Icons.eco_rounded,
    'Selamat datang di FERTICORE AI',
    'Pantau dan kendalikan alat tabur pupuk presisi langsung dari ponsel — dosis, motor, dan statistik secara real-time.',
  ),
  _Slide(
    Icons.settings_input_antenna_rounded,
    'Hubungkan alat Anda',
    'Masukkan ID alat yang tertera di label atau layar OLED, lalu atur broker. Gunakan TLS dan password agar alat tidak bisa dikendalikan orang lain.',
  ),
  _Slide(
    Icons.auto_awesome_rounded,
    'Dosis tepat, bukan tebakan',
    'Sistem pakar menghitung dosis per tanaman dari komoditas, umur tanaman (HST), luas lahan, dan jenis pupuk.',
  ),
  _Slide(
    Icons.verified_rounded,
    'Setiap perintah terkonfirmasi',
    'Sebelum dikirim Anda melihat ringkasannya, dan aplikasi menunggu alat mengonfirmasi. Panduan lengkap selalu ada di tombol (?) dan menu Pengaturan.',
  ),
];

/// Pengenalan singkat saat pertama kali membuka aplikasi.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  /// Dipanggil saat pengguna selesai/lewati. `true` = lanjut atur koneksi.
  final void Function(bool setupConnection) onDone;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone(true);
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BrandLogo(size: 36),
                      const Spacer(),
                      if (!_isLast)
                        TextButton(onPressed: () => widget.onDone(false), child: const Text('Lewati')),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        final s = _slides[i];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(Radii.xl),
                                border: Border.all(color: AppColors.border, width: 0.6),
                              ),
                              child: Icon(s.icon, size: 64, color: AppColors.primary),
                            ),
                            const SizedBox(height: Gap.xxl),
                            Text(s.title, style: t.headlineMedium, textAlign: TextAlign.center),
                            const SizedBox(height: Gap.md),
                            Text(
                              s.body,
                              style: t.bodyLarge?.copyWith(color: AppColors.inkMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index ? AppColors.navActive : AppColors.inkFaint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Gap.xl),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_isLast ? 'Atur koneksi alat' : 'Lanjut'),
                  ),
                  if (_isLast) ...[
                    const SizedBox(height: Gap.sm),
                    TextButton(onPressed: () => widget.onDone(false), child: const Text('Nanti saja')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
