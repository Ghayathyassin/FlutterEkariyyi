import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../generated/l10n.dart';
import '../models/drawer_state.dart';
import '../theme/app_theme.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  static const List<IconData> drawerIcons = [
    Icons.home_outlined,
    FontAwesomeIcons.filePen,
    FontAwesomeIcons.listCheck,
    Icons.calculate_outlined,
    FontAwesomeIcons.pencil,
    FontAwesomeIcons.streetView,
    Icons.receipt_long_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final drawerList = [
      S.of(context).homepage,
      S.of(context).titleRegister,
      S.of(context).transactionTracking,
      S.of(context).feesSimulation,
      S.of(context).titleRegisterChanges,
      S.of(context).ownershipReqTracking,
      S.of(context).paidInvoices,
    ];

    return Drawer(
      backgroundColor: AppColors.drawerBg,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: kPrimaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset('assets/images/logoHeader.png'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isEnglish
                          ? 'Land Registry & Cadastre'
                          : 'السجل العقاري والمساحة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Consumer<DrawerState>(
              builder: (context, drawerState, _) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: drawerList.length,
                itemBuilder: (context, index) {
                  final bool isSelected = drawerState.selectedIndex == index;
                  final Color fg = isSelected
                      ? AppColors.drawerSelected
                      : Colors.white.withOpacity(0.82);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: isSelected
                          ? AppColors.drawerSelected.withOpacity(0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () {
                          drawerState.setSelectedIndex(index);
                          _navigateToScreen(context, index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          child: Row(
                            children: [
                              Icon(drawerIcons[index], color: fg, size: 21),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  drawerList[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : fg,
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.chevron_right,
                                    color: AppColors.drawerSelected, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    color: Colors.white.withOpacity(0.4), size: 16),
                const SizedBox(width: 8),
                Text(
                  'LRC  •  v1.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    Navigator.pop(context);

    try {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/index');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/titleRegister');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/transactionTracking');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/feesSimulation');
          break;
        case 4:
          Navigator.pushReplacementNamed(context, '/titleRegisterChange');
          break;
        case 5:
          Navigator.pushReplacementNamed(context, '/ownershipTracking');
          break;
        case 6:
          Navigator.pushReplacementNamed(context, '/paidInvoices');
          break;
        default:
          break;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Navigation error: $e');
        log('Stack trace: $stackTrace');
      }
    }
  }
}
