import 'package:flutter/painting.dart';
import 'package:uuid/uuid.dart';
import 'stroke_point.dart';

enum ToolType { pen, eraser, line, rectangle, ellipse, text, selection }

class Stroke {
  final String id;
  final List<StrokePoint> points;
  final Color color;
  final double baseWidth;
  final ToolType tool;

  Stroke({
    required this.points,
    required this.color,
    required this.baseWidth,
    required this.tool,
    String? id,
  }) : id = id ?? _generateId();

  static final _uuid = Uuid();
  static String _generateId() => _uuid.v4();

  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    double minX = points[0].x, maxX = points[0].x;
    double minY = points[0].y, maxY = points[0].y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final half = baseWidth / 2;
    return Rect.fromLTRB(minX - half, minY - half, maxX + half, maxY + half);
  }

  bool containsPoint(Offset point, double tolerance) {
    if (points.isEmpty) return false;
    if (points.length == 1) {
      return (Offset(points[0].x, points[0].y) - point).distance <= tolerance;
    }
    for (int i = 1; i < points.length; i++) {
      final a = Offset(points[i - 1].x, points[i - 1].y);
      final b = Offset(points[i].x, points[i].y);
      if (_distToSegment(point, a, b) <= tolerance) return true;
    }
    return false;
  }

  static double _distToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return ap.distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lenSq).clamp(0.0, 1.0);
    final closest = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
    return (p - closest).distance;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.toARGB32(),
        'baseWidth': baseWidth,
        'tool': tool.name,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('points') ||
        !json.containsKey('baseWidth') ||
        !json.containsKey('tool')) {
      throw const FormatException('Missing required stroke fields');
    }
    return Stroke(
      id: json['id'] as String?,
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      baseWidth: (json['baseWidth'] as num).toDouble(),
      tool: ToolType.values.firstWhere((t) => t.name == json['tool']),
    );
  }
}
