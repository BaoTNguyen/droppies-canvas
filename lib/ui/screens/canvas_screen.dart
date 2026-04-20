import 'package:flutter/material.dart';
import '../../engine/drawing_engine.dart';
import '../../models/canvas_document.dart';
import '../../file_persistence/canvas_repository.dart';
import '../widgets/canvas_view.dart';
import '../widgets/toolbar.dart';
import '../widgets/color_palette.dart';
import '../widgets/settings_panel.dart';

class CanvasScreen extends StatefulWidget {
  final CanvasDocument document;
  final CanvasRepository? repository;

  const CanvasScreen({super.key, required this.document, this.repository});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  late final DrawingEngine _engine;
  late final TextEditingController _nameController;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _engine = DrawingEngine(document: widget.document);
    _nameController = TextEditingController(text: widget.document.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.document.name = _nameController.text.trim().isEmpty
        ? 'Untitled'
        : _nameController.text.trim();
    widget.document.touch();
    await widget.repository?.save(widget.document);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;

    return Scaffold(
      body: Stack(
        children: [
          // Canvas
          CanvasView(
            engine: _engine,
            onChanged: () => setState(() {}),
          ),

          // Top-left controls
          Positioned(
            top: pad.top + 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 10),
                Toolbar(
                  activeTool: _engine.activeTool,
                  onToolSelected: (t) => setState(() => _engine.activeTool = t),
                ),
                const SizedBox(height: 10),
                ColorPalette(
                  activeColor: _engine.activeColor,
                  onColorSelected: (c) => setState(() => _engine.activeColor = c),
                ),
              ],
            ),
          ),

          // Settings button (top-right)
          Positioned(
            top: pad.top + 12,
            right: 16,
            child: _iconButton(
              icon: Icons.settings,
              onTap: () => setState(() => _showSettings = !_showSettings),
            ),
          ),

          // Settings panel
          if (_showSettings)
            Positioned(
              top: pad.top + 56,
              right: 0,
              bottom: 0,
              child: SettingsPanel(
                settings: _engine.document.settings,
                onSettingsChanged: (s) {
                  setState(() => _engine.document.settings = s);
                },
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: pad.bottom + 16,
            left: 16,
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.undo,
                  onTap: _engine.history.canUndo
                      ? () { _engine.history.undo(); setState(() {}); }
                      : null,
                  enabled: _engine.history.canUndo,
                ),
                const SizedBox(width: 8),
                _iconButton(
                  icon: Icons.redo,
                  onTap: _engine.history.canRedo
                      ? () { _engine.history.redo(); setState(() {}); }
                      : null,
                  enabled: _engine.history.canRedo,
                ),
              ],
            ),
          ),

          // Bottom-right: save + export
          Positioned(
            bottom: pad.bottom + 16,
            right: 16,
            child: _iconButton(
              icon: Icons.save,
              onTap: () async {
                await _save();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconButton(
          icon: Icons.arrow_back,
          onTap: () async {
            await _save();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 200,
          height: 36,
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Name of your canvas',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.4)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.white.withValues(alpha:0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha:0.12)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }
}
