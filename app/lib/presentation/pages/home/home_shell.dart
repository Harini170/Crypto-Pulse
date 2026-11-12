import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/stats/stats_bloc.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../widgets/glow_background.dart';
import '../market/market_page.dart';
import '../stats/stats_page.dart';
import '../watchlist/watchlist_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  // Drives the fade + slide every time the tab changes.
  late final AnimationController _tabAnim = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final Animation<double> _tabCurve =
      CurvedAnimation(parent: _tabAnim, curve: AppMotion.enter);
  late final Animation<Offset> _tabSlide =
      Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
          .animate(_tabCurve);

  late final List<Widget> _pages = [
    const MarketPage(),
    const StatsPage(),
    WatchlistPage(onExplore: () => _select(0)),
  ];

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    if (i == 2) context.read<WatchlistBloc>().add(const WatchlistRefreshed());
    setState(() => _index = i);
    _tabAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => getIt<MarketBloc>()..add(const MarketStarted())),
        BlocProvider(
            create: (_) => getIt<StatsBloc>()..add(const StatsStarted())),
      ],
      child: Scaffold(
        body: GlowBackground(
          child: SafeArea(
            bottom: false,
            // IndexedStack keeps scroll position / search text of every tab alive.
            child: FadeTransition(
              opacity: _tabCurve,
              child: SlideTransition(
                position: _tabSlide,
                child: IndexedStack(index: _index, children: _pages),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<WatchlistBloc, WatchlistState>(
          buildWhen: (p, c) => p.ids.length != c.ids.length,
          builder: (context, ws) => _FloatingNav(
            index: _index,
            onTap: _select,
            watchCount: ws.ids.length,
          ),
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.index,
    required this.onTap,
    required this.watchCount,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int watchCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.88),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.candlestick_chart_rounded,
                    label: 'Markets',
                    selected: index == 0,
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.donut_large_rounded,
                    label: 'Stats',
                    selected: index == 1,
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.star_rounded,
                    label: 'Watchlist',
                    selected: index == 2,
                    badge: watchCount,
                    onTap: () => onTap(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The active icon pops slightly with a bounce.
              AnimatedScale(
                scale: selected ? 1.14 : 1,
                duration: AppMotion.slow,
                curve: AppMotion.bounce,
                child: Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  child: Icon(
                    icon,
                    size: 23,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.enter,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
