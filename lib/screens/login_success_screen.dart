import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_header.dart';
import '../widgets/language_switch_button.dart';

/// TEMPORARY landing shown after a successful login. The real post‑login screen
/// (which uses [profileId]) is not built yet — for now this just confirms the
/// sign‑in. [profileId] is carried through so it's ready to wire up later.
class LoginSuccessScreen extends StatelessWidget {
  final Function(Locale) onLocaleChange;
  final String username;
  final int profileId;

  const LoginSuccessScreen({
    required this.onLocaleChange,
    required this.username,
    required this.profileId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: '',
          actions: [
            LanguageSwitchButton(
              onLocaleChange: onLocaleChange,
              isEnglish: isEnglish,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(title: S.of(context).titleRegisterChanges),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.greenTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline,
                            size: 46, color: AppColors.success),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        isEnglish
                            ? 'Signed in successfully'
                            : 'تم تسجيل الدخول بنجاح',
                        textAlign: TextAlign.center,
                        style: AppType.h1,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isEnglish ? 'Welcome, $username' : 'أهلاً، $username',
                        textAlign: TextAlign.center,
                        style: AppType.bodyMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
