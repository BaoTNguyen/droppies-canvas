import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../models/canvas_document.dart';

class ObsidianExporter {
  Future<File> exportPng(CanvasDocument doc, String vaultPath, {int width = 2048}) async {
    final height = width;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = doc.settings.backgroundColor,
    );

    if (doc.strokes.isNotEmpty) {
      double minX = double.infinity, maxX = double.negativeInfinity;
      double minY = double.infinity, maxY = double.negativeInfinity;
      for (final stroke in doc.strokes) {
        for (final p in stroke.points) {
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
        }
      }

      final cw = maxX - minX;
      final ch = maxY - minY;
      final margin = 50.0;
      final scaleX = cw > 0 ? (width - margin * 2) / cw : 1.0;
      final scaleY = ch > 0 ? (height - margin * 2) / ch : 1.0;
      final s = scaleX < scaleY ? scaleX : scaleY;
      final offsetX = margin - minX * s + (width - margin * 2 - cw * s) / 2;
      final offsetY = margin - minY * s + (height - margin * 2 - ch * s) / 2;

      for (final stroke in doc.strokes) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.baseWidth * s
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (stroke.points.length == 1) {
          final p = stroke.points[0];
          canvas.drawCircle(
            Offset(p.x * s + offsetX, p.y * s + offsetY),
            stroke.baseWidth * s / 2,
            paint..style = PaintingStyle.fill,
          );
        } else {
          final path = Path();
          path.moveTo(
            stroke.points[0].x * s + offsetX,
            stroke.points[0].y * s + offsetY,
          );
          for (int i = 1; i < stroke.points.length; i++) {
            path.lineTo(
              stroke.points[i].x * s + offsetX,
              stroke.points[i].y * s + offsetY,
            );
          }
          canvas.drawPath(path, paint);
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final sanitized = sanitizeFilename(doc.name);
    final dir = Directory('$vaultPath/Droppies');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/$sanitized.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  Future<File> exportMarkdownSidecar(CanvasDocument doc, String vaultPath) async {
    final sanitized = sanitizeFilename(doc.name);
    final dir = Directory('$vaultPath/Droppies');
    if (!await dir.exists()) await dir.create(recursive: true);

    final link = obsidianImageLink(doc.name);
    final content = '''---
title: $sanitized
created: ${doc.createdAt.toIso8601String()}
tags: [droppies]
---

$link
''';

    final file = File('${dir.path}/$sanitized.md');
    await file.writeAsString(content);
    return file;
  }

  String obsidianImageLink(String canvasName) {
    final parts = canvasName.split('/');
    final filename = sanitizeFilename(parts.last);
    if (parts.length > 1) {
      final prefix = parts.sublist(0, parts.length - 1).join('/');
      return '![[$prefix/Droppies/$filename.png]]';
    }
    return '![[Droppies/$filename.png]]';
  }

  String sanitizeFilename(String name) {
    if (name.isEmpty) return 'untitled';
    var result = name.replaceAll(RegExp(r'[/\\:*?"<>|\x00]'), '_');
    if (result.length > 200) result = result.substring(0, 200);
    if (result.isEmpty) return 'untitled';
    return result;
  }
}
