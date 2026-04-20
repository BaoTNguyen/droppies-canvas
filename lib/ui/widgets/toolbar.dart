import 'package:flutter/material.dart';
import '../../models/stroke.dart';

class Toolbar extends StatelessWidget {
  final ToolType activeTool;
  final ValueChanged<ToolType> onToolSelected;

  const Toolbar({super.key, required this.activeTool, required this.onToolSelected});

  static const _tools = [
    (ToolType.pen, Icons.edit, 'Pen'),
    (ToolType.eraser, Icons.auto_fix_normal, 'Eraser'),
    (ToolType.line, Icons.show_chart, 'Line'),
    (ToolType.rectangle, Icons.crop_square, 'Rectangle'),
    (ToolType.ellipse, Icons.circle_outlined, 'Ellipse'),
    (ToolType.text, Icons.text_fields, 'Text'),
  ];

  static const _enabledTools = {ToolType.pen, ToolType.eraser};

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (tool, icon, label) in _tools)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ToolButton(
              icon: icon,
              label: label,
              isActive: activeTool == tool,
              isEnabled: _enabledTools.contains(tool),
              onTap: () => onToolSelected(tool),
            ),
          ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isEnabled ? label : '$label (coming soon)',
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha:0.15)
                : Colors.white.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? Colors.white : Colors.white.withValues(alpha:0.1),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (isActive ? Colors.white : Colors.white70)
                : Colors.white24,
          ),
        ),
      ),
    );
  }
}
