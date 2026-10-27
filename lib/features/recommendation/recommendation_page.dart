import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/formatters.dart';
import 'package:alburdat_dashboard/core/utils/validators.dart';
import 'package:alburdat_dashboard/data/knowledge_base.dart';
import 'package:alburdat_dashboard/data/models/agronomy.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/features/recommendation/recommendation_controller.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final _area = TextEditingController();
  final _hst = TextEditingController();

  static final _decimalInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

  @override
  void dispose() {
    _area.dispose();
    _hst.dispose();
    super.dispose();
  }

  void _calculate(RecommendationController reco) {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState?.validate() ?? false;
    final error = reco.calculate();
    if (!formOk || error != null) {
      showAppSnack(context, error ?? 'Periksa kembali isian', tone: Tone.danger);
    }
  }

  Future<void> _send(RecommendationController reco, DeviceService device) async {
    final r = reco.result;
    if (r == null) return;
    final ok = await showConfirmSheet(
      context,
      title: 'Kirim dosis ke alat?',
      message: 'Alat akan menabur dosis ini pada setiap titik/tanaman.',
      confirmLabel: 'Kirim',
      rows: [
        SummaryRow('Komoditas', r.input.commodity.name),
        SummaryRow('Pupuk', r.input.fertilizer.name),
        SummaryRow('Umur tanaman', '${Fmt.number(r.input.hst, decimals: 0)} HST'),
        SummaryRow('Dosis per titik', '${Fmt.number(r.dosePerPlant, decimals: 2)} g'),
        SummaryRow('Perangkat', device.config.deviceId),
      ],
    );
    if (!ok || !mounted) return;
    final result = await device.setDose(r.dosePerPlant);
    if (!mounted) return;
    showCommandResult(context, result, successMessage: 'Dosis ${Fmt.number(r.dosePerPlant, decimals: 2)} g diterapkan');
  }

  @override
  Widget build(BuildContext context) {
    final reco = context.watch<RecommendationController>();
    final device = context.watch<DeviceService>();
    final t = Theme.of(context).textTheme;

    return TabPage(
      header: const PageHeader(
        title: 'Rekomendasi',
        actions: [HelpButton(topic: GuideTopic.recommendation)],
      ),
      children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AppCard(
            color: AppColors.surfaceRaised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Data lahan',
                  subtitle: 'Sistem pakar menghitung dosis dari basis pengetahuan agronomi',
                ),
                const SizedBox(height: Gap.lg),
                DropdownButtonFormField<Commodity>(
                  initialValue: reco.commodity,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Komoditas',
                    prefixIcon: Icon(Icons.grass_rounded),
                  ),
                  items: [
                    for (final c in commodities) DropdownMenuItem(value: c, child: Text(c.name)),
                  ],
                  validator: (v) => v == null ? 'Pilih komoditas' : null,
                  onChanged: reco.setCommodity,
                ),
                const SizedBox(height: Gap.md),
                DropdownButtonFormField<Fertilizer>(
                  initialValue: reco.fertilizer,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Jenis pupuk',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                  items: [
                    for (final f in fertilizers)
                      DropdownMenuItem(
                        value: f,
                        child: Text(f.multiplier == 1 ? f.name : '${f.name} (${Fmt.number(f.multiplier)}× NPK)'),
                      ),
                  ],
                  validator: (v) => v == null ? 'Pilih jenis pupuk' : null,
                  onChanged: reco.setFertilizer,
                ),
                const SizedBox(height: Gap.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _area,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: _decimalInput,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Luas lahan', suffixText: 'm²'),
                        validator: Validators.landArea,
                        onChanged: reco.setLandArea,
                      ),
                    ),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: TextFormField(
                        controller: _hst,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: _decimalInput,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Umur tanaman', suffixText: 'HST'),
                        validator: Validators.plantAge,
                        onChanged: reco.setHst,
                        onFieldSubmitted: (_) => _calculate(reco),
                      ),
                    ),
                  ],
                ),
                if (reco.estimate != null) ...[
                  const SizedBox(height: Gap.lg),
                  _PlantCountSlider(reco: reco),
                ],
                const SizedBox(height: Gap.lg),
                FilledButton.icon(
                  onPressed: () => _calculate(reco),
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Hitung rekomendasi'),
                ),
              ],
            ),
          ),
        ),
        if (reco.result != null) ...[
          const SizedBox(height: Gap.md),
          _ResultCard(
            result: reco.result!,
            sendable: reco.isResultSendable,
            device: device,
            onSend: () => _send(reco, device),
          ),
        ] else ...[
          const SizedBox(height: Gap.md),
          const InfoBanner(
            tone: Tone.info,
            message: 'Isi semua data lalu tekan "Hitung rekomendasi". Hasil dapat langsung dikirim ke alat.',
          ),
        ],
        const SizedBox(height: Gap.md),
        Text(
          'Rekomendasi bersifat panduan umum. Sesuaikan dengan hasil uji tanah dan anjuran penyuluh setempat.',
          style: t.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PlantCountSlider extends StatelessWidget {
  const _PlantCountSlider({required this.reco});

  final RecommendationController reco;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = reco.estimate!;
    final count = reco.plantCount ?? e.suggested;
    final span = e.max - e.min;

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xs),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(Radii.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Jumlah tanaman', style: t.labelMedium),
              const Spacer(),
              Text(Fmt.number(count, decimals: 0), style: t.titleLarge),
            ],
          ),
          Text(
            'Estimasi dari jarak tanam ${Fmt.number(reco.commodity!.plantSpacing)} m '
            '(${Fmt.number(e.min, decimals: 0)}–${Fmt.number(e.max, decimals: 0)})',
            style: t.bodySmall,
          ),
          if (span > 0)
            Slider(
              value: count.toDouble(),
              min: e.min.toDouble(),
              max: e.max.toDouble(),
              divisions: span.clamp(1, 200),
              label: Fmt.number(count, decimals: 0),
              onChanged: (v) => reco.setPlantCount(v.round()),
            )
          else
            const SizedBox(height: Gap.sm),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.sendable, required this.device, required this.onSend});

  final CalculationResult result;
  final bool sendable;
  final DeviceService device;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = result;
    final ruleRange = r.ruleToHst == null
        ? '≥ ${Fmt.number(r.ruleFromHst, decimals: 0)} HST'
        : '${Fmt.number(r.ruleFromHst, decimals: 0)}–${Fmt.number(r.ruleToHst!, decimals: 0)} HST';

    String? blocker;
    if (!sendable) {
      blocker = 'Dosis ${Fmt.number(r.dosePerPlant, decimals: 2)} g di luar kemampuan alat '
          '(${Fmt.number(AppConfig.minDeviceDose, decimals: 0)}–${Fmt.number(AppConfig.maxDeviceDose, decimals: 0)} g/titik). '
          'Bagi menjadi beberapa kali tabur lewat Kontrol, atau tabur manual.';
    } else if (!device.isConnected) {
      blocker = 'Belum terhubung ke broker.';
    } else if (!device.isDeviceOnline) {
      blocker = 'Alat offline — hasil tidak dapat dikirim sekarang.';
    }

    return AppCard(
      color: AppColors.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: Text('Hasil rekomendasi', style: t.titleLarge)),
              const SizedBox(width: Gap.sm),
              StatusPill(
                label: sendable ? 'Sesuai alat' : 'Di luar rentang',
                tone: sendable ? Tone.success : Tone.warning,
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.number(r.dosePerPlant, decimals: 2), style: t.displayMedium),
              const SizedBox(width: Gap.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('g / tanaman', style: t.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Row(
            children: [
              Expanded(child: _Fact(label: 'Total kebutuhan', value: Fmt.mass(r.totalGrams, decimals: 0))),
              Expanded(child: _Fact(label: 'Jumlah tanaman', value: Fmt.number(r.input.plantCount, decimals: 0))),
              Expanded(child: _Fact(label: 'Aturan', value: ruleRange)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(
            '${r.input.commodity.name} umur ${Fmt.number(r.input.hst, decimals: 0)} HST masuk aturan $ruleRange. '
            'Dosis dasar × faktor ${r.input.fertilizer.name} (${Fmt.number(r.input.fertilizer.multiplier)}×) '
            '× ${Fmt.number(r.input.plantCount, decimals: 0)} tanaman pada lahan ${Fmt.number(r.input.landArea, decimals: 0)} m².',
            style: t.bodySmall,
          ),
          if (blocker != null) ...[
            const SizedBox(height: Gap.md),
            InfoBanner(message: blocker, tone: Tone.warning),
          ],
          const SizedBox(height: Gap.lg),
          FilledButton.icon(
            onPressed: blocker == null && device.canSendCommands ? onSend : null,
            icon: device.isCommandInFlight
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            label: Text(device.isCommandInFlight ? 'Menunggu konfirmasi…' : 'Kirim ke alat'),
          ),
          if (!sendable) ...[
            const SizedBox(height: Gap.sm),
            TextButton(
              onPressed: () => openGuide(context, GuideTopic.recommendation),
              child: const Text('Kenapa tidak bisa dikirim?'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: t.titleMedium),
      ],
    );
  }
}
