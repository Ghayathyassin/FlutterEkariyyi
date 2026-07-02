import 'package:flutter/material.dart';
import 'app_theme.dart';

/// "The Cadastral Line" — the redesign's one signature, drawn with CustomPaint
/// so it costs almost nothing and scales to any size.
///
///  * [CadastralLines]   — faint parcel‑boundary linework behind green surfaces.
///  * [CornerTicks]      — L‑shaped registration marks that frame "record"
///    moments (receipt card, completed stage).
///  * [SurveyBaseline]   — a survey baseline (track + station nodes) used as the
///    tracking progress indicator instead of a stock progress bar.

/// State of a tracking stage / survey station.
enum StageState { pending, inProgress, done }

Color stageColor(StageState s) {
  switch (s) {
    case StageState.done:
      return AppColors.success;
    case StageState.inProgress:
      return AppColors.amber;
    case StageState.pending:
      return const Color(0xffc9d2dc);
  }
}

/// Maps the backend colour code ('1' pending, '2' in‑progress, '3' done).
StageState stageFromCode(String? code) {
  switch (code) {
    case '3':
      return StageState.done;
    case '2':
      return StageState.inProgress;
    default:
      return StageState.pending;
  }
}

/// Faint parcel‑boundary linework, painted in white over a green surface.
class CadastralLines extends StatelessWidget {
  const CadastralLines({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.18,
    this.child,
  });

  final Color color;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CadastralLinesPainter(color.withOpacity(opacity)),
      child: child,
    );
  }
}

class _CadastralLinesPainter extends CustomPainter {
  _CadastralLinesPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final w = size.width, h = size.height;

    // A handful of parcel boundaries — irregular plots, like a cadastral sheet.
    void poly(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
    }

    // Long boundary running across.
    poly([
      Offset(-10, h * 0.34),
      Offset(w * 0.30, h * 0.30),
      Offset(w * 0.30, h * 0.66),
      Offset(w * 0.66, h * 0.62),
      Offset(w + 10, h * 0.70),
    ]);
    // Vertical lot dividers.
    poly([Offset(w * 0.30, -10), Offset(w * 0.30, h * 0.30)]);
    poly([Offset(w * 0.62, h * 0.62), Offset(w * 0.66, h + 10)]);
    poly([Offset(w * 0.82, -10), Offset(w * 0.80, h * 0.66)]);
    // A small corner parcel.
    poly([
      Offset(w * 0.08, h * 0.72),
      Offset(w * 0.08, h + 10),
    ]);
    poly([
      Offset(-10, h * 0.86),
      Offset(w * 0.30, h * 0.86),
    ]);
  }

  @override
  bool shouldRepaint(covariant _CadastralLinesPainter old) =>
      old.color != color;
}

/// Four L‑shaped registration ticks in the corners of the paint area.
/// [progress] (0..1) lets them "draw in".
class CornerTicks extends StatelessWidget {
  const CornerTicks({
    super.key,
    this.color = AppColors.primary,
    this.length = 14,
    this.thickness = 2,
    this.inset = 8,
    this.progress = 1.0,
  });

  final Color color;
  final double length;
  final double thickness;
  final double inset;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerTicksPainter(
          color, length, thickness, inset, progress.clamp(0.0, 1.0)),
    );
  }
}

class _CornerTicksPainter extends CustomPainter {
  _CornerTicksPainter(
      this.color, this.length, this.thickness, this.inset, this.progress);
  final Color color;
  final double length, thickness, inset, progress;

  @override
  void paint(Canvas canvas, Size size) {
    final len = length * progress;
    if (len <= 0) return;
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final l = inset, t = inset, r = size.width - inset, b = size.height - inset;
    // TL
    canvas.drawLine(Offset(l, t), Offset(l + len, t), p);
    canvas.drawLine(Offset(l, t), Offset(l, t + len), p);
    // TR
    canvas.drawLine(Offset(r, t), Offset(r - len, t), p);
    canvas.drawLine(Offset(r, t), Offset(r, t + len), p);
    // BL
    canvas.drawLine(Offset(l, b), Offset(l + len, b), p);
    canvas.drawLine(Offset(l, b), Offset(l, b - len), p);
    // BR
    canvas.drawLine(Offset(r, b), Offset(r - len, b), p);
    canvas.drawLine(Offset(r, b), Offset(r, b - len), p);
  }

  @override
  bool shouldRepaint(covariant _CornerTicksPainter o) =>
      o.color != color || o.progress != progress || o.length != length;
}

/// A single L registration mark (top‑start corner of cards).
class CornerMark extends StatelessWidget {
  const CornerMark(
      {super.key, this.color = AppColors.primary, this.size = 12, this.thickness = 2});
  final Color color;
  final double size;
  final double thickness;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CornerMarkPainter(color, thickness)),
      );
}

class _CornerMarkPainter extends CustomPainter {
  _CornerMarkPainter(this.color, this.thickness);
  final Color color;
  final double thickness;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    canvas.drawLine(Offset.zero, Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CornerMarkPainter o) => o.color != color;
}

/// Survey baseline progress: a thin track with a filled portion and station
/// nodes coloured by [states]. Replaces the stock progress bar on tracking.
class SurveyBaseline extends StatelessWidget {
  const SurveyBaseline({
    super.key,
    required this.states,
    this.progress,
    this.height = 28,
  });

  final List<StageState> states;

  /// 0..1 fill of the baseline. If null, derived from the states.
  final double? progress;
  final double height;

  double get _derivedProgress {
    if (progress != null) return progress!.clamp(0.0, 1.0);
    if (states.isEmpty) return 0;
    final done = states.where((s) => s == StageState.done).length;
    final active = states.any((s) => s == StageState.inProgress) ? 0.5 : 0.0;
    return ((done + active) / states.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BaselinePainter(
          states: states,
          progress: _derivedProgress,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    );
  }
}

class _BaselinePainter extends CustomPainter {
  _BaselinePainter(
      {required this.states, required this.progress, required this.rtl});
  final List<StageState> states;
  final double progress;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = Paint()
      ..color = AppColors.line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.success
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    double sx(double t) => rtl ? size.width * (1 - t) : size.width * t;

    canvas.drawLine(Offset(sx(0), cy), Offset(sx(1), cy), track);
    canvas.drawLine(Offset(sx(0), cy), Offset(sx(progress), cy), fill);

    final n = states.length;
    if (n == 0) return;
    for (int i = 0; i < n; i++) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      final c = Offset(sx(t), cy);
      final color = stageColor(states[i]);
      canvas.drawCircle(c, 7, Paint()..color = Colors.white);
      canvas.drawCircle(c, 6, Paint()..color = color);
      canvas.drawCircle(
          c,
          6,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _BaselinePainter o) =>
      o.progress != progress || o.rtl != rtl || o.states != states;
}

/// Shared surface decoration: crisp document card (hairline + e1 lift).
class AppDecor {
  AppDecor._();
  static BoxDecoration card({double? radius, Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      );
  static BoxDecoration flat({double? radius, Color? color}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius ?? AppRadius.lg),
        border: Border.all(color: AppColors.line),
      );
}
