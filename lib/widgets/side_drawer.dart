import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/features.dart';
import '../generated/l10n.dart';
import '../models/drawer_state.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// One drawer destination.
///
/// [id] is the value kept in [DrawerState] and is deliberately **not** the list
/// position: filtering a destination out (Title Register on iOS) must not shift
/// the highlight of the ones that remain. `screens/index.dart` passes these same
/// ids to `DrawerState.setSelectedIndex`, so the two have to agree — which is
/// why id, icon, route and label now travel together instead of living in three
/// index-aligned lists plus an index-based switch.
class _Destination {
  const _Destination({
    required this.id,
    required this.icon,
    required this.route,
    required this.label,
  });

  final int id;
  final IconData icon;
  final String route;
  final String label;
}

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  // Material Symbols set per the redesign spec.
  static List<_Destination> _destinations(BuildContext context) => [
        _Destination(
          id: 0,
          icon: Icons.home_rounded,
          route: '/index',
          label: S.of(context).homepage,
        ),
        // Hidden on iOS — see Features.titleRegister.
        if (Features.titleRegister)
          _Destination(
            id: 1,
            icon: Icons.menu_book_rounded,
            route: '/titleRegister',
            label: S.of(context).titleRegister,
          ),
        _Destination(
          id: 2,
          icon: Icons.fact_check_outlined,
          route: '/transactionTracking',
          label: S.of(context).transactionTracking,
        ),
        _Destination(
          id: 3,
          icon: Icons.calculate_rounded,
          route: '/feesSimulation',
          label: S.of(context).feesSimulation,
        ),
        _Destination(
          id: 4,
          icon: Icons.edit_document,
          route: '/titleRegisterChange',
          label: S.of(context).titleRegisterChanges,
        ),
        _Destination(
          id: 5,
          icon: Icons.vpn_key_outlined,
          route: '/ownershipTracking',
          label: S.of(context).ownershipReqTracking,
        ),
        _Destination(
          id: 6,
          icon: Icons.receipt_long_rounded,
          route: '/paidInvoices',
          label: S.of(context).paidInvoices,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final destinations = _destinations(context);

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
                          : 'المديرية العامة للشؤون العقارية',
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
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  // Highlight by stable id; stagger the reveal by position.
                  final bool isSelected =
                      drawerState.selectedIndex == destination.id;
                  final Color fg = isSelected
                      ? Colors.white
                      : const Color(0xffc7ccd1);

                  return AppReveal(
                    delay: Duration(milliseconds: 45 * index),
                    dy: 12,
                    child: Pressable(
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: isSelected
                          ? AppColors.drawerSelected.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () {
                          drawerState.setSelectedIndex(destination.id);
                          _navigateToScreen(context, destination.route);
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              end: 14, top: 12, bottom: 12),
                          child: Row(
                            children: [
                              // 3dp active survey-rule on the start edge.
                              Container(
                                width: 3,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.drawerSelected
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Icon(destination.icon,
                                  color: isSelected
                                      ? AppColors.drawerSelected
                                      : fg,
                                  size: 21),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  destination.label,
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

  void _navigateToScreen(BuildContext context, String route) {
    Navigator.pop(context);

    try {
      Navigator.pushReplacementNamed(context, route);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        log('Navigation error: $e');
        log('Stack trace: $stackTrace');
      }
    }
  }
}
