import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Пайдошавии мулоим (fade + slide) бо таъхир — барои рӯйхатҳо ва корт-ҳо.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offset = const Offset(0, 0.06),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + widget.duration;
    _ctrl = AnimationController(vsync: this, duration: total);
    final start = total.inMilliseconds == 0 ? 0.0 : widget.delay.inMilliseconds / total.inMilliseconds;
    _curve = CurvedAnimation(parent: _ctrl, curve: Interval(start, 1.0, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Таъхири зина-ба-зина барои индекси элемент (то 400мс).
Duration staggerDelay(int index, {int stepMs = 45, int maxMs = 400}) {
  final ms = index * stepMs;
  return Duration(milliseconds: ms > maxMs ? maxMs : ms);
}

/// Рақам аз 0 то арзиш мешуморад; ҳангоми тағйири арзиш аз ҷои ҷорӣ идома меёбад.
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// Ҳангоми гузоштани мушак (веб/десктоп) корт каме боло меравад ва равшан мешавад.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double radius;
  const HoverLift({super.key, required this.child, this.radius = 10});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _hover
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8))]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Дойраҳои рангини нарм, ки оҳиста ҳаракат мекунанд (замина барои экрани вуруд).
class AnimatedBackdrop extends StatefulWidget {
  final Widget child;
  const AnimatedBackdrop({super.key, required this.child});

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _orb(double size, Color color, Alignment a) {
    return Align(
      alignment: a,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            return Stack(
              fit: StackFit.expand,
              children: [
                _orb(420, AppColors.primary, Alignment(-0.9 + 0.5 * t, -0.8 + 0.3 * t)),
                _orb(360, AppColors.accent, Alignment(0.9 - 0.4 * t, 0.7 - 0.5 * t)),
                _orb(260, AppColors.primaryLight, Alignment(0.2 + 0.3 * t, -0.2 + 0.6 * t)),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
