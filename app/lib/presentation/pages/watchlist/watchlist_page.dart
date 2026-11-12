import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/coin.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../widgets/change_chip.dart';
import '../../widgets/coin_avatar.dart';
import '../../widgets/coin_tile.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/state_views.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key, required this.onExplore});

  /// Switches the shell to the Markets tab from the empty state.
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, state) {
        final Widget body;
        if (state.status == LoadStatus.initial ||
            (state.status == LoadStatus.loading && state.coins.isEmpty)) {
          body = const CoinListShimmer(key: ValueKey('shimmer'), count: 5);
        } else if (state.status == LoadStatus.failure && state.coins.isEmpty) {
          body = ErrorView(
            key: const ValueKey('error'),
            message: state.error ?? 'Unable to load your watchlist.',
            onRetry: () =>
                context.read<WatchlistBloc>().add(const WatchlistStarted()),
          );
        } else if (state.ids.isEmpty) {
          body = EmptyView(
            key: const ValueKey('empty'),
            icon: Icons.star_outline_rounded,
            title: 'Your watchlist is empty',
            message: 'Tap the star on any coin to track its price here.',
            actionLabel: 'Explore markets',
            onAction: onExplore,
          );
        } else {
          final coins = state.coins;
          body = RefreshIndicator(
            key: const ValueKey('list'),
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () async {
              context.read<WatchlistBloc>().add(const WatchlistRefreshed());
              await Future<void>.delayed(const Duration(milliseconds: 700));
            },
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: coins.length + (coins.isEmpty ? 0 : 1),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SummaryCard(coins: coins),
                  );
                }
                final coin = coins[i - 1];
                return Dismissible(
                  key: ValueKey('watch-${coin.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: AppColors.loss.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.loss),
                  ),
                  onDismissed: (_) {
                    final bloc = context.read<WatchlistBloc>();
                    bloc.add(WatchlistToggled(coin));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('${coin.name} removed'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () => bloc.add(WatchlistToggled(coin)),
                        ),
                      ));
                  },
                  child: CoinTile(coin: coin, heroPrefix: 'watch')
                      .animate(delay: (40 * (i - 1)).ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.05, curve: Curves.easeOutCubic),
                );
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Watchlist',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                  ),
                  if (state.ids.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${state.ids.length} tracked',
                          style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Average 24h move + best performer of the tracked coins.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.coins});
  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    final avg = coins.fold<double>(0, (sum, c) => sum + c.priceChange24h) /
        coins.length;
    final best =
        coins.reduce((a, b) => a.priceChange24h >= b.priceChange24h ? a : b);

    return GlassCard(
      gradient: AppColors.heroGradient,
      radius: 22,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Average 24h change',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                ChangeChip(value: avg, large: true),
              ],
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.border),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Best performer',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CoinAvatar(coin: best, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${best.ticker}  ${Fmt.percent(best.priceChange24h)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.trend(best.isUp),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, curve: Curves.easeOutCubic);
  }
}
