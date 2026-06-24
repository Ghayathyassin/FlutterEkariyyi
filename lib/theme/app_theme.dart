import 'package:flutter/material.dart';

/// Central design system for the LRC app.
///
/// The brand colours are intentionally unchanged (green [primary], red
/// [danger], grey [neutral], the dark [drawerBg]). What this file adds is a
/// consistent, modern *treatment* of those colours: spacing scale, corner
/// radii, soft shadows, typography and component themes so every screen looks
/// like part of the same product.
class AppColors {
  AppColors._();

  /// Primary brand green (unchanged).
  static const Color primary = Color(0xff006401);
  static const Color primaryDark = Color(0xff004d01);

  /// Action / danger red (unchanged).
  static const Color danger = Color(0xff8c0000);
  static const Color dangerDark = Color(0xff6e0000);

  /// Neutral / secondary grey (unchanged).
  static const Color neutral = Color(0xff6f6f6f);

  /// Dark side-drawer background (unchanged).
  static const Color drawerBg = Color(0xff1f1f1f);
  static const Color drawerSurface = Color(0xff2a2a2a);
  static const Color drawerSelected = Color(0xff549fd7);

  /// App surfaces.
  static const Color scaffold = Color(0xfff4f6f8);
  static const Color surface = Colors.white;

  /// Header strip behind in-screen titles (kept in the brand's light grey,
  /// just cleaner).
  static const Color headerBg = Color(0xffeef1f4);

  static const Color textPrimary = Color(0xff1f2933);
  static const Color textSecondary = Color(0xff6b7280);
  static const Color border = Color(0xffe3e8ee);
  static const Color success = Color(0xff1b8a3a);

  /// Accent colours — all already used elsewhere in the app (the blue is the
  /// drawer-selected blue, the amber is the "in progress" stage colour). Used
  /// to give each service its own identity without adding new brand hues.
  static const Color info = Color(0xff549fd7); // blue
  static const Color amber = Color(0xffe6a700); // gold (stage "in progress")
  static const Color primarySoft = Color(0xffeaf2ea);

  /// Tinted background for an accent chip (12% of the accent over white).
  static Color tint(Color accent) => Color.alphaBlend(
        accent.withOpacity(0.12),
        Colors.white,
      );
}

/// Spacing scale (multiples of 4) used across screens for consistent rhythm.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii.
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Reusable soft shadows.
class AppShadows {
  AppShadows._();
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Typographic scale. Keeps the bundled font but sets deliberate sizes,
/// weights, line-heights and letter-spacing so the UI reads as designed, not
/// hand-sized. Use these instead of writing `fontSize` inline.
class AppType {
  AppType._();

  static const TextStyle display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );
  static const TextStyle title = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14.5,
    height: 1.45,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textSecondary,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AppColors.primary,
  );
}

/// Brand gradient used on the app bar and primary surfaces.
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryDark],
);

/// Ready-made button styles so screens don't re-declare colours inline.
class AppButtons {
  AppButtons._();

  static ButtonStyle _base(Color bg) => ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 1.5,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle primary() => _base(AppColors.primary);
  static ButtonStyle danger() => _base(AppColors.danger);
  static ButtonStyle neutral() => _base(AppColors.neutral);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primary,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.scaffold,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .copyWith(
            headlineSmall: AppType.display,
            titleLarge: AppType.h1,
            titleMedium: AppType.title,
            bodyLarge: AppType.body,
            bodyMedium: AppType.body,
            bodySmall: AppType.caption,
            labelLarge: AppType.label,
          )
          .apply(fontFamily: 'Segoe UI'),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.neutral,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary()),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Segoe UI',
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontFamily: 'Segoe UI',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
