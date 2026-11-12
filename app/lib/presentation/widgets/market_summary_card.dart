import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/market_stats.dart';
import '../blocs/stats/stats_bloc.dart';
import 'change_chip.dart';

/// Big overview card at the top of the Markets screen.
class MarketSummaryCard extends StatelessWidget {
  const MarketSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsBloc, StatsState>(
      buildWhen: (p, c) => p.stats != c.stats,
      builder: (context, state) {
        final stats = state.stats;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: stats == null
              ? const _Skeleton(key: ValueKey('skeleton'))
              : _Content(key: const ValueKey('content'), stats: stats),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({super.key, required this.stats});
  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Global market cap',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
              const Spacer(),
              ChangeChip(value: stats.marketCapChange24h),
            ],
          ),
          const SizedBox(height: 8),
          // Animates smoothly from the old value to the new one on every refresh.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: stats.totalMarketCap),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              Fmt.compactUsd(v),
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      label: '24h volume',
                      value: Fmt.compactUsd(stats.totalVolume))),
              Expanded(
                  child: _MiniStat(
                      label: 'BTC dominance',
                      value: '${stats.btcDominance.toStringAsFixed(1)}%')),
              Expanded(
                  child: _MiniStat(
                      label: 'ETH dominance',
                      value: '${stats.ethDominance.toStringAsFixed(1)}%')),
            ],
          ),
          const SizedBox(height: 18),
          _Breadth(gainers: stats.gainers, losers: stats.losers),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Green/red bar showing how many coins are up vs down.
class _Breadth extends StatelessWidget {
  const _Breadth({required this.gainers, required this.losers});
  final int gainers;
  final int losers;

  @override
  Widget build(BuildContext context) {
    final up = gainers < 1 ? 1 : gainers;
    final down = losers < 1 ? 1 : losers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Market breadth',
                style:
                    TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            const Spacer(),
            Text('$gainers up  ·  $losers down',
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                    flex: up, child: const ColoredBox(color: AppColors.gain)),
                const SizedBox(width: 2),
                Expanded(
                    flex: down, child: const ColoredBox(color: AppColors.loss)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white10);
  }
}
