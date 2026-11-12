import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/watchlist/watchlist_bloc.dart';
import 'presentation/pages/splash/splash_page.dart';

class CryptoPulseApp extends StatelessWidget {
  const CryptoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The watchlist is app-wide so every star button and the Watchlist tab stay in sync.
    return BlocProvider<WatchlistBloc>.value(
      value: getIt<WatchlistBloc>()..add(const WatchlistStarted()),
      child: MaterialApp(
        title: 'Crypto Pulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: const SplashPage(),
      ),
    );
  }
}
