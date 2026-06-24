import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drawer_state.dart';
import 'package:flutter_application_1/widgets/category.dart';
import 'package:flutter_application_1/widgets/side_drawer.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

  // The custom "L.L" mark used for the Paid Invoices tile.
  Widget _llShape(double size) {
    Widget singleL() => Expanded(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: size * 0.15,
                  height: size,
                  color: AppColors.primary,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: size * 0.4,
                  height: size * 0.15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          singleL(),
          const SizedBox(width: 2),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(width: 4, height: 4, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 2),
          singleL(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isEnglish = locale.languageCode == 'en';
    final width = MediaQuery.of(context).size.width;
    final bool wide = width > 600;
    final double pad = wide ? 32 : 20;

    final categories = <Widget>[
      Category(
        function: () => _navigateTo(context, 1, '/titleRegister'),
        title: S.of(context).titleRegister,
        icon: FontAwesomeIcons.filePen,
        accent: AppColors.primary,
      ),
      Category(
        function: () => _navigateTo(context, 2, '/transactionTracking'),
        title: S.of(context).transactionTracking,
        icon: FontAwesomeIcons.listCheck,
        accent: AppColors.info,
      ),
      Category(
        function: () => _navigateTo(context, 4, '/titleRegisterChange'),
        title: S.of(context).titleRegisterChanges,
        icon: FontAwesomeIcons.pencil,
        accent: AppColors.amber,
      ),
      Category(
        function: () => _navigateTo(context, 3, '/feesSimulation'),
        title: S.of(context).feesSimulation,
        icon: Icons.calculate_outlined,
        accent: AppColors.danger,
      ),
      Category(
        function: () => _navigateTo(context, 5, '/ownershipTracking'),
        title: S.of(context).ownershipReqTracking,
        icon: FontAwesomeIcons.streetView,
        accent: AppColors.info,
      ),
      Category(
        function: () => _navigateTo(context, 6, '/paidInvoices'),
        title: S.of(context).paidInvoices,
        customIcon: _llShape(22),
        accent: AppColors.primary,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      drawer: const SideDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isEnglish, pad),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.lg, pad, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEnglish ? 'Services' : 'الخدمات', style: AppType.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isEnglish ? 'Choose a service to begin' : 'اختر خدمة للبدء',
                    style: AppType.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: wide ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.0,
                    children: categories,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEnglish, double pad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33004d01),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, AppSpacing.sm, pad, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (ctx) => _iconPill(
                      icon: Icons.menu,
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 30,
                    child: Image.asset('assets/images/logoHeader.png'),
                  ),
                  const Spacer(),
                  _langPill(isEnglish),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isEnglish ? 'LAND REGISTRY & CADASTRE' : 'السجل العقاري والمساحة',
                style: AppType.eyebrow.copyWith(
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isEnglish ? 'Welcome' : 'مرحباً بك',
                style: AppType.display.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isEnglish
                    ? 'What would you like to do today?'
                    : 'ماذا تريد أن تنجز اليوم؟',
                style: AppType.body.copyWith(
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconPill({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _langPill(bool isEnglish) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () =>
            onLocaleChange(isEnglish ? const Locale('ar') : const Locale('en')),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                isEnglish ? 'العربية' : 'EN',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
