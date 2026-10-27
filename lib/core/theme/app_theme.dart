import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token desain (warna, jarak, radius) — mengikuti referensi UI:
/// latar abu lembut, kartu terang tanpa bayangan, aksen hijau, angka besar
/// berbobot tipis, dan navigasi bawah mengambang.
class AppColors {
  AppColors._();

  static const background = Color(0xFFECEDEF);
  static const surface = Color(0xFFF7F7F8);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E3E6);

  static const ink = Color(0xFF1B1C1E);
  static const inkMuted = Color(0xFF85888E);
  static const inkFaint = Color(0xFFB4B6BB);

  static const primary = Color(0xFF2F9E5B);
  static const primaryDark = Color(0xFF237A45);
  static const primarySoft = Color(0xFFE3F3E9);

  static const navActive = Color(0xFF2A2B2E);

  static const success = Color(0xFF2F9E5B);
  static const warning = Color(0xFFB7791F);
  static const warningSoft = Color(0xFFFFF3D6);
  static const danger = Color(0xFFD9363E);
  static const dangerSoft = Color(0xFFFDE7E8);
  static const info = Color(0xFF2F6FDB);
  static const infoSoft = Color(0xFFE5EEFC);
}

class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Ruang bawah konten agar tidak tertutup navigasi mengambang.
  static const double navClearance = 112;
}

class Radii {
  Radii._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

/// Nada semantik yang dipakai ulang oleh pill, banner, dan snackbar.
enum Tone { neutral, success, warning, danger, info }

extension ToneColors on Tone {
  Color get foreground => switch (this) {
    Tone.neutral => AppColors.inkMuted,
    Tone.success => AppColors.success,
    Tone.warning => AppColors.warning,
    Tone.danger => AppColors.danger,
    Tone.info => AppColors.info,
  };

  Color get background => switch (this) {
    Tone.neutral => AppColors.background,
    Tone.success => AppColors.primarySoft,
    Tone.warning => AppColors.warningSoft,
    Tone.danger => AppColors.dangerSoft,
    Tone.info => AppColors.infoSoft,
  };
}

class AppTheme {
  AppTheme._();

  static TextTheme _text() {
    final base = GoogleFonts.interTextTheme();
    TextStyle s(double size, FontWeight w, [Color c = AppColors.ink]) =>
        GoogleFonts.inter(fontSize: size, fontWeight: w, color: c, height: 1.3);
    return base.copyWith(
      displayLarge: s(56, FontWeight.w300).copyWith(letterSpacing: -2, height: 1),
      displayMedium: s(44, FontWeight.w300).copyWith(letterSpacing: -1.5, height: 1),
      displaySmall: s(32, FontWeight.w300).copyWith(letterSpacing: -1, height: 1.1),
      headlineMedium: s(22, FontWeight.w600),
      headlineSmall: s(18, FontWeight.w600),
      titleLarge: s(16, FontWeight.w600),
      titleMedium: s(14, FontWeight.w600),
      titleSmall: s(13, FontWeight.w600),
      bodyLarge: s(15, FontWeight.w400),
      bodyMedium: s(14, FontWeight.w400),
      bodySmall: s(12, FontWeight.w400, AppColors.inkMuted),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12, FontWeight.w500, AppColors.inkMuted),
      labelSmall: s(11, FontWeight.w500, AppColors.inkMuted),
    );
  }

  static ThemeData get light {
    final text = _text();
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.headlineSmall,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 14),
        labelStyle: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.inkFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.inkMuted,
          minimumSize: const Size.fromHeight(52),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: text.labelLarge),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x222F9E5B),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navActive,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: rounded,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        iconColor: AppColors.ink,
        collapsedIconColor: AppColors.inkMuted,
      ),
    );
  }
}
