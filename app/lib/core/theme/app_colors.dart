import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bg = Color(0xFF070A12);
  static const surface = Color(0xFF0E1424);
  static const card = Color(0xFF151C2F);
  static const cardHigh = Color(0xFF1B2440);
  static const border = Color(0x1AFFFFFF);

  static const primary = Color(0xFF5B8CFF);
  static const accent = Color(0xFF8B5CF6);
  static const gold = Color(0xFFFFC53D);

  static const gain = Color(0xFF16C784);
  static const loss = Color(0xFFEA3943);

  static const textPrimary = Color(0xFFF2F5FA);
  static const textSecondary = Color(0xFF8F9BB3);
  static const textMuted = Color(0xFF5C6784);

  static const brandGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Used by the market overview card.
  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1B2A5E), Color(0xFF3B2A7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color trend(bool up) => up ? gain : loss;
}
