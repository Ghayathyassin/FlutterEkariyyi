import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';

/// A modern service tile: a tinted, accent-coloured icon chip, a corner
/// affordance arrow, and the service name anchored to the bottom. Each tile
/// can carry its own [accent] (all drawn from the existing brand palette) so
/// the home grid feels lively without introducing new colours.
class Category extends StatelessWidget {
  const Category({
    super.key,
    required this.function,
    required this.title,
    this.icon,
    this.customIcon,
    this.accent = AppColors.primary,
  }) : assert(icon != null || customIcon != null);

  final void Function() function;
  final String title;
  final IconData? icon;
  final Widget? customIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: function,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint(accent),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: customIcon ?? Icon(icon, size: 24, color: accent),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward,
                      size: 18, color: accent.withOpacity(0.7)),
                ],
              ),
              const Spacer(),
              const SizedBox(height: AppSpacing.sm),
              AutoSizeText(
                title,
                style: AppType.title,
                maxLines: 2,
                minFontSize: 11,
                stepGranularity: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
