import 'package:flutter/animation.dart';

/// One place for animation speeds and curves, so the whole app feels consistent.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration chart = Duration(milliseconds: 700);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve bounce = Curves.easeOutBack;
}
