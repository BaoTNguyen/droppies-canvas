import 'package:flutter/painting.dart';
import '../grid/grid_config.dart';

class CanvasSettings {
  GridConfig grid;
  Color backgroundColor;

  CanvasSettings({required this.grid, required this.backgroundColor});

  factory CanvasSettings.defaultDark() => CanvasSettings(
        grid: GridConfig(),
        backgroundColor: const Color(0xFF1a1a2e),
      );

  factory CanvasSettings.light() => CanvasSettings(
        grid: GridConfig(),
        backgroundColor: const Color(0xFFF5F5F5),
      );

  factory CanvasSettings.blueprint() => CanvasSettings(
        grid: GridConfig(),
        backgroundColor: const Color(0xFF1E3A6E),
      );

  Map<String, dynamic> toJson() => {
        'grid': grid.toJson(),
        'backgroundColor': backgroundColor.toARGB32(),
      };

  factory CanvasSettings.fromJson(Map<String, dynamic> json) {
    Color bgColor;
    try {
      final bgValue = json['backgroundColor'];
      bgColor = bgValue is int ? Color(bgValue) : const Color(0xFF1a1a2e);
    } catch (_) {
      bgColor = const Color(0xFF1a1a2e);
    }

    GridConfig grid;
    if (json.containsKey('grid') && json['grid'] is Map<String, dynamic>) {
      grid = GridConfig.fromJson(json['grid'] as Map<String, dynamic>);
    } else {
      grid = GridConfig();
    }

    return CanvasSettings(grid: grid, backgroundColor: bgColor);
  }
}
