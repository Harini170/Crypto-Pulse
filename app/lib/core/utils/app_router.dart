import 'package:flutter/material.dart';

import '../../data/models/coin.dart';
import '../../presentation/pages/coin_detail/coin_detail_page.dart';
import '../../presentation/pages/home/home_shell.dart';

class AppRouter {
  AppRouter._();

  /// Splash -> app. Replaces the splash so Back never returns to it.
  static Future<void> goHome(BuildContext context) {
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  /// Fade + gentle slide transition; the coin avatar flies via [Hero].
  static Future<void> openCoin(BuildContext context, Coin coin,
      {String? heroTag}) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) =>
            CoinDetailPage(coin: coin, heroTag: heroTag),
        transitionsBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
