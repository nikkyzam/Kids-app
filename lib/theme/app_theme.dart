import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryLight = Color(0xFFEEF3FE);
  static const Color secondary = Color(0xFFF5A623);
  static const Color surface = Color(0xFFFAFBFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1D2E);
  static const Color textMuted = Color(0xFF8E93A6);
  static const Color success = Color(0xFF4CAF7D);
  static const Color successLight = Color(0xFFE8F8EF);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);

  static const Color grossMotorColor = Color(0xFF5B8DEF);
  static const Color fineMotorColor = Color(0xFF9C6FDE);
  static const Color languageColor = Color(0xFF26C6DA);
  static const Color cognitiveColor = Color(0xFFF5A623);
  static const Color socialEmotionalColor = Color(0xFFFF7043);
  static const Color sensoryColor = Color(0xFF66BB6A);

  /// Hairline used where a surface needs definition without a shadow.
  static const Color border = Color(0xFFEBEEF6);

  static const String _font = 'Nunito';

  /// Corner radius for cards. Shared so that anything drawing its own surface
  /// inside a Card (e.g. a tinted header) can match the clip exactly.
  static const double cardRadius = 20;

  // --- Elevation -----------------------------------------------------------
  // Tinted rather than neutral-grey shadows: a shadow carrying a little of the
  // brand hue reads as soft daylight instead of dirt, which suits a warm,
  // child-focused app better than Material's default black-alpha elevation.

  /// Resting shadow for cards and other raised surfaces.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0D2B3A67),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x08151C33),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Stronger shadow for elements that should feel lifted (FAB, dialogs).
  static const List<BoxShadow> liftedShadow = [
    BoxShadow(
      color: Color(0x1A2B3A67),
      blurRadius: 28,
      offset: Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  /// Coloured glow under a primary action, tying the button to the brand.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.32),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
        ),
        scaffoldBackgroundColor: surface,
        fontFamily: _font,
        splashFactory: InkSparkle.splashFactory,

        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: _font,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.3,
          ),
        ),

        cardTheme: CardThemeData(
          color: cardBg,
          // A soft tinted shadow instead of a flat hairline, so cards sit above
          // the background rather than being drawn onto it. surfaceTintColor is
          // cleared because M3's elevation tint would grey the white card.
          elevation: 3,
          shadowColor: const Color(0x1A2B3A67),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE8EBF3),
            disabledForegroundColor: textMuted,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: _font,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: _font,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // Display sizes get progressively tighter tracking — large text set at
        // default spacing looks loose, small text set tight looks cramped.
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textDark,
            letterSpacing: -0.3,
            height: 1.25,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textDark,
            letterSpacing: -0.1,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textDark,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textMuted,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textDark,
            letterSpacing: 0.1,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F6FB),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          hintStyle: const TextStyle(
            fontFamily: _font,
            color: textMuted,
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFEDF0F7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
        ),

        // The components below previously fell back to Material defaults, which
        // shipped square corners and Roboto in the middle of a rounded UI.
        dialogTheme: DialogThemeData(
          backgroundColor: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: -0.3,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            color: textMuted,
            height: 1.5,
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: cardBg,
          elevation: 0,
          showDragHandle: true,
          dragHandleColor: Color(0xFFD8DDEA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: textDark,
          contentTextStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.all(16),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F4FB),
          selectedColor: primaryLight,
          side: BorderSide.none,
          labelStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textMuted,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: _font,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),

        listTileTheme: const ListTileThemeData(
          titleTextStyle: TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          subtitleTextStyle: TextStyle(
            fontFamily: _font,
            fontSize: 13,
            color: textMuted,
            height: 1.4,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),

        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardBg,
          surfaceTintColor: Colors.transparent,
          indicatorColor: primaryLight,
          elevation: 0,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontFamily: _font,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? primary : textMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 24,
              color: selected ? primary : textMuted,
            );
          }),
        ),

        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: Color(0xFFE9EDF7),
          circularTrackColor: Color(0xFFE9EDF7),
        ),
      );
}
