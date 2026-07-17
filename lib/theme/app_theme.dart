import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for the LRC app — "The Cadastral Line" redesign.
///
/// Faithful to the LRC Redesign Spec: fixed brand palette (only neutrals tuned),
/// IBM Plex type (Cairo for Arabic), 4dp spacing, precise radii, a
/// hairline‑first elevation model,
/// and the survey‑linework signature (see `app_decor.dart`). Every screen pulls
/// from these tokens — never hardcode styling.
class AppColors {
  AppColors._();

  /// Primary brand green.
  static const Color primary = Color(0xff006401);
  static const Color primaryDark = Color(0xff004d01);

  /// Action red — the ONE primary CTA per screen (Add / Calculate / Show /
  /// Login). Action, not error.
  static const Color danger = Color(0xff8c0000);
  static const Color dangerDark = Color(0xff6e0000);

  /// Confirm / success green (Submit, Proceed, success banner, "stage done").
  static const Color success = Color(0xff1b8a3a);

  /// Neutral grey — reset / secondary buttons.
  static const Color neutral = Color(0xff6f6f6f);

  /// Dark side‑drawer.
  static const Color drawerBg = Color(0xff1f1f1f);
  static const Color drawerSurface = Color(0xff2a2a2a);
  static const Color drawerSelected = Color(0xff549fd7);

  /// App surfaces.
  static const Color scaffold = Color(0xfff4f6f8);
  static const Color surface = Color(0xffffffff);
  static const Color paper = Color(0xfffbfcfd);
  static const Color headerBg = Color(0xffffffff);

  static const Color textPrimary = Color(0xff1f2933);
  static const Color textSecondary = Color(0xff6b7280);
  static const Color disabled = Color(0xff9aa4b0);
  static const Color disabledStrong = Color(0xffc2cad3);

  /// Hairline rules / borders / dividers.
  static const Color line = Color(0xffe3e8ee);
  static const Color border = line; // back‑compat alias

  /// Accents (all pre‑existing brand hues).
  static const Color info = Color(0xff549fd7); // blue
  static const Color amber = Color(0xffe6a700); // gold
  static const Color amberText = Color(0xffb3830a); // AA on amber tint

  /// Tints (icon chips, selected fields, banners, totals).
  static const Color greenTint = Color(0xffeaf3ea);
  static const Color blueTint = Color(0xffe7f1fa);
  static const Color amberTint = Color(0xfffdf3d7);
  static const Color redTint = Color(0xfffbeaea);
  static const Color primarySoft = greenTint; // back‑compat alias

  /// The tint that matches a given accent (falls back to a computed 12% blend).
  static Color tintFor(Color accent) {
    if (accent == primary || accent == success) return greenTint;
    if (accent == info) return blueTint;
    if (accent == amber) return amberTint;
    if (accent == danger) return redTint;
    return tint(accent);
  }

  /// Generic accent tint (~12% of the accent over white).
  static Color tint(Color accent) =>
      Color.alphaBlend(accent.withOpacity(0.12), Colors.white);
}

/// Spacing — 4dp base.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double smd = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii: 8 fields · 12 buttons · 16 cards · 20 banner · 999 pill.
class AppRadius {
  AppRadius._();
  static const double sm = 8; // fields
  static const double md = 12; // buttons
  static const double lg = 16; // cards
  static const double banner = 20;
  static const double xl = 20; // back‑compat alias (was 24)
  static const double pill = 999;
}

/// Elevation model — hairline first.
/// e0 = border only (no shadow). e1 = card lift. e2 = sheets/dialogs.
class AppShadows {
  AppShadows._();

  /// e1 — Home tiles / raised cards.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0f1f2933), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0d1f2933), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Lighter single‑layer lift.
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0d1f2933), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// e2 — sheets / dialogs.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x1f1f2933), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

/// Type scale (applied via [AppTheme]). These carry size/weight/tracking/
/// height only — the font family is set by the themed [TextTheme] and
/// inherited through `DefaultTextStyle`, so Arabic screens get Cairo
/// automatically (with letter-spacing zeroed — never track Arabic).
class AppType {
  AppType._();

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  static const TextStyle title = h2;
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMuted = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Monospaced, tabular figures — reference IDs, parcel/unit/block numbers,
  /// and monetary amounts. IBM Plex Mono.
  static TextStyle mono({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// Brand gradient (≈135°) — masthead, banner, primary surfaces.
const LinearGradient kPrimaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryDark],
);

/// Ready‑made button styles. Semantics per spec:
/// `danger` = the red primary CTA, `primary`/`confirm` = green confirm/advance,
/// `neutral` = grey reset.
class AppButtons {
  AppButtons._();

  static ButtonStyle _base(Color bg, Color pressed) => ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        disabledBackgroundColor: bg.withOpacity(0.45),
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(pressed.withOpacity(0.9)),
      );

  static ButtonStyle primary() => _base(AppColors.success, AppColors.primary);
  static ButtonStyle confirm() => primary();
  static ButtonStyle danger() => _base(AppColors.danger, AppColors.dangerDark);
  static ButtonStyle neutral() =>
      _base(AppColors.neutral, const Color(0xff585858));
}

class AppTheme {
  AppTheme._();

  /// Builds the light theme. [isArabic] swaps the base UI family to Cairo so
  /// the whole RTL UI is set in a first‑class Arabic face.
  static ThemeData light({bool isArabic = false}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primary,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.scaffold,
    );

    // Map our scale onto the Material roles, then apply the UI family to
    // every entry (Cairo for Arabic, IBM Plex Sans otherwise). Arabic strips
    // any letter-spacing — tracking breaks Arabic's cursive joins.
    TextStyle localized(TextStyle style) =>
        isArabic ? style.copyWith(letterSpacing: 0) : style;
    final scaled = base.textTheme.copyWith(
      headlineSmall: localized(AppType.display),
      titleLarge: localized(AppType.h1),
      titleMedium: localized(AppType.title),
      bodyLarge: localized(AppType.body),
      bodyMedium: localized(AppType.body),
      bodySmall: localized(AppType.caption),
      labelLarge: localized(AppType.label),
    );
    final textTheme = isArabic
        ? GoogleFonts.cairoTextTheme(scaled)
        : GoogleFonts.ibmPlexSansTextTheme(scaled);
    final uiFamily = isArabic
        ? GoogleFonts.cairo().fontFamily
        : GoogleFonts.ibmPlexSans().fontFamily;

    return base.copyWith(
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
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
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: AppColors.disabled),
        prefixIconColor: AppColors.neutral,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary()),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: uiFamily,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontFamily: uiFamily,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.drawerBg,
        actionTextColor: AppColors.drawerSelected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
