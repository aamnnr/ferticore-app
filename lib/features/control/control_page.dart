import 'package:alburdat_dashboard/core/config/app_config.dart';
import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/core/utils/formatters.dart';
import 'package:alburdat_dashboard/core/utils/validators.dart';
import 'package:alburdat_dashboard/features/guide/guide_content.dart';
import 'package:alburdat_dashboard/features/guide/guide_page.dart';
import 'package:alburdat_dashboard/services/mqtt/device_service.dart';
import 'package:alburdat_dashboard/widgets/app_bars.dart';
import 'package:alburdat_dashboard/widgets/app_card.dart';
import 'package:alburdat_dashboard/widgets/feedback.dart';
import 'package:alburdat_dashboard/widgets/link_status.dart';
import 'package:alburdat_dashboard/widgets/status_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Kontrol dosis manual: tombol ±, slider, pilihan cepat, atau ketik angka.
class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  static const double _step = 0.5;
  static const List<double> _presets = [5, 10, 15, 20, 25, 30, 40, 50];

  final _input = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _target = 10;

  @override
  void initState() {
    super.initState();
    _input.text = Fmt.number(_target);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _setTarget(double v, {bool syncText = true}) {
    final clamped = v.clamp(AppConfig.minDeviceDose, AppConfig.maxDeviceDose);
    final rounded = (clamped * 10).roundToDouble() / 10;
    setState(() => _target = rounded);
    if (syncText) {
      _input.text = Fmt.number(rounded);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _apply(DeviceService device) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = device.status?.dose;
    final ok = await showConfirmSheet(
      context,
      title: 'Terapkan dosis ${Fmt.number(_target)} g?',
      message: 'Dosis baru langsung berlaku untuk tabur berikutnya pada alat.',
      confirmLabel: 'Terapkan',
      icon: Icons.tune_rounded,
      rows: [
        SummaryRow('Perangkat', device.config.deviceId),
        SummaryRow('Dosis saat ini', current == null ? '–' : '${Fmt.number(current)} g'),
        SummaryRow('Dosis baru', '${Fmt.number(_target)} g'),
      ],
    );
    if (!ok || !mounted) return;
    final result = await device.setDose(_target);
    if (!mounted) return;
    showCommandResult(context, result, successMessage: 'Dosis ${Fmt.number(_target)} g diterapkan');
  }

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final link = LinkStatus.of(device);
    final t = Theme.of(context).textTheme;
    final current = device.status?.dose;

    return TabPage(
      header: const PageHeader(
        title: 'Kontrol',
        actions: [HelpButton(topic: GuideTopic.control)],
      ),
      children: [
        AppCard(
          color: AppColors.surfaceRaised,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosis di alat', style: t.labelMedium),
                    const SizedBox(height: Gap.xs),
                    Text(current == null ? '–' : '${Fmt.number(current)} g', style: t.displaySmall),
                  ],
                ),
              ),
              StatusPill(label: link.label, tone: link.tone),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: AppCard(
            color: AppColors.surfaceRaised,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Dosis baru',
                  subtitle: 'Rentang alat ${Fmt.number(AppConfig.minDeviceDose, decimals: 0)}–'
                      '${Fmt.number(AppConfig.maxDeviceDose, decimals: 0)} gram per titik',
                ),
                const SizedBox(height: Gap.xl),
                Row(
                  children: [
                    _RoundButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Kurangi ${Fmt.number(_step)} g',
                      onPressed: _target > AppConfig.minDeviceDose ? () => _setTarget(_target - _step) : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(Fmt.number(_target), style: t.displayLarge),
                          Text('gram', style: t.bodySmall),
                        ],
                      ),
                    ),
                    _RoundButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Tambah ${Fmt.number(_step)} g',
                      onPressed: _target < AppConfig.maxDeviceDose ? () => _setTarget(_target + _step) : null,
                    ),
                  ],
                ),
                const SizedBox(height: Gap.md),
                Slider(
                  value: _target,
                  min: AppConfig.minDeviceDose,
                  max: AppConfig.maxDeviceDose,
                  divisions: ((AppConfig.maxDeviceDose - AppConfig.minDeviceDose) / _step).round(),
                  label: '${Fmt.number(_target)} g',
                  onChanged: _setTarget,
                ),
                const SizedBox(height: Gap.sm),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: [
                    for (final p in _presets)
                      ChoiceChip(
                        label: Text('${Fmt.number(p, decimals: 0)} g'),
                        selected: _target == p,
                        showCheckmark: false,
                        selectedColor: AppColors.navActive,
                        labelStyle: t.labelLarge?.copyWith(
                          color: _target == p ? Colors.white : AppColors.ink,
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border, width: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
                        onSelected: (_) => _setTarget(p),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.lg),
                TextFormField(
                  controller: _input,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(
                    labelText: 'Atau ketik dosis',
                    suffixText: 'g',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  validator: Validators.deviceDose,
                  onChanged: (v) {
                    final d = Validators.parseDecimal(v);
                    if (Validators.deviceDose(v) == null && d != null) _setTarget(d, syncText: false);
                  },
                  onFieldSubmitted: (_) => _apply(device),
                ),
                const SizedBox(height: Gap.lg),
                if (!device.isDeviceOnline) ...[
                  InfoBanner(message: link.detail, tone: link.tone),
                  const SizedBox(height: Gap.md),
                ],
                FilledButton.icon(
                  onPressed: device.canSendCommands ? () => _apply(device) : null,
                  icon: device.isCommandInFlight
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded),
                  label: Text(device.isCommandInFlight ? 'Menunggu konfirmasi…' : 'Terapkan dosis'),
                ),
                if (device.lastConfirmedDose != null) ...[
                  const SizedBox(height: Gap.md),
                  InfoBanner(
                    tone: Tone.success,
                    message: 'Terakhir dikonfirmasi alat: ${Fmt.number(device.lastConfirmedDose!)} g',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Center(
          child: TextButton.icon(
            onPressed: () => openGuide(context, GuideTopic.control),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Cara kerja konfirmasi dosis'),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 26,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        fixedSize: const Size(56, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      icon: Icon(icon),
    );
  }
}
