import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

/// Home service tile — "Option E" from the redesign spec: a white card (radius
/// 16, e1 lift) with a 44dp accent‑tint chip holding a 24dp Material Symbol in
/// the service accent, a title, and a one‑line description. Presses scale 0.96.
class Category extends StatelessWidget {
  const Category({
    super.key,
    required this.function,
    required this.title,
    this.description,
    this.icon,
    this.customIcon,
    this.accent = AppColors.primary,
  }) : assert(icon != null || customIcon != null);

  final void Function() function;
  final String title;
  final String? description;
  final IconData? icon;
  final Widget? customIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: function,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            splashColor: accent.withOpacity(0.08),
            highlightColor: accent.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tintFor(accent),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: customIcon ?? Icon(icon, size: 36, color: accent),
                  ),
                  const SizedBox(height: 12),
                  AutoSizeText(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    minFontSize: 11,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.25,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
