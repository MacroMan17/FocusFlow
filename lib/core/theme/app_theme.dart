import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Token Constants
// ─────────────────────────────────────────────────────────────────────────────

// Color palette — Jungle theme
const kBg = Color(0xFF070D1A); // jungle near-black
const kBg2 = Color(0xFF0D1628); // card bg
const kGlass = Color(0x1AFFFFFF); // glass surface
const kPrimary = Color(0xFF00C896); // jungle teal / primary green
const kAccent = Color(0xFF00E5FF); // accent cyan
const kCompleted = Color(0xFF2ECC71); // green
const kWarning = Color(0xFFF39C12); // amber
const kOverdue = Color(0xFFFF5C7A); // red-pink
const kText = Color(0xFFFFFFFF); // white
const kTextSec = Color(0xFF8899AA); // secondary text
const kDivider = Color(0x18FFFFFF); // divider

// Spacing
const kPad = 24.0; // screen padding
const kSecGap = 32.0; // between sections
const kCardGap = 16.0; // between cards
const kTextGap = 8.0; // between text
const kCardPad = 20.0; // card internal padding

// Radii
const kCardRadius = 24.0;
const kChipRadius = 20.0;
const kNavRadius = 28.0;

// ─────────────────────────────────────────────────────────────────────────────
// App Theme Builder
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build();

  /// Light variant kept for API compatibility — uses same design language
  static ThemeData light(int _) => _build();

  static ThemeData _build() {
    const cs = ColorScheme.dark(
      brightness: Brightness.dark,
      surface: kBg,
      surfaceContainerLow: kBg2,
      surfaceContainerHighest: Color(0xFF0D1628),
      primary: kPrimary,
      onPrimary: kBg,
      primaryContainer: Color(0x2600C896),
      onPrimaryContainer: kPrimary,
      secondary: kAccent,
      onSecondary: kBg,
      secondaryContainer: Color(0x2200E5FF),
      onSecondaryContainer: kAccent,
      error: kOverdue,
      onError: kText,
      errorContainer: Color(0x33FF5C7A),
      onErrorContainer: kOverdue,
      onSurface: kText,
      onSurfaceVariant: kTextSec,
      outline: Color(0x33FFFFFF),
      outlineVariant: kDivider,
      inverseSurface: Color(0xFFE8F5E9),
      onInverseSurface: kBg,
      inversePrimary: kPrimary,
    );

    // Typography — Inter preferred, system fallback
    const fontFamily = 'Inter';

    final tt = _buildTextTheme(fontFamily);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: kBg,
      fontFamily: fontFamily,
      textTheme: tt,

      // ── Status bar ──────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: kBg,
        foregroundColor: kText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: kBg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: kText,
          letterSpacing: -0.3,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        elevation: 0,
        color: kGlass,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kCardRadius)),
          side: BorderSide(color: kDivider, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Chips ──────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: kGlass,
        selectedColor: Color(0x336C63FF),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: kTextSec,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        shape: const StadiumBorder(),
        side: const BorderSide(color: kDivider),
        elevation: 0,
      ),

      // ── Input ──────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kBg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kOverdue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: kTextSec, fontSize: 15),
        labelStyle: const TextStyle(color: kTextSec, fontSize: 15),
      ),

      // ── Dividers ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: kDivider,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kBg2,
        contentTextStyle: const TextStyle(color: kText, fontSize: 14),
        actionTextColor: kAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kDivider),
        ),
      ),

      // ── Buttons ────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: kBg,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(0, 56),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kPrimary,
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500),
        ),
      ),

      // ── Navigation bar (unused, replaced by custom) ────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kBg2,
        height: 78,
        indicatorColor: Color(0x336C63FF),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? kPrimary : kTextSec,
            )),
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 8,
        backgroundColor: kPrimary,
        foregroundColor: kText,
        shape: CircleBorder(),
      ),
    );
  }

  static TextTheme _buildTextTheme(String family) {
    // Matches the spec: greeting 36/Bold, quote 18/Regular italic,
    // section 22/SemiBold, card title 18/Medium, etc.
    return TextTheme(
      // Greeting headline  36sp Bold
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: kText,
        letterSpacing: -0.5,
        height: 42 / 36,
      ),
      // Section titles  22sp SemiBold
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: kText,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      // Settings titles / card header  18sp Medium
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: kText,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      // Quote body  18sp Regular italic
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        color: kText,
        height: 28 / 18,
      ),
      // Card titles  18sp Medium
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: kText,
        height: 1.3,
      ),
      // Task description / settings subtitle  15sp Regular
      titleSmall: TextStyle(
        fontFamily: family,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: kTextSec,
        height: 1.4,
      ),
      // Body text
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: kText,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: kTextSec,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: kTextSec,
        height: 1.4,
      ),
      // Navigation labels  13sp Medium
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kTextSec,
        height: 1.2,
      ),
      // Category chips  14sp Medium
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kTextSec,
        height: 1.2,
      ),
      // Stats label  15sp Medium
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kTextSec,
        height: 1.2,
      ),
    );
  }
}
