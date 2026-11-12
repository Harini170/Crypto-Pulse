import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// Soft brand-coloured glows that slowly drift behind the content.
class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        const Positioned(
          top: -120,
          left: -80,
          child: _Blob(
            color: AppColors.primary,
            size: 320,
            opacity: 0.22,
            dx: 60,
            dy: 40,
            seconds: 9,
          ),
        ),
        const Positioned(
          top: 120,
          right: -140,
          child: _Blob(
            color: AppColors.accent,
            size: 300,
            opacity: 0.22,
            dx: -70,
            dy: 50,
            seconds: 11,
          ),
        ),
        const Positioned(
          bottom: -170,
          left: -60,
          child: _Blob(
            color: AppColors.primary,
            size: 300,
            opacity: 0.14,
            dx: 50,
            dy: -40,
            seconds: 13,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.opacity,
    required this.dx,
    required this.dy,
    required this.seconds,
  });

  final Color color;
  final double size;
  final double opacity;
  final double dx;
  final double dy;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: Offset(dx, dy),
              duration: seconds.seconds,
              curve: Curves.easeInOut,
            )
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.18, 1.18),
              duration: seconds.seconds,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
