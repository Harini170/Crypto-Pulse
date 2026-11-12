import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Price text that briefly flashes green/red whenever the live price ticks.
class PriceFlash extends StatefulWidget {
  const PriceFlash({super.key, required this.price, this.style, this.alignEnd = true});

  final double price;
  final TextStyle? style;
  final bool alignEnd;

  @override
  State<PriceFlash> createState() => _PriceFlashState();
}

class _PriceFlashState extends State<PriceFlash> {
  Color _bg = Colors.transparent;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant PriceFlash old) {
    super.didUpdateWidget(old);
    if (old.price != widget.price) {
      setState(() => _bg = (widget.price > old.price ? AppColors.gain : AppColors.loss)
          .withOpacity(0.28));
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _bg = Colors.transparent);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        Fmt.price(widget.price),
        textAlign: widget.alignEnd ? TextAlign.end : TextAlign.start,
        style: widget.style ?? const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }
}
