enum GridType { off, lines, dots }

class GridConfig {
  final GridType type;
  final double cellWidth;
  final double lineWidth;
  final double boxRatio; // clamped 0.1–10

  GridConfig({
    this.type = GridType.off,
    double cellWidth = 48.0,
    this.lineWidth = 1.0,
    double boxRatio = 1.0,
  })  : cellWidth = cellWidth < 1.0 ? 1.0 : cellWidth,
        boxRatio = boxRatio.clamp(0.1, 10.0);

  double get cellHeight => cellWidth * boxRatio;

  int visibleColumns({required double viewportLeft, required double viewportRight}) {
    final firstCol = (viewportLeft / cellWidth).floor();
    final lastCol = (viewportRight / cellWidth).ceil();
    return lastCol - firstCol + 1;
  }

  int visibleRows({required double viewportTop, required double viewportBottom}) {
    final h = cellHeight;
    final firstRow = (viewportTop / h).floor();
    final lastRow = (viewportBottom / h).ceil();
    return lastRow - firstRow + 1;
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'cellWidth': cellWidth,
        'lineWidth': lineWidth,
        'boxRatio': boxRatio,
      };

  factory GridConfig.fromJson(Map<String, dynamic> json) => GridConfig(
        type: GridType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => GridType.off,
        ),
        cellWidth: (json['cellWidth'] as num?)?.toDouble() ?? 48.0,
        lineWidth: (json['lineWidth'] as num?)?.toDouble() ?? 1.0,
        boxRatio: (json['boxRatio'] as num?)?.toDouble() ?? 1.0,
      );
}
