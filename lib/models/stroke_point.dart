import 'dart:math';

class StrokePoint {
  final double x;
  final double y;
  final double pressure;
  final double velocity;
  final int timestamp;

  const StrokePoint({
    required this.x,
    required this.y,
    required this.pressure,
    required this.velocity,
    required this.timestamp,
  });

  factory StrokePoint.fromMotion({
    required double x,
    required double y,
    required double pressure,
    required StrokePoint previousPoint,
    required int timestamp,
  }) {
    final dt = timestamp - previousPoint.timestamp;
    double vel;
    if (dt <= 0) {
      vel = previousPoint.velocity;
    } else {
      final dx = x - previousPoint.x;
      final dy = y - previousPoint.y;
      final distance = sqrt(dx * dx + dy * dy);
      vel = distance / dt;
      if (previousPoint.velocity > 0 && vel > 3 * previousPoint.velocity) {
        vel = 3 * previousPoint.velocity;
      }
    }
    return StrokePoint(
      x: x,
      y: y,
      pressure: pressure,
      velocity: vel,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
        'velocity': velocity,
        'timestamp': timestamp,
      };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['pressure'] as num).toDouble(),
        velocity: (json['velocity'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
      );
}
