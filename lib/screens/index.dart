import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drawer_state.dart';
import 'package:flutter_application_1/widgets/category.dart';
import 'package:flutter_application_1/widgets/custom_app_bar.dart';
import 'package:flutter_application_1/widgets/language_switch_button.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

class Index extends StatelessWidget {
  final Function(Locale) onLocaleChange;
  @override
  // ignore: overridden_fields
  final Key? key;

  const Index({required this.onLocaleChange, this.key}) : super(key: key);

  void _navigateTo(BuildContext context, int index, String route) {
    Provider.of<DrawerState>(context, listen: false).setSelectedIndex(index);
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final width = MediaQuery.of(context).size.width;
    final bool wide = width >= 600;
    final double pad = wide ? 24 : 16;
    final int crossAxisCount = wide ? 3 : 2;

    final categories = <Widget>[
      Category(
        function: () => _navigateTo(context, 1, '/titleRegister'),
        title: S.of(context).titleRegister,
        description: isEnglish ? 'Request property records' : 'طلب بيانات عقارية',
        icon: Icons.menu_book_rounded,
        accent: AppColors.primary,
      ),
      Category(
        function: () => _navigateTo(context, 2, '/transactionTracking'),
        title: S.of(context).transactionTracking,
        description: isEnglish ? 'Track your application' : 'تتبّع معاملتك',
        icon: Icons.fact_check_outlined,
        accent: AppColors.info,
      ),
      Category(
        function: () => _navigateTo(context, 4, '/titleRegisterChange'),
        title: S.of(context).titleRegisterChanges,
        description: isEnglish ? 'Sign in to manage' : 'تسجيل الدخول للتعديل',
        icon: Icons.edit_document,
        accent: AppColors.amber,
      ),
      Category(
        function: () => _navigateTo(context, 3, '/feesSimulation'),
        title: S.of(context).feesSimulation,
        description: isEnglish ? 'Estimate fees' : 'احتساب الرسوم',
        icon: Icons.calculate_rounded,
        accent: AppColors.danger,
      ),
      Category(
        function: () => _navigateTo(context, 5, '/ownershipTracking'),
        title: S.of(context).ownershipReqTracking,
        description: isEnglish ? 'Track ownership request' : 'تتبّع طلب الملكية',
        icon: Icons.vpn_key_outlined,
        accent: AppColors.info,
      ),
      Category(
        function: () => _navigateTo(context, 6, '/paidInvoices'),
        title: S.of(context).paidInvoices,
        description: isEnglish ? 'Find paid invoices' : 'الفواتير المدفوعة',
        icon: Icons.receipt_long_rounded,
        accent: AppColors.primary,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
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
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppReveal(dy: -8, child: _buildWelcome(isEnglish, pad)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, pad),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Stretch the tiles to fill the available space so the grid
                    // fits any screen without scrolling: derive the row height
                    // from the space left below the header.
                    const double spacing = 14;
                    final int rows =
                        (categories.length / crossAxisCount).ceil();
                    final double tileExtent =
                        (constraints.maxHeight - spacing * (rows - 1)) / rows;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: tileExtent,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      itemCount: categories.length,
                      // Reveal the tiles row by row, top to bottom: both tiles
                      // in a row share the same delay, keyed to the row index,
                      // so the grid cascades down after the header appears.
                      itemBuilder: (context, i) {
                        final int row = i ~/ crossAxisCount;
                        return AppReveal(
                          delay: const Duration(milliseconds: 260) +
                              const Duration(milliseconds: 110) * row,
                          dy: 18,
                          child: categories[i],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(bool isEnglish, double pad) {
    // Arabic script is cursive — letter‑spacing splits the joined glyphs and
    // reads as the letters being "cut off", so it is dropped for Arabic.
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: isEnglish ? 0.5 : 0,
      color: Colors.white,
    );
    final subStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: isEnglish ? 0.8 : 0,
      color: Colors.white.withOpacity(0.85),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadius.banner)),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnglish
                  ? 'LAND REGISTRY & CADASTRE'
                  : 'المديرية العامة للشؤون العقارية',
              style: titleStyle,
            ),
            const SizedBox(height: 6),
            Text(
              isEnglish ? 'Republic of Lebanon' : 'الجمهورية اللبنانية',
              style: subStyle,
            ),
            const SizedBox(height: 2),
            Text(
              isEnglish ? 'Ministry of Finance' : 'وزارة المالية',
              style: subStyle,
            ),
          ],
        ),
      ),
    );
  }
}
