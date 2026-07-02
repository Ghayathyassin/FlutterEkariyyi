import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_application_1/screens/index.dart';
import '../theme/app_theme.dart';

/// "Choose your language" screen. Two selectable cards (English / العربية) with
/// an animated selection state, then a full‑width Continue button that commits
/// the locale via [onLocaleChange] and advances to the home dashboard.
class MainScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const MainScreen({required this.onLocaleChange, super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  // Only 'en' / 'ar' are supported. Default to the device locale when it is one
  // of ours, otherwise English.
  late String _selected =
      _isSupported(WidgetsBinding.instance.platformDispatcher.locale)
          ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
          : 'en';

  bool _isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    // Keep the status strip brand‑green with light icons on this screen.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  void _continue() {
    final locale = Locale(_selected);
    widget.onLocaleChange(locale);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Index(onLocaleChange: widget.onLocaleChange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = _selected == 'ar';

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // LRC mark.
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.card,
                  ),
                  child: Image.asset(
                    'assets/images/logoMain.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'اختر لغتك',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _LanguageCard(
                        badge: 'EN',
                        label: 'English',
                        selected: _selected == 'en',
                        onTap: () => setState(() => _selected = 'en'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _LanguageCard(
                        badge: 'ع',
                        label: 'العربية',
                        isArabic: true,
                        selected: _selected == 'ar',
                        onTap: () => setState(() => _selected = 'ar'),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  onPressed: _continue,
                  child: Text(
                    isAr ? 'متابعة' : 'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: isAr
                          ? GoogleFonts.ibmPlexSansArabic().fontFamily
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single selectable language card — a circular badge, the language label,
/// and a selection caption. The selection transition is animated.
class _LanguageCard extends StatelessWidget {
  final String badge;
  final String label;
  final bool selected;
  final bool isArabic;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.badge,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.greenTint, Color(0xffd5edda)],
                  )
                : null,
            color: selected ? null : const Color(0xfff0f2f5),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: isArabic ? 24 : 18,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.neutral,
              fontFamily:
                  isArabic ? GoogleFonts.ibmPlexSansArabic().fontFamily : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.smd),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily:
                isArabic ? GoogleFonts.ibmPlexSansArabic().fontFamily : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          selected
              ? (isArabic ? '● محدّد' : '● Selected')
              : (isArabic ? 'اضغط للاختيار' : 'Tap to select'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontFamily:
                isArabic ? GoogleFonts.ibmPlexSansArabic().fontFamily : null,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.banner),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppShadows.subtle,
        ),
        child: isArabic
            ? Directionality(textDirection: TextDirection.rtl, child: content)
            : content,
      ),
    );
  }
}
