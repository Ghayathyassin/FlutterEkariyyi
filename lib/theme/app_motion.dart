import 'package:flutter/material.dart';

/// Motion layer for the LRC app.
///
/// This is intentionally separate from [AppColors]/[AppType]: the brand's
/// *visual* identity (the fixed green palette, spacing, type) is untouched —
/// this file only adds *movement* so the UI feels active instead of static.
///
/// Everything here honours the OS "reduce motion" accessibility setting
/// ([AppMotion.reduced]) by falling back to no animation.
class AppMotion {
  AppMotion._();

  /// Durations.
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 520);

  /// Per-item delay for cascading (staggered) grid/list reveals.
  static const Duration stagger = Duration(milliseconds: 70);

  /// Entrance easing — decelerate, "emphasized" feel.
  static const Curve enter = Curves.easeOutCubic;

  /// Springy settle used when a pressed element is released.
  static const Curve spring = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// One-shot entrance animation: fades, slides and slightly scales its [child]
/// in when it first mounts. Give successive items an increasing [delay] to get
/// a staggered cascade.
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.dy = 18,
    this.scaleFrom = 0.96,
  });

  final Widget child;

  /// How long to wait before this item animates in (used for stagger).
  final Duration delay;
  final Duration? duration;

  /// Vertical travel in logical px (positive = slides up from below,
  /// negative = eases down from above).
  final double dy;

  /// Initial scale the child grows from (1.0 = no scale).
  final double scaleFrom;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.base,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    final curved = CurvedAnimation(parent: _c, curve: AppMotion.enter);
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.dy * (1 - t)),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps [children] so each one reveals a stagger-step after the previous —
/// a cascading list/column entrance. Spread the result into a `children:` list.
List<Widget> revealStagger(
  List<Widget> children, {
  Duration initial = Duration.zero,
  Duration step = AppMotion.stagger,
  double dy = 18,
}) {
  return [
    for (int i = 0; i < children.length; i++)
      AppReveal(delay: initial + step * i, dy: dy, child: children[i]),
  ];
}

/// Wraps a tappable so it springs down slightly while pressed and settles back
/// on release — a tactile micro-interaction. It uses a passive [Listener], so
/// any [InkWell]/gesture inside [child] still receives the tap (and its ripple).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: _down ? AppMotion.fast : AppMotion.base,
        curve: _down ? Curves.easeOut : AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}
