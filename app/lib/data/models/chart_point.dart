import 'package:equatable/equatable.dart';

class ChartPoint extends Equatable {
  const ChartPoint(this.time, this.price);

  final DateTime time;
  final double price;

  /// Backend format: `[timestampMs, price]`.
  factory ChartPoint.fromList(List<dynamic> raw) => ChartPoint(
        DateTime.fromMillisecondsSinceEpoch((raw[0] as num).toInt()),
        (raw[1] as num).toDouble(),
      );

  @override
  List<Object?> get props => [time, price];
}
