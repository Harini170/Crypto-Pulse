import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final double radius;
  final VoidCallback? onTap;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(widget.radius);
    return AnimatedScale(
      scale: _pressed && widget.onTap != null ? 0.97 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.gradient == null
                ? AppColors.card.withOpacity(0.85)
                : null,
            gradient: widget.gradient,
            borderRadius: shape,
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: shape,
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
