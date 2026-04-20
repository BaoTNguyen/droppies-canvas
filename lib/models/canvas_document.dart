import 'package:uuid/uuid.dart';
import 'stroke.dart';
import '../settings/canvas_settings.dart';

class CanvasDocument {
  final String id;
  String name;
  final List<Stroke> strokes;
  CanvasSettings settings;
  final DateTime createdAt;
  DateTime updatedAt;

  CanvasDocument._({
    required this.id,
    required this.name,
    required this.strokes,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  static final _uuid = Uuid();

  factory CanvasDocument.create({required String name}) {
    final now = DateTime.now();
    return CanvasDocument._(
      id: _uuid.v4(),
      name: name,
      strokes: [],
      settings: CanvasSettings.defaultDark(),
      createdAt: now,
      updatedAt: now,
    );
  }

  void touch() {
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'settings': settings.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CanvasDocument.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || !json.containsKey('name')) {
      throw const FormatException('Missing required fields: id, name');
    }

    final strokesList = json['strokes'] as List? ?? [];
    final strokes = <Stroke>[];
    for (final s in strokesList) {
      try {
        strokes.add(Stroke.fromJson(s as Map<String, dynamic>));
      } catch (_) {}
    }

    final settings = json.containsKey('settings') && json['settings'] is Map<String, dynamic>
        ? CanvasSettings.fromJson(json['settings'] as Map<String, dynamic>)
        : CanvasSettings.defaultDark();

    final createdAt = json.containsKey('createdAt')
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now();

    return CanvasDocument._(
      id: json['id'] as String,
      name: json['name'] as String,
      strokes: strokes,
      settings: settings,
      createdAt: createdAt,
      updatedAt: json.containsKey('updatedAt')
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
