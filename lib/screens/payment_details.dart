import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/custom_card_widget_row.dart';
import 'package:flutter_application_1/widgets/custom_header.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';

class PaymentDetails extends StatelessWidget {
  final Function(Locale) onLocaleChange;
  final String id;
  final String name;
  final String lastName;
  final String mobile;
  final String email;
  final String city;
  final String address;

  const PaymentDetails({
    super.key,
    required this.onLocaleChange,
    required this.id,
    required this.name,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.city,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    var locale = Localizations.localeOf(context);
    var isEnglish = locale.languageCode == 'en';

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: '',
          actions: [
            LanguageSwitchButton(
              onLocaleChange: onLocaleChange,
              isEnglish: isEnglish,
              reload: false,
            ),
          ],
        ),
        drawer: const SideDrawer(),
        body: Column(
          children: [
            CustomHeader(
              title: isEnglish ? 'Payment Details' : 'تفاصيل الطلب',
              goBack: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _confirmationBanner(isEnglish),
                    const SizedBox(height: AppSpacing.md),
                    CustomCardWidgetRow(
                      content: [
                        {'title': 'ID', 'description': id},
                        {'title': S.of(context).firstName, 'description': name},
                        {
                          'title': S.of(context).lastName,
                          'description': lastName
                        },
                        {
                          'title': S.of(context).telephone,
                          'description': mobile
                        },
                        {'title': S.of(context).email, 'description': email},
                        {'title': S.of(context).city, 'description': city},
                        {
                          'title': S.of(context).address,
                          'description': address
                        },
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: AppButtons.primary(),
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/index'),
                        icon: const Icon(Icons.home_outlined, size: 20),
                        label: Text(
                          isEnglish
                              ? 'Back To Home Screen'
                              : 'العودة إلى الصفحة الرئيسية',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmationBanner(bool isEnglish) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isEnglish
                  ? 'Your request has been recorded. Keep your ID for later use.'
                  : 'تم تسجيل طلبك. احتفظ بالمعرّف لاستخدامه لاحقًا.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
