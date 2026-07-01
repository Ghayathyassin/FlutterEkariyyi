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
    return Container(
      height: 60,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: AppReveal(
        dy: -6,
        child: Row(
        children: [
          Material(
            color: AppColors.scaffold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _onBack(context),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.arrow_back,
                    size: 22, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppType.h2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
