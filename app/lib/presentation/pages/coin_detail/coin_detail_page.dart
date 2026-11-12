import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/load_status.dart';
import '../../../data/models/chart_point.dart';
import '../../../data/models/coin.dart';
import '../../blocs/coin_detail/coin_detail_bloc.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../widgets/change_chip.dart';
import '../../widgets/coin_avatar.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/price_flash.dart';
import '../../widgets/range_selector.dart';
import '../../widgets/state_views.dart';

class CoinDetailPage extends StatelessWidget {
  const CoinDetailPage({super.key, required this.coin, this.heroTag});

  final Coin coin;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoinDetailBloc>(
      create: (_) => getIt<CoinDetailBloc>(param1: coin)..add(const CoinDetailStarted()),
      child: _CoinDetailView(heroTag: heroTag),
    );
  }
}

class _CoinDetailView extends StatefulWidget {
  const _CoinDetailView({this.heroTag});
  final String? heroTag;

  @override
  State<_CoinDetailView> createState() => _CoinDetailViewState();
}

class _CoinDetailViewState extends State<_CoinDetailView> {
  final ValueNotifier<ChartPoint?> _touched = ValueNotifier(null);

  @override
  void dispose() {
    _touched.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: BlocBuilder<CoinDetailBloc, CoinDetailState>(
          builder: (context, state) {
            final coin = state.coin;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.bg.withOpacity(0.88),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  title: Row(
                    children: [
                      Text(coin.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#${coin.marketCapRank}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  actions: [_WatchButton(coin: coin), const SizedBox(width: 6)],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PriceHeader(coin: coin, heroTag: widget.heroTag, touched: _touched)
                          .animate()
                          .fadeIn(duration: 350.ms),
                      const SizedBox(height: 18),
                      _ChartCard(state: state, touched: _touched)
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 400.ms)
                          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                      const SizedBox(height: 16),
                      _StatsGrid(coin: coin)
                          .animate()
                          .fadeIn(delay: 220.ms, duration: 400.ms)
                          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                      const SizedBox(height: 16),
                      _SupplyCard(coin: coin)
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                      if (state.detailLoaded) ...[
                        const SizedBox(height: 16),
                        _AboutCard(coin: coin).animate().fadeIn(duration: 400.ms),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WatchButton extends StatelessWidget {
  const _WatchButton({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      buildWhen: (p, c) => p.contains(coin.id) != c.contains(coin.id),
      builder: (context, ws) {
        final watched = ws.contains(coin.id);
        return IconButton(
          tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.read<WatchlistBloc>().add(WatchlistToggled(coin));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(watched
                    ? '${coin.name} removed from watchlist'
                    : '${coin.name} added to watchlist'),
              ));
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              watched ? Icons.star_rounded : Icons.star_outline_rounded,
              key: ValueKey(watched),
              size: 28,
              color: watched ? const Color(0xFFFFC53D) : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _PriceHeader extends StatelessWidget {
  const _PriceHeader({required this.coin, required this.heroTag, required this.touched});

  final Coin coin;
  final String? heroTag;
  final ValueNotifier<ChartPoint?> touched;

  @override
  Widget build(BuildContext context) {
    const big = TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CoinAvatar(coin: coin, size: 46, heroTag: heroTag),
            const SizedBox(width: 12),
            Text(coin.ticker,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<ChartPoint?>(
          valueListenable: touched,
          builder: (context, point, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                point == null
                    ? PriceFlash(price: coin.currentPrice, style: big, alignEnd: false)
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(Fmt.price(point.price), style: big),
                      ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: point == null
                        ? Row(
                            key: const ValueKey('change'),
                            children: [
                              ChangeChip(value: coin.priceChange24h, large: true),
                              const SizedBox(width: 8),
                              const Text('past 24h',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          )
                        : BlocBuilder<CoinDetailBloc, CoinDetailState>(
                            key: const ValueKey('time'),
                            buildWhen: (p, c) => p.range != c.range,
                            builder: (_, s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(Fmt.tooltipDate(point.time, s.range),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.state, required this.touched});

  final CoinDetailState state;
  final ValueNotifier<ChartPoint?> touched;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CoinDetailBloc>();
    final Widget body;
    if (state.chartStatus == LoadStatus.failure) {
      body = Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.show_chart_rounded, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(state.chartError ?? 'Could not load the chart',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () => bloc.add(const ChartRetried()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (state.chartStatus != LoadStatus.success || state.chart.length < 2) {
      body = const ShimmerBox(key: ValueKey('loading'), height: 250, radius: 16);
    } else {
      body = PriceChart(
        key: ValueKey(state.range),
        points: state.chart,
        range: state.range,
        isUp: state.rangeIsUp,
        onTouch: (p) => touched.value = p,
      );
    }

    final pct = state.rangeChangePct;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
            child: Row(
              children: [
                const Text('Price chart',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                if (pct != null && state.chartStatus == LoadStatus.success) ...[
                  Text(state.range.label,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  ChangeChip(value: pct),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: body,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: RangeSelector(
              selected: state.range,
              onChanged: (r) {
                touched.value = null;
                bloc.add(ChartRangeChanged(r));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final volRatio = coin.marketCap == 0 ? 0.0 : coin.totalVolume / coin.marketCap * 100;
    final items = <(String, String)>[
      ('Market cap', Fmt.compactUsd(coin.marketCap)),
      ('24h volume', Fmt.compactUsd(coin.totalVolume)),
      ('Volume / Mkt cap', '${volRatio.toStringAsFixed(2)}%'),
      ('Rank', '#${coin.marketCapRank}'),
      ('24h high', Fmt.price(coin.high24h)),
      ('24h low', Fmt.price(coin.low24h)),
      ('All-time high', Fmt.price(coin.ath)),
      ('All-time low', Fmt.price(coin.atl)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('Market statistics',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (label, value) in items)
                  SizedBox(
                    width: w,
                    child: GlassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(value,
                                style: const TextStyle(
                                    fontSize: 16.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.coin});
  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final progress = coin.supplyProgress;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Supply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          row('Circulating', '${Fmt.compact(coin.circulatingSupply)} ${coin.ticker}'),
          row('Total', coin.totalSupply == null ? '—' : '${Fmt.compact(coin.totalSupply!)} ${coin.ticker}'),
          row('Max', coin.maxSupply == null ? '∞' : '${Fmt.compact(coin.maxSupply!)} ${coin.ticker}'),
          if (progress != null) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(height: 10, color: AppColors.surface),
                        FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(
                              height: 10,
                              decoration:
                                  const BoxDecoration(gradient: AppColors.brandGradient)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(v * 100).toStringAsFixed(1)}% of supply is in circulation',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutCard extends StatefulWidget {
  const _AboutCard({required this.coin});
  final Coin coin;

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.coin.description ?? '';
    final text = raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    final cats = widget.coin.categories;
    if (text.isEmpty && cats.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About ${widget.coin.name}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(c,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Text(
                text,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            if (text.length > 220)
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
          ],
        ],
      ),
    );
  }
}
