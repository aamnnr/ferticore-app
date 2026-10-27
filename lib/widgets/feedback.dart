import 'package:alburdat_dashboard/core/theme/app_theme.dart';
import 'package:alburdat_dashboard/data/models/device_command.dart';
import 'package:flutter/material.dart';

/// Snackbar seragam di seluruh aplikasi (menggantikan 5 salinan `_showFeedback`).
void showAppSnack(BuildContext context, String message, {Tone tone = Tone.neutral}) {
  final icon = switch (tone) {
    Tone.success => Icons.check_circle_rounded,
    Tone.danger => Icons.error_rounded,
    Tone.warning => Icons.warning_rounded,
    _ => Icons.info_rounded,
  };
  final color = tone == Tone.neutral ? Colors.white : tone.background;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: Gap.sm),
            Expanded(child: Text(message)),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, 96),
        duration: const Duration(seconds: 3),
      ),
    );
}

/// Satu baris ringkasan pada lembar konfirmasi.
class SummaryRow {
  const SummaryRow(this.label, this.value);
  final String label;
  final String value;
}

/// Lembar konfirmasi dari bawah. Mengembalikan `true` bila disetujui.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  List<SummaryRow> rows = const [],
  String confirmLabel = 'Lanjutkan',
  bool destructive = false,
  IconData icon = Icons.send_rounded,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final t = Theme.of(ctx).textTheme;
      final accent = destructive ? AppColors.danger : AppColors.primary;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(Gap.md),
                decoration: BoxDecoration(
                  color: destructive ? AppColors.dangerSoft : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(height: Gap.lg),
              Text(title, style: t.headlineSmall),
              const SizedBox(height: Gap.sm),
              Text(message, style: t.bodyMedium?.copyWith(color: AppColors.inkMuted)),
              if (rows.isNotEmpty) ...[
                const SizedBox(height: Gap.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: AppColors.border, width: 0.6),
                  ),
                  child: Column(
                    children: [
                      for (final r in rows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(r.label, style: t.bodySmall)),
                              Text(r.value, style: t.titleMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Gap.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: FilledButton(
                      style: destructive
                          ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                          : null,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Menampilkan hasil perintah alat sebagai snackbar dengan nada yang tepat.
void showCommandResult(BuildContext context, CommandResult result, {String? successMessage}) {
  if (!context.mounted) return;
  final tone = switch (result.outcome) {
    CommandOutcome.confirmed || CommandOutcome.sent => Tone.success,
    CommandOutcome.timeout => Tone.warning,
    CommandOutcome.rejected => Tone.danger,
  };
  showAppSnack(
    context,
    result.isSuccess ? (successMessage ?? result.message) : result.message,
    tone: tone,
  );
}
