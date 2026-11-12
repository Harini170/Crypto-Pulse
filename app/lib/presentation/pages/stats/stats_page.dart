import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/coin.dart';
import '../../../data/models/market_stats.dart';
import '../../blocs/stats/stats_bloc.dart';
import '../../widgets/animated_count.dart';
import '../../widgets/change_chip.dart';
import '../../widgets/coin_tile.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/state_views.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatsBloc, StatsState>(
      listenWhen: (p, c) => p.error != c.error && c.error != null && c.stats != null,
      listener: (context, s) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.error!))),
      builder: (context, state) {
        final stats = state.stats;
        if (state.status == LoadStatus.failure && stats == null) {
          return ErrorView(
            message: state.error ?? 'Unable to load market statistics.',
            onRetry: () => context.read<StatsBloc>().add(const StatsStarted()),
          );
        }
        if (stats == null) return const _StatsShimmer();

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            final bloc = context.read<StatsBloc>();
            bloc.add(const StatsRefreshed());
            await bloc.stream.firstWhere((s) => !s.isRefreshing);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Market overview',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  LiveBadge(source: stats.source),
                ],
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 16),
              _HeroCard(stats: stats)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 450.ms)
                  .slideY(begin: 0.08, curve: Curves.easeOutCubic),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.swap_horiz_rounded,
                      label: '24h volume',
                      value: stats.totalVolume,
                      format: Fmt.compactUsd,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.layers_rounded,
                      label: 'Active coins',
                      value: stats.activeCoins.toDouble(),
                      format: (v) => v.round().toString(),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 160.ms, duration: 450.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),
              _DominanceCard(stats: stats)
                  .animate()
                  .fadeIn(delay: 240.ms, duration: 450.ms)
                  .slideY(begin: 0.08),
              const SizedBox(height: 14),
              _SentimentCard(stats: stats)
                  .animate()
                  .fadeIn(delay: 320.ms, duration: 450.ms)
                  .slideY(begin: 0.08),
              const SizedBox(height: 14),
              _Movers(
                title: 'Top gainers',
                icon: Icons.trending_up_rounded,
                color: AppColors.gain,
                coins: stats.topGainers,
                prefix: 'stats-gain',
              ).animate().fadeIn(delay: 400.ms, duration: 450.ms).slideY(begin: 0.08),
              const SizedBox(height: 14),
              _Movers(
                title: 'Top losers',
                icon: Icons.trending_down_rounded,
                color: AppColors.loss,
                coins: stats.topLosers,
                prefix: 'stats-lose',
              ).animate().fadeIn(delay: 480.ms, duration: 450.ms).slideY(begin: 0.08),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(22),
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.35),
          AppColors.accent.withOpacity(0.28),
          AppColors.card,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Global market cap',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedCount(
            value: stats.totalMarketCap,
            format: Fmt.compactUsd,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChangeChip(value: stats.marketCapChange24h, large: true),
              const SizedBox(width: 8),
              const Text('past 24h',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.format,
  });

  final IconData icon;
  final String label;
  final double value;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            format: format,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DominanceCard extends StatefulWidget {
  const _DominanceCard({required this.stats});
  final MarketStats stats;

  @override
  State<_DominanceCard> createState() => _DominanceCardState();
}

class _DominanceCardState extends State<_DominanceCard> {
  int _touched = -1;

  static const _palette = [
    Color(0xFFF7931A), // BTC
    Color(0xFF627EEA), // ETH
    Color(0xFF26A17B),
    Color(0xFFF3BA2F),
    Color(0xFF9945FF),
    Color(0xFF4B5675), // others
  ];

  @override
  Widget build(BuildContext context) {
    final slices = widget.stats.dominance;
    final hasTouch = _touched >= 0 && _touched < slices.length;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market dominance',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 62,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        final i = (!event.isInterestedForInteractions ||
                                resp?.touchedSection == null)
                            ? -1
                            : resp!.touchedSection!.touchedSectionIndex;
                        if (i != _touched) setState(() => _touched = i);
                      },
                    ),
                    sections: [
                      for (var i = 0; i < slices.length; i++)
                        PieChartSectionData(
                          value: slices[i].share <= 0 ? 0.001 : slices[i].share,
                          color: _palette[i % _palette.length],
                          radius: i == _touched ? 34 : 27,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasTouch ? slices[_touched].symbol : 'BTC',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${(hasTouch ? slices[_touched].share : widget.stats.btcDominance).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (var i = 0; i < slices.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: _palette[i % _palette.length], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('${slices[i].symbol} ${slices[i].share.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentimentCard extends StatelessWidget {
  const _SentimentCard({required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.gainers + stats.losers;
    final ratio = total == 0 ? 0.5 : stats.gainers / total;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('24h market breadth',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: LayoutBuilder(
                  builder: (_, c) => Stack(
                    children: [
                      Container(color: AppColors.loss),
                      Container(width: c.maxWidth * v, color: AppColors.gain),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${stats.gainers} rising',
                  style: const TextStyle(
                      color: AppColors.gain, fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('${stats.losers} falling',
                  style: const TextStyle(
                      color: AppColors.loss, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Movers extends StatelessWidget {
  const _Movers({
    required this.title,
    required this.icon,
    required this.color,
    required this.coins,
    required this.prefix,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Coin> coins;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final c in coins)
            CoinTile(coin: c, heroPrefix: prefix, showRank: false, showSparkline: false),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 190, height: 26),
          SizedBox(height: 18),
          ShimmerBox(height: 140, radius: 26),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ShimmerBox(height: 100, radius: 22)),
              SizedBox(width: 12),
              Expanded(child: ShimmerBox(height: 100, radius: 22)),
            ],
          ),
          SizedBox(height: 14),
          ShimmerBox(height: 260, radius: 22),
        ],
      ),
    );
  }
}
