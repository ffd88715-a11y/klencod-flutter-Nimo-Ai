import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Authentic Apple iOS 18 Human Interface Guidelines (HIG) Color System.
/// Calm matte dark surfaces without harsh neon glare.
class TalkoraColors {
  const TalkoraColors._();

  // iOS System Accent Colors (Light)
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosIndigo = Color(0xFF5856D6);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosTeal = Color(0xFF30B0C7);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosOrange = Color(0xFFFF9500);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color iosRed = Color(0xFFFF3B30);

  // iOS System Accent Colors (Dark)
  static const Color iosDarkBlue = Color(0xFF0A84FF);
  static const Color iosDarkIndigo = Color(0xFF5E5CE6);
  static const Color iosDarkGreen = Color(0xFF30D158);
  static const Color iosDarkOrange = Color(0xFFFF9F0A);
  static const Color iosDarkRed = Color(0xFFFF453A);

  // Legacy aliases kept for full backwards compatibility across existing screens
  static const Color primaryAccent = iosBlue;
  static const Color secondaryAccent = iosIndigo;
  static const Color success = iosGreen;
  static const Color error = iosRed;

  // iOS Light Surfaces (System Grouped Background)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightFill = Color(0xFFE5E5EA);
  static const Color lightSeparator = Color(0xFFC6C6C8);
  static const Color lightMainText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF8E8E93);

  // iOS Dark Surfaces (Calm Matte Graphite — zero harsh neon)
  static const Color darkBackground = Color(0xFF0E1015);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color darkFill = Color(0xFF2C2C2E);
  static const Color darkSeparator = Color(0xFF38383A);
  static const Color darkPrimary = iosDarkBlue;
  static const Color darkText = Color(0xFFF5F5F7);
  static const Color darkSecondaryText = Color(0xFF98989D);

  /// User-selectable iOS accent palette
  static const Map<String, Color> accentChoices = {
    'blue': iosBlue,
    'indigo': iosIndigo,
    'purple': iosPurple,
    'teal': iosTeal,
    'green': iosGreen,
    'orange': iosOrange,
  };

  static Color resolveAccent(String key, {bool isDark = false}) {
    if (key == 'blue') return isDark ? iosDarkBlue : iosBlue;
    if (key == 'indigo') return isDark ? iosDarkIndigo : iosIndigo;
    if (key == 'green') return isDark ? iosDarkGreen : iosGreen;
    if (key == 'orange') return isDark ? iosDarkOrange : iosOrange;
    return accentChoices[key] ?? (isDark ? iosDarkBlue : iosBlue);
  }
}

class TalkoraTheme {
  const TalkoraTheme._();

  /// iOS SF Pro Display / SF Pro Text typography metrics with crisp Arabic Tajawal fallback
  static TextTheme _buildIosTextTheme(
    TextTheme base,
    bool isArabic,
    Color mainText,
    Color secondaryText,
  ) {
    final fontTheme = isArabic
        ? GoogleFonts.tajawalTextTheme(base)
        : GoogleFonts.interTextTheme(base);

    const iosFontFallback = <String>[
      '.SF UI Display',
      '.SF UI Text',
      'SF Pro Display',
      'SF Pro Text',
      'Helvetica Neue',
    ];

    TextStyle? applyIos(
      TextStyle? style, {
      double? size,
      FontWeight? weight,
      double? letterSpacing,
      double? height,
      Color? color,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: isArabic ? 0 : letterSpacing,
        height: height,
        color: color,
        fontFamilyFallback: isArabic ? null : iosFontFallback,
      );
    }

    return fontTheme.copyWith(
      // iOS Large Title (34pt Bold)
      headlineLarge: applyIos(
        fontTheme.headlineLarge,
        size: 32,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: mainText,
      ),
      // iOS Title 1 (26pt Bold)
      headlineMedium: applyIos(
        fontTheme.headlineMedium,
        size: 25,
        weight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.22,
        color: mainText,
      ),
      // iOS Title 2 (21pt Bold)
      headlineSmall: applyIos(
        fontTheme.headlineSmall,
        size: 21,
        weight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.25,
        color: mainText,
      ),
      // iOS Title 3 (19pt Semibold)
      titleLarge: applyIos(
        fontTheme.titleLarge,
        size: 19,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.28,
        color: mainText,
      ),
      // iOS Headline (16.5pt Semibold)
      titleMedium: applyIos(
        fontTheme.titleMedium,
        size: 16.5,
        weight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.3,
        color: mainText,
      ),
      // iOS Body (16pt Regular)
      bodyLarge: applyIos(
        fontTheme.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.45,
        color: mainText,
      ),
      // iOS Subheadline (14pt Regular)
      bodyMedium: applyIos(
        fontTheme.bodyMedium,
        size: 14,
        weight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: secondaryText,
      ),
      // iOS Footnote / Caption (12.5pt)
      bodySmall: applyIos(
        fontTheme.bodySmall,
        size: 12.5,
        weight: FontWeight.w400,
        color: secondaryText,
      ),
      labelLarge: applyIos(
        fontTheme.labelLarge,
        size: 15,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  static ThemeData light({required bool isArabic, String accentKey = 'blue'}) {
    final accent = TalkoraColors.resolveAccent(accentKey, isDark: false);
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: TalkoraColors.lightBackground,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: accent,
        scaffoldBackgroundColor: TalkoraColors.lightBackground,
        barBackgroundColor: TalkoraColors.lightSurface,
      ),
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: TalkoraColors.iosIndigo,
        surface: TalkoraColors.lightSurface,
        error: TalkoraColors.iosRed,
        onPrimary: Colors.white,
        onSurface: TalkoraColors.lightMainText,
      ),
      textTheme: _buildIosTextTheme(
        base.textTheme,
        isArabic,
        TalkoraColors.lightMainText,
        TalkoraColors.lightSecondaryText,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: TalkoraColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: TalkoraColors.lightSeparator.withValues(alpha: 0.35), width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: TalkoraColors.lightBackground.withValues(alpha: 0.94),
        foregroundColor: TalkoraColors.lightMainText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: TalkoraColors.lightMainText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: isArabic ? 0 : -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TalkoraColors.lightSeparator,
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TalkoraColors.lightFill.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData dark({required bool isArabic, String accentKey = 'blue'}) {
    final accent = TalkoraColors.resolveAccent(accentKey, isDark: true);
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: TalkoraColors.darkBackground,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: accent,
        scaffoldBackgroundColor: TalkoraColors.darkBackground,
        barBackgroundColor: TalkoraColors.darkSurface,
      ),
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: TalkoraColors.iosDarkIndigo,
        surface: TalkoraColors.darkSurface,
        error: TalkoraColors.iosDarkRed,
        onPrimary: Colors.white,
        onSurface: TalkoraColors.darkText,
      ),
      textTheme: _buildIosTextTheme(
        base.textTheme,
        isArabic,
        TalkoraColors.darkText,
        TalkoraColors.darkSecondaryText,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: TalkoraColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: TalkoraColors.darkSeparator.withValues(alpha: 0.6), width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: TalkoraColors.darkBackground.withValues(alpha: 0.94),
        foregroundColor: TalkoraColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: TalkoraColors.darkText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: isArabic ? 0 : -0.4,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TalkoraColors.darkSeparator,
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TalkoraColors.darkFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    );
  }
}
