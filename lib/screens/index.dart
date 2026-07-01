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
        customIcon: _llShape(28),
        accent: AppColors.primary,
      ),
    ];

    final int crossAxisCount = wide ? 3 : 2;

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
            // Home-only welcome banner, flowing straight out of the green
            // app bar above it (rounded bottom). Eases down on load.
            AppReveal(dy: -12, child: _buildWelcome(isEnglish, pad)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    pad, AppSpacing.lg, pad, AppSpacing.lg),
                // The grid sizes itself to the available height so all tiles
                // fit on one screen with no scrolling.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final int rows =
                        (categories.length / crossAxisCount).ceil();
                    const spacing = AppSpacing.md;
                    final double cellWidth = (constraints.maxWidth -
                            spacing * (crossAxisCount - 1)) /
                        crossAxisCount;
                    final double cellHeight =
                        (constraints.maxHeight - spacing * (rows - 1)) / rows;
                    final double aspect =
                        cellHeight <= 0 ? 1.0 : cellWidth / cellHeight;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: aspect,
                      // Tiles cascade in after the banner, one stagger step
                      // apart, for an orchestrated home-screen entrance.
                      children: [
                        for (int i = 0; i < categories.length; i++)
                          AppReveal(
                            delay: const Duration(milliseconds: 140) +
                                AppMotion.stagger * i,
                            child: categories[i],
                          ),
                      ],
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33004d01),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(pad, AppSpacing.md, pad, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnglish
                ? 'LAND REGISTRY & CADASTRE'
                : 'المديرية العامة للشؤون العقارية',
            style: AppType.eyebrow.copyWith(
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEnglish ? 'Welcome' : 'مرحباً بك',
            style: AppType.display.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
