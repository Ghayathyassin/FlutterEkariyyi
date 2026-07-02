import 'package:flutter/material.dart';
import '../theme/app_decor.dart';
import 'register_ui.dart';

/// One stage in a transaction/ownership track. Renders the spec's stage chip
/// (tinted card + state glyph + caption). Colour codes (unchanged from the
/// backend): 1 = pending, 2 = in‑progress, 3 = done.
///
/// Callers still wrap this in [Expanded] inside a Row.
class StageBlock extends StatelessWidget {
  final String title;
  final String colorCode;

  const StageBlock({
    required this.title,
    required this.colorCode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StageChip(title: title, state: stageFromCode(colorCode));
  }
}
