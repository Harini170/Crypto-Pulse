import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tiny, non-interactive trend line for list rows.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.data,
    required this.isUp,
    this.width = 78,
    this.height = 34,
  });

  final List<double> data;
  final bool isUp;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);

    // Down-sample: ~40 points is plenty for 78px and keeps lists buttery.
    final step = (data.length / 40).ceil().clamp(1, 1000);
    final pts = <double>[for (var i = 0; i < data.length; i += step) data[i], data.last];
    final minY = pts.reduce((a, b) => a < b ? a : b);
    final maxY = pts.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) == 0 ? (maxY.abs() * 0.01 + 1e-9) : (maxY - minY) * 0.1;
    final color = AppColors.trend(isUp);

    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i])],
                isCurved: true,
                curveSmoothness: 0.2,
                preventCurveOverShooting: true,
                barWidth: 1.6,
                color: color,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.25), color.withOpacity(0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
