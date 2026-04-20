import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/canvas_document.dart';
import '../../file_persistence/canvas_repository.dart';
import 'canvas_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CanvasRepository? _repo;
  List<CanvasDocument> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/canvases';
    await Directory(path).create(recursive: true);
    _repo = CanvasRepository(storageDirectory: path);
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_repo == null) return;
    final docs = await _repo!.listAll();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  Future<void> _createNew() async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) return;
    final doc = CanvasDocument.create(name: name.trim());
    await _repo?.save(doc);
    if (mounted) await _openCanvas(doc);
  }

  Future<void> _openCanvas(CanvasDocument doc) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CanvasScreen(document: doc, repository: _repo),
      ),
    );
    await _refresh();
  }

  Future<void> _delete(CanvasDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Delete Canvas?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${doc.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo?.delete(doc.id);
      await _refresh();
    }
  }

  Future<String?> _showNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('New Canvas', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Canvas name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.4)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha:0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Droppies Canvas'),
        centerTitle: false,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white54))
          : _docs.isEmpty
              ? _buildEmpty()
              : _buildList(),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF06D6A0),
              onPressed: _createNew,
              child: const Icon(Icons.add, color: Colors.black87),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brush, size: 64, color: Colors.white.withValues(alpha:0.15)),
          const SizedBox(height: 16),
          Text(
            'No canvases yet',
            style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create one',
            style: TextStyle(color: Colors.white.withValues(alpha:0.25), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _docs.length,
      itemBuilder: (context, i) {
        final doc = _docs[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _DocumentCard(
            doc: doc,
            onTap: () => _openCanvas(doc),
            onDelete: () => _delete(doc),
          ),
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final CanvasDocument doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({required this.doc, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha:0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: doc.settings.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Center(
                child: Text(
                  '${doc.strokes.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(doc.updatedAt),
                    style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha:0.3)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
