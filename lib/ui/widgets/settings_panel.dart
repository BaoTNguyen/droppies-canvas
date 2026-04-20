import 'package:flutter/material.dart';
import '../../settings/canvas_settings.dart';
import '../../grid/grid_config.dart';

class SettingsPanel extends StatelessWidget {
  final CanvasSettings settings;
  final ValueChanged<CanvasSettings> onSettingsChanged;

  const SettingsPanel({super.key, required this.settings, required this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xE6242438),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.4),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              _buildGridSection(),
              const SizedBox(height: 28),
              _buildBackgroundSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grid', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _GridTypeToggle(
          current: settings.grid.type,
          onChanged: (type) {
            settings.grid = GridConfig(
              type: type,
              cellWidth: settings.grid.cellWidth,
              lineWidth: settings.grid.lineWidth,
              boxRatio: settings.grid.boxRatio,
            );
            onSettingsChanged(settings);
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Width',
          value: settings.grid.cellWidth,
          min: 10,
          max: 200,
          suffix: '${settings.grid.cellWidth.round()} px',
          onChanged: (v) {
            settings.grid = GridConfig(
              type: settings.grid.type,
              cellWidth: v,
              lineWidth: settings.grid.lineWidth,
              boxRatio: settings.grid.boxRatio,
            );
            onSettingsChanged(settings);
          },
        ),
        const SizedBox(height: 8),
        _buildSlider(
          label: 'Box Ratio',
          value: settings.grid.boxRatio,
          min: 0.1,
          max: 5.0,
          suffix: settings.grid.boxRatio.toStringAsFixed(1),
          onChanged: (v) {
            settings.grid = GridConfig(
              type: settings.grid.type,
              cellWidth: settings.grid.cellWidth,
              lineWidth: settings.grid.lineWidth,
              boxRatio: v,
            );
            onSettingsChanged(settings);
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(suffix, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        SliderTheme(
          data: const SliderThemeData(
            activeTrackColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: Colors.white12,
            trackHeight: 2,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildBackgroundSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Background Color', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _bgPreset('Default', const Color(0xFF1a1a2e), CanvasSettings.defaultDark),
            _bgPreset('Light', const Color(0xFFF5F5F5), CanvasSettings.light),
            _bgPreset('Blueprint', const Color(0xFF1E3A6E), CanvasSettings.blueprint),
          ],
        ),
      ],
    );
  }

  Widget _bgPreset(String label, Color color, CanvasSettings Function() factory) {
    final isActive = settings.backgroundColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () {
        final preset = factory();
        preset.grid = settings.grid;
        onSettingsChanged(preset);
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white24,
                width: isActive ? 2.5 : 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GridTypeToggle extends StatelessWidget {
  final GridType current;
  final ValueChanged<GridType> onChanged;

  const _GridTypeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in GridType.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: current == type ? Colors.white : Colors.white24,
                    width: current == type ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.horizontal(
                    left: type == GridType.off ? const Radius.circular(6) : Radius.zero,
                    right: type == GridType.dots ? const Radius.circular(6) : Radius.zero,
                  ),
                  color: current == type ? Colors.white.withValues(alpha:0.1) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    type.name.toUpperCase(),
                    style: TextStyle(
                      color: current == type ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: current == type ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
