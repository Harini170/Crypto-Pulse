import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class ChangeChip extends StatelessWidget {
  const ChangeChip({super.key, required this.value, this.large = false});

  final double value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final up = value >= 0;
    final color = AppColors.trend(up);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 7, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(large ? 12 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: color, size: large ? 22 : 18),
          Text(
            Fmt.percent(value.abs(), sign: false),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
