import 'dart:io';
import 'package:test/test.dart';
import 'package:flutter/painting.dart';
import 'package:droppies_canvas/export/obsidian_exporter.dart';
import 'package:droppies_canvas/models/canvas_document.dart';
import 'package:droppies_canvas/models/stroke.dart';
import 'package:droppies_canvas/models/stroke_point.dart';

void main() {
  late Directory tempVault;
  late ObsidianExporter exporter;
  late CanvasDocument doc;

  setUp(() async {
    tempVault = await Directory.systemTemp.createTemp('droppies_vault_test_');
    exporter = ObsidianExporter();
    doc = CanvasDocument.create(name: 'My Drawing');
    doc.strokes.add(Stroke(
      points: [
        StrokePoint(x: 100, y: 100, pressure: 0.5, velocity: 5.0, timestamp: 0),
        StrokePoint(x: 200, y: 200, pressure: 0.6, velocity: 6.0, timestamp: 50),
      ],
      color: const Color(0xFF3A7BD5),
      baseWidth: 5.0,
      tool: ToolType.pen,
    ));
  });

  tearDown(() async {
    if (await tempVault.exists()) await tempVault.delete(recursive: true);
  });

  group('Filename sanitization', () {
    test('simple name is unchanged', () {
      expect(exporter.sanitizeFilename('My Drawing'), 'My Drawing');
    });

    test('forward slash is replaced', () {
      final result = exporter.sanitizeFilename('Notes/Ideas');
      expect(result.contains('/'), isFalse);
    });

    test('backslash is replaced', () {
      final result = exporter.sanitizeFilename('Notes\\Ideas');
      expect(result.contains('\\'), isFalse);
    });

    test('null bytes are removed', () {
      final result = exporter.sanitizeFilename('Bad\x00Name');
      expect(result.contains('\x00'), isFalse);
    });

    // EDGE CASE: name longer than 200 chars is truncated to safe length
    test('name longer than 200 chars is truncated', () {
      final long = 'A' * 300;
      expect(exporter.sanitizeFilename(long).length, lessThanOrEqualTo(200));
    });

    // EDGE CASE: empty name uses a fallback
    test('empty name gets a non-empty fallback', () {
      expect(exporter.sanitizeFilename('').isNotEmpty, isTrue);
    });

    test('colons are replaced (Windows / macOS incompatible)', () {
      final result = exporter.sanitizeFilename('Time: 10:30');
      expect(result.contains(':'), isFalse);
    });
  });

  group('Obsidian wikilink', () {
    test('generates correct wikilink format', () {
      final link = exporter.obsidianImageLink('My Drawing');
      expect(link, '![[Droppies/My Drawing.png]]');
    });

    test('wikilink uses sanitized filename', () {
      final link = exporter.obsidianImageLink('Notes/Ideas');
      expect(link.contains('/Droppies/'), isTrue);
      expect(link.endsWith('.png]]'), isTrue);
    });
  });

  group('PNG export', () {
    test('exportPng creates a file at the correct path', () async {
      final file = await exporter.exportPng(doc, tempVault.path);
      expect(await file.exists(), isTrue);
    });

    test('exported PNG path is within vault/Droppies/', () async {
      final file = await exporter.exportPng(doc, tempVault.path);
      expect(file.path, contains('Droppies'));
    });

    test('exported PNG filename matches sanitized canvas name', () async {
      final file = await exporter.exportPng(doc, tempVault.path);
      expect(file.path, contains(exporter.sanitizeFilename(doc.name)));
      expect(file.path, endsWith('.png'));
    });

    test('exported file is a non-empty PNG', () async {
      final file = await exporter.exportPng(doc, tempVault.path);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(0));
      // PNG magic bytes: 0x89 0x50 0x4E 0x47
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50); // 'P'
      expect(bytes[2], 0x4E); // 'N'
      expect(bytes[3], 0x47); // 'G'
    });

    // EDGE CASE: exporting empty canvas (no strokes) still produces a valid PNG
    test('empty canvas exports as valid PNG', () async {
      final emptyDoc = CanvasDocument.create(name: 'Empty');
      final file = await exporter.exportPng(emptyDoc, tempVault.path);
      final bytes = await file.readAsBytes();
      expect(bytes[0], 0x89);
    });

    // EDGE CASE: Droppies subdirectory is created if it does not exist
    test('creates Droppies subdirectory if missing', () async {
      final subDir = Directory('${tempVault.path}/Droppies');
      expect(await subDir.exists(), isFalse);
      await exporter.exportPng(doc, tempVault.path);
      expect(await subDir.exists(), isTrue);
    });

    // EDGE CASE: exporting same name twice overwrites without error
    test('exporting twice with same name overwrites without throwing', () async {
      await exporter.exportPng(doc, tempVault.path);
      expect(() => exporter.exportPng(doc, tempVault.path), returnsNormally);
    });

    // EDGE CASE: non-existent vault path is created automatically
    test('non-existent vault path is created during export', () async {
      final missingVault = '${tempVault.path}/new_vault';
      expect(await Directory(missingVault).exists(), isFalse);
      await exporter.exportPng(doc, missingVault);
      expect(await Directory(missingVault).exists(), isTrue);
    });
  });

  group('Markdown sidecar', () {
    test('exportMarkdownSidecar creates a .md file', () async {
      final file = await exporter.exportMarkdownSidecar(doc, tempVault.path);
      expect(await file.exists(), isTrue);
      expect(file.path, endsWith('.md'));
    });

    test('sidecar contains Obsidian wikilink to the PNG', () async {
      final file = await exporter.exportMarkdownSidecar(doc, tempVault.path);
      final content = await file.readAsString();
      expect(content, contains('![[Droppies/'));
      expect(content, contains('.png]]'));
    });

    test('sidecar contains YAML frontmatter with created date', () async {
      final file = await exporter.exportMarkdownSidecar(doc, tempVault.path);
      final content = await file.readAsString();
      expect(content, contains('---'));
      expect(content, contains('created:'));
    });

    test('sidecar contains droppies tag', () async {
      final file = await exporter.exportMarkdownSidecar(doc, tempVault.path);
      final content = await file.readAsString();
      expect(content, contains('droppies'));
    });
  });
}
