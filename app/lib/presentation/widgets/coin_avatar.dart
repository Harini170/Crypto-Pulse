import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/coin.dart';

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, required this.coin, this.size = 42, this.heroTag});

  final Coin coin;
  final double size;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: coin.image == null || coin.image!.isEmpty
            ? _fallback()
            : CachedNetworkImage(
                imageUrl: coin.image!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (_, __) => _fallback(),
                errorWidget: (_, __, ___) => _fallback(),
              ),
      ),
    );
    return heroTag == null ? avatar : Hero(tag: heroTag!, child: avatar);
  }

  Widget _fallback() {
    final hue = (coin.id.hashCode % 360).abs().toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue, 0.65, 0.5).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.6, 0.35).toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          coin.symbol.isEmpty ? '?' : coin.symbol.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}
