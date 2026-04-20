import 'dart:math';
import 'stroke_point.dart';

enum PenType { fixed, pressureSensitive, velocitySensitive, velocityInverted }

class PenConfig {
  final String id;
  final String name;
  final PenType type;
  final double width;
  final double pressureSensitivity; // 0.0–1.0
  final double velocityImpact;      // 0.0–1.0
  final bool zoomLocked;

  const PenConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.width,
    required this.pressureSensitivity,
    required this.velocityImpact,
    required this.zoomLocked,
  });

  double computeWidth(StrokePoint point, double currentScale) {
    double w;
    switch (type) {
      case PenType.fixed:
        w = width;
      case PenType.pressureSensitive:
        final factor = max(0.1, (1.0 - pressureSensitivity) + pressureSensitivity * point.pressure);
        w = width * factor;
      case PenType.velocitySensitive:
        final factor = 1.0 / (1.0 + velocityImpact * point.velocity * 0.1);
        w = width * factor;
      case PenType.velocityInverted:
        final factor = 1.0 + velocityImpact * point.velocity * 0.02;
        w = width * factor;
    }
    if (zoomLocked) w /= currentScale;
    return w;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'width': width,
        'pressureSensitivity': pressureSensitivity,
        'velocityImpact': velocityImpact,
        'zoomLocked': zoomLocked,
      };

  factory PenConfig.fromJson(Map<String, dynamic> json) => PenConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        type: PenType.values.firstWhere((t) => t.name == json['type']),
        width: (json['width'] as num).toDouble(),
        pressureSensitivity: (json['pressureSensitivity'] as num).toDouble(),
        velocityImpact: (json['velocityImpact'] as num).toDouble(),
        zoomLocked: json['zoomLocked'] as bool,
      );
}
