import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/load_status.dart';
import '../../../domain/entities/market_options.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/stats/stats_bloc.dart';
import '../../widgets/coin_tile.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/market_summary_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/top_movers_strip.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 420) {
      context.read<MarketBloc>().add(const MarketLoadMore());
    }
  }

  void _openSort(MarketState state) {
    final bloc = context.read<MarketBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // lets the sheet use more of the screen height
      builder: (_) => _SortSheet(
        sort: state.sort,
        ascending: state.ascending,
        onSelected: (sort, asc) {
          Navigator.of(context).pop();
          bloc.add(MarketSortChanged(sort, ascending: asc));
          if (_scroll.hasClients) _scroll.jumpTo(0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarketBloc, MarketState>(
      listenWhen: (p, c) =>
          p.error != c.error && c.error != null && c.coins.isNotEmpty,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(source: state.source),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _SearchField(
                controller: _search,
                onChanged: (q) =>
                    context.read<MarketBloc>().add(MarketSearchChanged(q)),
              ),
            ),
            const SizedBox(height: 12),
            _FilterRow(
              selected: state.filter,
              onSelected: (f) =>
                  context.read<MarketBloc>().add(MarketFilterChanged(f)),
              onSortTap: () => _openSort(state),
            ),
            const SizedBox(height: 6),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MarketState state) {
    final loading = state.status == LoadStatus.initial ||
        state.status == LoadStatus.loading;
    final Widget child;
    if (loading) {
      child = const CoinListShimmer(key: ValueKey('shimmer'));
    } else if (state.status == LoadStatus.failure && state.coins.isEmpty) {
      child = ErrorView(
        key: const ValueKey('error'),
        message: state.error ?? 'Unable to load the market.',
        onRetry: () => context.read<MarketBloc>().add(const MarketStarted()),
      );
    } else if (state.coins.isEmpty) {
      child = EmptyView(
        key: const ValueKey('empty'),
        icon: Icons.search_off_rounded,
        title: 'No coins found',
        message: state.query.isNotEmpty
            ? 'Nothing matches "${state.query}". Try another name or symbol.'
            : 'No coins match the selected filter.',
        actionLabel: 'Reset filters',
        onAction: () {
          _search.clear();
          final bloc = context.read<MarketBloc>();
          bloc.add(const MarketSearchChanged(''));
          bloc.add(const MarketFilterChanged(CoinFilter.all));
        },
      );
    } else {
      child = _CoinList(
          key: const ValueKey('list'), state: state, controller: _scroll);
    }
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250), child: child);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crypto Pulse',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1)),
                SizedBox(height: 2),
                Text('Live market research',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          LiveBadge(source: source),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.15, curve: Curves.easeOutCubic);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search coins, e.g. Bitcoin or ETH',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, v, __) => v.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
        filled: true,
        fillColor: AppColors.card.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 1.4),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

/// Filter chips on the left, sort button pinned on the right.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
    required this.onSortTap,
  });

  final CoinFilter selected;
  final ValueChanged<CoinFilter> onSelected;
  final VoidCallback onSortTap;

  IconData _icon(CoinFilter f) => switch (f) {
        CoinFilter.all => Icons.apps_rounded,
        CoinFilter.gainers => Icons.trending_up_rounded,
        CoinFilter.losers => Icons.trending_down_rounded,
        CoinFilter.highVolume => Icons.bar_chart_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: CoinFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = CoinFilter.values[i];
                final on = f == selected;
                return GestureDetector(
                  onTap: () => onSelected(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: on ? AppColors.brandGradient : null,
                      color: on ? null : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: on ? Colors.transparent : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(_icon(f),
                            size: 16,
                            color: on ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: on ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: onSortTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 160.ms, duration: 400.ms);
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.sortLabel});
  final String sortLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const MarketSummaryCard(),
        const SizedBox(height: 22),
        const TopMoversStrip(),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text('All coins',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('Sorted by $sortLabel',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _CoinList extends StatelessWidget {
  const _CoinList({super.key, required this.state, required this.controller});
  final MarketState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final coins = state.coins;
    // The overview (summary + movers) only shows on the plain, unfiltered list.
    final showOverview = state.query.isEmpty && state.filter == CoinFilter.all;
    final headerCount = showOverview ? 1 : 0;
    final sortLabel = '${state.sort.label} ${state.ascending ? '↑' : '↓'}';

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.card,
      onRefresh: () async {
        context.read<StatsBloc>().add(const StatsRefreshed());
        final bloc = context.read<MarketBloc>();
        bloc.add(const MarketRefreshed());
        await bloc.stream.firstWhere((s) => !s.isRefreshing);
      },
      child: ListView.builder(
        controller: controller,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: headerCount + coins.length + 1,
        findChildIndexCallback: (key) {
          if (key is ValueKey<String>) {
            final i = coins.indexWhere((c) => c.id == key.value);
            return i < 0 ? null : i + headerCount;
          }
          return null;
        },
        itemBuilder: (context, i) {
          if (showOverview && i == 0) return _Overview(sortLabel: sortLabel);
          final index = i - headerCount;
          if (index == coins.length) return _Footer(state: state);
          final coin = coins[index];
          return KeyedSubtree(
            key: ValueKey<String>(coin.id),
            child: CoinTile(coin: coin, heroPrefix: 'market')
                .animate(delay: (28 * (index % ApiConstants.pageSize)).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: 0.05, curve: Curves.easeOutCubic),
          );
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});
  final MarketState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text("You've reached the end",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ),
      );
    }
    return const SizedBox(height: 60);
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet(
      {required this.sort, required this.ascending, required this.onSelected});

  final CoinSort sort;
  final bool ascending;
  final void Function(CoinSort sort, bool ascending) onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Scrollable, so it never overflows on short screens or small windows.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Tap the active option again to flip the direction.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 8),
            for (final s in CoinSort.values)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                selected: s == sort,
                selectedColor: AppColors.primary,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                title: Text(s.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: s == sort
                    ? Icon(ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded)
                    : null,
                onTap: () {
                  if (s == sort) {
                    onSelected(s, !ascending);
                  } else {
                    onSelected(s, s == CoinSort.name); // name defaults to A→Z
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
