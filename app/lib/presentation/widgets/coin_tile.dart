import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/coin.dart';
import 'change_chip.dart';
import 'coin_avatar.dart';
import 'glass_card.dart';
import 'line_reveal.dart';
import 'price_flash.dart';
import 'sparkline.dart';

/// One coin card, shared by the market list and the watchlist.
class CoinTile extends StatelessWidget {
  const CoinTile({
    super.key,
    required this.coin,
    required this.heroPrefix,
    this.showRank = true,
    this.showSparkline = true,
  });

  final Coin coin;
  final String heroPrefix;
  final bool showRank;
  final bool showSparkline;

  @override
  Widget build(BuildContext context) {
    final tag = '$heroPrefix-${coin.id}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        onTap: () => AppRouter.openCoin(context, coin, heroTag: tag),
        child: Row(
          children: [
            if (showRank)
              Container(
                width: 26,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${coin.marketCapRank}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            CoinAvatar(coin: coin, heroTag: tag),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    '${coin.ticker}  ·  ${Fmt.compactUsd(coin.marketCap)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (showSparkline) ...[
              SizedBox(
                width: 78,
                height: 34,
                child: LineReveal(
                  child: Sparkline(data: coin.sparkline, isUp: coin.isUp),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceFlash(price: coin.currentPrice),
                const SizedBox(height: 4),
                ChangeChip(value: coin.priceChange24h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
