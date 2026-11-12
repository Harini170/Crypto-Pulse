import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_router.dart';
import '../../widgets/glow_background.dart';

/// First screen: animated logo, then fades into the app.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      AppRouter.goHome(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.55),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 58),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.easeOutBack,
                      )
                      .then(delay: 150.ms)
                      .shimmer(duration: 1100.ms, color: Colors.white30),
                  const SizedBox(height: 26),
                  // App name
                  const Text(
                    'Crypto Pulse',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.4, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  // Tagline
                  const Text(
                    'Live market research',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ).animate(delay: 650.ms).fadeIn(duration: 500.ms),
                ],
              ),
            ),
            // Loading bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: Center(
                child: SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      minHeight: 4,
                      color: AppColors.primary,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ).animate(delay: 900.ms).fadeIn(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
