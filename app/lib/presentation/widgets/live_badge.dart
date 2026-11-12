import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// Pulsing pill showing where the data comes from:
/// LIVE (CoinGecko), DEMO (mock market) or OFFLINE (cached copy).
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      'live' => ('LIVE', AppColors.gain),
      'cache' => ('OFFLINE', const Color(0xFFFFB020)),
      _ => ('DEMO', AppColors.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.3, end: 1, duration: 900.ms),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
