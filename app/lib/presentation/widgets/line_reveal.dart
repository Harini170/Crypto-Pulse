import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Reveals its child from left to right once, when it first appears.
/// Used to make sparklines look like they are being "drawn".
class LineReveal extends StatelessWidget {
  const LineReveal({
    super.key,
    required this.child,
    this.duration = AppMotion.chart,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.enter,
      child: child,
      builder: (_, t, child) => ClipRect(
        clipper: _RevealClipper(t),
        child: child,
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Rect> {
  _RevealClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);

  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}
