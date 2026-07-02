import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_decor.dart';

/// Shared "Cadastral Line" building blocks used across the feature screens so
/// forms, sections and summaries read as one document.

/// Small field label sitting above an input (13/500, secondary).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 6, start: 2),
        child: Text(text, style: AppType.label),
      );
}

/// A section kicker: green tick + wide‑tracked eyebrow + hairline rule.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
      {super.key, required this.label, this.icon, this.accent = AppColors.primary});
  final String label;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.smd),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 15,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (icon != null) ...[
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
            ],
            Text(label.toUpperCase(), style: AppType.eyebrow),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Container(height: 1, color: AppColors.line)),
          ],
        ),
      );
}

/// Cart counter pill: green‑tint pill + label + a green count badge (mono).
class CartChip extends StatelessWidget {
  const CartChip({super.key, required this.count, this.label});
  final int count;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bool empty = count <= 0;
    final Color fg = empty ? AppColors.textSecondary : AppColors.primary;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: empty ? AppColors.scaffold : AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
            color: empty ? AppColors.line : AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 17, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Text(label ?? 'Cart',
              style: AppType.label.copyWith(color: fg, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: empty ? AppColors.disabled : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text('$count',
                style: AppType.mono(
                    fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// The emphasised total bar. Default = red solid (cart total). [tinted] = green
/// tint variant used for the fees total.
class SummaryBar extends StatelessWidget {
  const SummaryBar({
    super.key,
    required this.label,
    required this.amount,
    this.suffix = 'L.L',
    this.tinted = false,
  });

  final String label;
  final String amount;
  final String suffix;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final Color bg = tinted ? AppColors.greenTint : AppColors.danger;
    final Color border = tinted ? const Color(0xffcfe3cf) : AppColors.danger;
    final Color fg = tinted ? AppColors.primary : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.2,
              )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(amount,
                  style: AppType.mono(
                      fontSize: 18, color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(suffix,
                  style: TextStyle(
                      color: fg.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// One of the four tracking stage chips, coloured by [state].
class StageChip extends StatelessWidget {
  const StageChip({super.key, required this.title, required this.state});
  final String title;
  final StageState state;

  @override
  Widget build(BuildContext context) {
    late final Color bg, border, fg;
    late final IconData icon;
    switch (state) {
      case StageState.done:
        bg = const Color(0xffeaf6ee);
        border = const Color(0xffb9dfc6);
        fg = AppColors.success;
        icon = Icons.check_rounded;
        break;
      case StageState.inProgress:
        bg = const Color(0xfffff6e0);
        border = const Color(0xfff0d798);
        fg = AppColors.amberText;
        icon = Icons.hourglass_bottom_rounded;
        break;
      case StageState.pending:
        bg = AppColors.scaffold;
        border = AppColors.line;
        fg = AppColors.disabled;
        icon = Icons.circle_outlined;
        break;
    }
    return Column(
      children: [
        Container(
          height: 44,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 20, color: fg),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.caption.copyWith(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.2),
        ),
      ],
    );
  }
}

/// Legend row for the tracking states.
class StageLegend extends StatelessWidget {
  const StageLegend({
    super.key,
    required this.pending,
    required this.inProgress,
    required this.done,
  });
  final String pending, inProgress, done;

  Widget _dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: AppType.caption),
        ],
      );

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          _dot(const Color(0xffc9d2dc), pending),
          _dot(AppColors.amber, inProgress),
          _dot(AppColors.success, done),
        ],
      );
}

/// A document card carrying corner registration ticks — for "record" moments
/// (the payment receipt).
class RegisterCard extends StatelessWidget {
  const RegisterCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            decoration: AppDecor.flat(),
            child: Padding(padding: padding, child: child),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CornerTicks(
                  color: AppColors.primary, length: 12, inset: 8),
            ),
          ),
        ],
      );
}
