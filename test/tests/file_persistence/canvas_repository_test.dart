import 'dart:io';
import 'package:test/test.dart';
import 'package:droppies_canvas/models/canvas_document.dart';
import 'package:droppies_canvas/file_persistence/canvas_repository.dart';

void main() {
  late Directory tempDir;
  late CanvasRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('droppies_test_');
    repo = CanvasRepository(storageDirectory: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('Save and Load', () {
    test('saved document can be loaded by id', () async {
      final doc = CanvasDocument.create(name: 'Persist Me');
      await repo.save(doc);
      final loaded = await repo.load(doc.id);
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Persist Me');
    });

    test('load returns null for unknown id', () async {
      final result = await repo.load('nonexistent-id-xyz');
      expect(result, isNull);
    });

    test('overwriting with same id updates the document', () async {
      final doc = CanvasDocument.create(name: 'Original');
      await repo.save(doc);
      doc.name = 'Updated';
      doc.touch();
      await repo.save(doc);
      final loaded = await repo.load(doc.id);
      expect(loaded!.name, 'Updated');
    });

    // EDGE CASE: saving document with name containing special characters
    test('document name with special chars is saved and loaded correctly', () async {
      final doc = CanvasDocument.create(name: 'Canvas: Notes/Ideas & More!');
      await repo.save(doc);
      final loaded = await repo.load(doc.id);
      expect(loaded!.name, 'Canvas: Notes/Ideas & More!');
    });

    // EDGE CASE: load from empty storage directory does not throw
    test('load from empty directory returns null', () async {
      final result = await repo.load('anything');
      expect(result, isNull);
    });
  });

  group('Delete', () {
    test('deleted document returns null on load', () async {
      final doc = CanvasDocument.create(name: 'Delete Me');
      await repo.save(doc);
      await repo.delete(doc.id);
      expect(await repo.load(doc.id), isNull);
    });

    // EDGE CASE: deleting non-existent id does not throw
    test('delete of unknown id is a no-op', () async {
      expect(() => repo.delete('ghost-id'), returnsNormally);
    });
  });

  group('ListAll', () {
    test('listAll returns all saved documents', () async {
      final a = CanvasDocument.create(name: 'A');
      final b = CanvasDocument.create(name: 'B');
      final c = CanvasDocument.create(name: 'C');
      await repo.save(a);
      await repo.save(b);
      await repo.save(c);

      final all = await repo.listAll();
      expect(all.map((d) => d.name), containsAll(['A', 'B', 'C']));
    });

    test('listAll on empty storage returns empty list', () async {
      expect(await repo.listAll(), isEmpty);
    });

    test('listAll does not include deleted documents', () async {
      final doc = CanvasDocument.create(name: 'Gone');
      await repo.save(doc);
      await repo.delete(doc.id);
      final all = await repo.listAll();
      expect(all.any((d) => d.id == doc.id), isFalse);
    });
  });

  group('Exists', () {
    test('exists returns true after save', () async {
      final doc = CanvasDocument.create(name: 'Check');
      await repo.save(doc);
      expect(await repo.exists(doc.id), isTrue);
    });

    test('exists returns false for unknown id', () async {
      expect(await repo.exists('nope'), isFalse);
    });

    test('exists returns false after delete', () async {
      final doc = CanvasDocument.create(name: 'Temp');
      await repo.save(doc);
      await repo.delete(doc.id);
      expect(await repo.exists(doc.id), isFalse);
    });
  });

  group('Corruption handling', () {
    // EDGE CASE: corrupted file on disk is skipped in listAll, doesn't crash
    test('corrupted save file is skipped in listAll', () async {
      final doc = CanvasDocument.create(name: 'Good Doc');
      await repo.save(doc);
      // Write a corrupt file directly
      final corruptFile = File('${tempDir.path}/corrupt-id.json');
      await corruptFile.writeAsString('{this is not json}}}');

      expect(() => repo.listAll(), returnsNormally);
      final all = await repo.listAll();
      expect(all.any((d) => d.name == 'Good Doc'), isTrue);
    });

    // EDGE CASE: empty file on disk does not throw
    test('empty save file is handled gracefully', () async {
      final emptyFile = File('${tempDir.path}/empty-id.json');
      await emptyFile.writeAsString('');
      expect(await repo.load('empty-id'), isNull);
    });
  });
}
