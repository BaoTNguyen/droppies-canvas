import 'dart:convert';
import 'dart:io';
import '../models/canvas_document.dart';

class CanvasRepository {
  final String storageDirectory;

  CanvasRepository({required this.storageDirectory});

  String _filePath(String id) => '$storageDirectory/$id.json';

  Future<void> save(CanvasDocument doc) async {
    final file = File(_filePath(doc.id));
    await file.writeAsString(jsonEncode(doc.toJson()));
  }

  Future<CanvasDocument?> load(String id) async {
    final file = File(_filePath(id));
    if (!await file.exists()) return null;
    try {
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      return CanvasDocument.fromJson(jsonDecode(content) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String id) async {
    final file = File(_filePath(id));
    if (await file.exists()) await file.delete();
  }

  Future<List<CanvasDocument>> listAll() async {
    final dir = Directory(storageDirectory);
    if (!await dir.exists()) return [];
    final docs = <CanvasDocument>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          if (content.isEmpty) continue;
          docs.add(CanvasDocument.fromJson(
              jsonDecode(content) as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    return docs;
  }

  Future<bool> exists(String id) async {
    return File(_filePath(id)).exists();
  }
}
