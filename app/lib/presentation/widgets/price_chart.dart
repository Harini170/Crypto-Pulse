import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/chart_point.dart';
import '../../domain/entities/market_options.dart';

/// Interactive price chart: drag a finger to scrub, [onTouch] reports the point under it
/// (or null when released) so the screen header can show the exact price + time.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.points,
    required this.range,
    required this.isUp,
    required this.onTouch,
  });

  final List<ChartPoint> points;
  final ChartRange range;
  final bool isUp;
  final ValueChanged<ChartPoint?> onTouch;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.trend(isUp);
    var minY = points.first.price;
    var maxY = points.first.price;
    for (final p in points) {
      if (p.price < minY) minY = p.price;
      if (p.price > maxY) maxY = p.price;
    }
    final span = maxY - minY;
    final pad = span == 0 ? maxY.abs() * 0.01 + 1e-9 : span * 0.12;
    final lo = minY - pad;
    final hi = maxY + pad;
    final xInterval =
        (points.length / 4).floorToDouble().clamp(1, 100000).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: lo,
        maxY: hi,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (hi - lo) / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0x14FFFFFF), strokeWidth: 1, dashArray: [4, 5]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              interval: (hi - lo) / 4,
              getTitlesWidget: (v, meta) {
                if (v == meta.min || v == meta.max)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(Fmt.axisPrice(v),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: xInterval,
              getTitlesWidget: (v, meta) {
                final i = v.round();
                if (i <= 0 || i >= points.length - 1)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(Fmt.chartDate(points[i].time, range),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          // The exact value is shown in the screen header, so hide the default tooltip bubble.
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) =>
                spots.map<LineTooltipItem?>((_) => null).toList(),
          ),
          getTouchedSpotIndicator: (bar, indexes) => indexes
              .map(
                (_) => TouchedSpotIndicatorData(
                  FlLine(
                      color: color.withOpacity(0.55),
                      strokeWidth: 1.4,
                      dashArray: [4, 4]),
                  FlDotData(
                    show: true,
                    getDotPainter: (s, p, b, i, {double? size}) =>
                        FlDotCirclePainter(
                      radius: 5.5,
                      color: color,
                      strokeWidth: 2.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          touchCallback: (event, response) {
            final spots = response?.lineBarSpots;
            if (!event.isInterestedForInteractions ||
                spots == null ||
                spots.isEmpty) {
              onTouch(null);
              return;
            }
            final i = spots.first.spotIndex;
            if (i >= 0 && i < points.length) onTouch(points[i]);
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].price),
            ],
            isCurved: true,
            curveSmoothness: 0.14,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.32), color.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
      // Smoothly morphs the line when the range or the data changes.
      duration: AppMotion.chart,
      curve: AppMotion.enter,
    );
  }
}
