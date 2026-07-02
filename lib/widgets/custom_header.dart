import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/drawer_state.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool goBack;

  const CustomHeader({
    super.key,
    required this.title,
    this.goBack = false,
  });

  void _onBack(BuildContext context) {
    if (goBack) {
      Navigator.pop(context);
    } else {
      Provider.of<DrawerState>(context, listen: false).setSelectedIndex(0);
      Navigator.pushReplacementNamed(context, '/index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: 56,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 6, end: AppSpacing.md),
      child: AppReveal(
        dy: -6,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onBack(context),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(title, style: AppType.h2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
