import 'package:flutter/material.dart';

/// False when the user turned animations off in the system settings. Every
/// decorative animation in the app checks this.
bool motionAllowed(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

/// Fades and slides [child] up when it first appears. [delay] staggers a list
/// without timers, by leaving the start of the animation empty.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds /
          (widget.delay + widget.duration).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      motionAllowed(context) ? _controller.forward() : _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      child: SlideTransition(
        position: _progress.drive(
          Tween(begin: const Offset(0, 0.12), end: Offset.zero),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Pops [child] in with a small overshoot. For mascots and celebratory moments.
class PopIn extends StatelessWidget {
  final Widget child;

  const PopIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!motionAllowed(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

/// A number that counts to its new value instead of jumping.
class CountUpText extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const CountUpText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: motionAllowed(context)
          ? const Duration(milliseconds: 500)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, shown, _) => Text('${shown.round()}', style: style),
    );
  }
}
