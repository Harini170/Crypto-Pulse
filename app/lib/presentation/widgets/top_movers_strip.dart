import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/coin.dart';
import '../blocs/stats/stats_bloc.dart';
import 'change_chip.dart';
import 'coin_avatar.dart';
import 'glass_card.dart';
import 'sparkline.dart';

/// Horizontal strip of the biggest 24h gainers / losers.
class TopMoversStrip extends StatefulWidget {
  const TopMoversStrip({super.key});

  @override
  State<TopMoversStrip> createState() => _TopMoversStripState();
}

class _TopMoversStripState extends State<TopMoversStrip> {
  bool _gainers = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsBloc, StatsState>(
      buildWhen: (p, c) => p.stats != c.stats,
      builder: (context, state) {
        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();
        final list = _gainers ? stats.topGainers : stats.topLosers;
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Top movers',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                _Toggle(
                  gainers: _gainers,
                  onChanged: (v) => setState(() => _gainers = v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.separated(
                key: ValueKey(_gainers),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _MoverCard(coin: list[i])
                    .animate(delay: (60 * i).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1, curve: Curves.easeOutCubic),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.gainers, required this.onChanged});
  final bool gainers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, bool value, Color color) {
      final on = gainers == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: on ? color : AppColors.textSecondary)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill('Gainers', true, AppColors.gain),
          pill('Losers', false, AppColors.loss),
        ],
      ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  const _MoverCard({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(12),
        onTap: () => AppRouter.openCoin(context, coin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CoinAvatar(coin: coin, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(coin.ticker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ],
            ),
            Sparkline(
                data: coin.sparkline, isUp: coin.isUp, width: 126, height: 28),
            Text(Fmt.price(coin.currentPrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ChangeChip(value: coin.priceChange24h),
          ],
        ),
      ),
    );
  }
}
