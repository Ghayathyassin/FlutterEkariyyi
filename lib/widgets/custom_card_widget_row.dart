import 'package:flutter/material.dart';
import '../generated/l10n.dart';
import '../theme/app_theme.dart';

class CustomCardWidgetRow extends StatelessWidget {
  final List<Map<String, String>> content;

  /// When provided, a delete (✕) button is shown in the card's top trailing
  /// corner (its own row, so it never overlaps the content text).
  final VoidCallback? onDelete;

  const CustomCardWidgetRow({
    super.key,
    required this.content,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onDelete != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    splashRadius: 20,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: onDelete,
                  ),
                ),
              ),
            for (int i = 0; i < content.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _row(context, content[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, String> item) {
    final isCost = item['title']?.contains('${S.of(context).cost}:') ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              item['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
                color: isCost ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              item['description'] ?? '',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: isCost ? FontWeight.bold : FontWeight.w500,
                color: isCost ? AppColors.danger : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
