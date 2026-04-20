import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  final Color activeColor;
  final ValueChanged<Color> onColorSelected;

  static const presets = [
    Color(0xFFFF6B9D), // pink
    Color(0xFFFF8C42), // orange
    Color(0xFFFFD166), // yellow
    Color(0xFF06D6A0), // green
    Color(0xFF118AB2), // cyan
    Color(0xFF073B4C), // blue
    Color(0xFFFFFFFF), // white
    Color(0xFF000000), // black
  ];

  static const _extendedColors = [
    Color(0xFFFF0000), Color(0xFFFF4500), Color(0xFFFF6347),
    Color(0xFFFF6B9D), Color(0xFFFF1493), Color(0xFFDA70D6),
    Color(0xFF9B59B6), Color(0xFF6C5CE7), Color(0xFF3498DB),
    Color(0xFF118AB2), Color(0xFF00CED1), Color(0xFF06D6A0),
    Color(0xFF2ECC71), Color(0xFF27AE60), Color(0xFFA8E6CF),
    Color(0xFFFFD166), Color(0xFFFF8C42), Color(0xFFF39C12),
    Color(0xFFFFFFFF), Color(0xFFBDC3C7), Color(0xFF95A5A6),
    Color(0xFF7F8C8D), Color(0xFF34495E), Color(0xFF000000),
  ];

  const ColorPalette({super.key, required this.activeColor, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final color in presets)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onColorSelected(color),
              onLongPress: () => _showColorPicker(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isActiveColor(color)
                        ? Colors.white
                        : Colors.white.withValues(alpha:0.2),
                    width: _isActiveColor(color) ? 2.5 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isActiveColor(Color color) {
    return activeColor.toARGB32() == color.toARGB32();
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Pick a Color', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _extendedColors)
                GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isActiveColor(color)
                            ? Colors.white
                            : Colors.white24,
                        width: _isActiveColor(color) ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
