import 'dart:math';
import 'package:flutter/material.dart';
import '../../engine/drawing_engine.dart';
import '../../models/stroke.dart';
import '../../models/stroke_point.dart';
import '../../grid/grid_config.dart';

class CanvasView extends StatefulWidget {
  final DrawingEngine engine;
  final VoidCallback? onChanged;

  const CanvasView({super.key, required this.engine, this.onChanged});

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  final Map<int, Offset> _pointers = {};
  StrokePoint? _lastPoint;
  Offset? _eraserPos;

  Offset _pinchMid = Offset.zero;
  double _pinchDist = 0;

  static const double _eraserScreenRadius = 20.0;

  DrawingEngine get _engine => widget.engine;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _CanvasPainter(
          engine: _engine,
          eraserPos: _eraserPos,
          eraserRadius: _eraserScreenRadius,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;

    if (_pointers.length == 1) {
      final cp = _engine.transform.screenToCanvas(e.localPosition);
      final pressure = e.pressure > 0 ? e.pressure : 0.5;
      final pt = StrokePoint(
        x: cp.dx, y: cp.dy,
        pressure: pressure, velocity: 0,
        timestamp: e.timeStamp.inMilliseconds,
      );

      if (_engine.activeTool == ToolType.pen) {
        _engine.beginStroke(pt);
        _lastPoint = pt;
      } else if (_engine.activeTool == ToolType.eraser) {
        _engine.eraseAt(cp, _eraserScreenRadius / _engine.transform.scale);
        _eraserPos = e.localPosition;
      }
    } else if (_pointers.length == 2) {
      if (_engine.currentStroke != null) {
        _engine.endStroke();
        _lastPoint = null;
      }
      _initPinch();
    }

    _notify();
  }

  void _onMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;

    if (_pointers.length == 1) {
      final cp = _engine.transform.screenToCanvas(e.localPosition);
      final pressure = e.pressure > 0 ? e.pressure : 0.5;

      if (_engine.activeTool == ToolType.pen && _lastPoint != null) {
        final pt = StrokePoint.fromMotion(
          x: cp.dx, y: cp.dy,
          pressure: pressure,
          previousPoint: _lastPoint!,
          timestamp: e.timeStamp.inMilliseconds,
        );
        _engine.continueStroke(pt);
        _lastPoint = pt;
      } else if (_engine.activeTool == ToolType.eraser) {
        _engine.eraseAt(cp, _eraserScreenRadius / _engine.transform.scale);
        _eraserPos = e.localPosition;
      }
    } else if (_pointers.length == 2) {
      _updatePinch();
    }

    _notify();
  }

  void _onUp(PointerEvent e) {
    _pointers.remove(e.pointer);

    if (_pointers.isEmpty) {
      if (_engine.currentStroke != null) {
        _engine.endStroke();
        _lastPoint = null;
      }
      _eraserPos = null;
    } else if (_pointers.length == 1) {
      // Dropped from 2 to 1 pointer — don't resume drawing mid-gesture
    }

    _notify();
  }

  void _initPinch() {
    final pts = _pointers.values.toList();
    _pinchMid = (pts[0] + pts[1]) / 2;
    _pinchDist = (pts[0] - pts[1]).distance;
  }

  void _updatePinch() {
    final pts = _pointers.values.toList();
    if (pts.length < 2) return;

    final mid = (pts[0] + pts[1]) / 2;
    final dist = (pts[0] - pts[1]).distance;

    _engine.transform.pan(mid.dx - _pinchMid.dx, mid.dy - _pinchMid.dy);

    if (_pinchDist > 0 && dist > 0) {
      _engine.transform.zoom(dist / _pinchDist, mid);
    }

    _pinchMid = mid;
    _pinchDist = dist;
  }

  void _notify() {
    setState(() {});
    widget.onChanged?.call();
  }
}

class _CanvasPainter extends CustomPainter {
  final DrawingEngine engine;
  final Offset? eraserPos;
  final double eraserRadius;

  _CanvasPainter({required this.engine, this.eraserPos, this.eraserRadius = 20});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = engine.document.settings.backgroundColor,
    );

    canvas.save();
    canvas.translate(engine.transform.translationX, engine.transform.translationY);
    canvas.scale(engine.transform.scale);
    if (engine.transform.rotationDeg != 0) {
      canvas.rotate(engine.transform.rotationDeg * pi / 180);
    }

    _paintGrid(canvas, size);

    for (final stroke in engine.document.strokes) {
      _paintStroke(canvas, stroke);
    }

    final active = engine.currentStroke;
    if (active != null) _paintStroke(canvas, active);

    canvas.restore();

    if (eraserPos != null && engine.activeTool == ToolType.eraser) {
      canvas.drawCircle(
        eraserPos!,
        eraserRadius,
        Paint()
          ..color = Colors.white.withValues(alpha:0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final grid = engine.document.settings.grid;
    if (grid.type == GridType.off) return;

    final t = engine.transform;
    final corners = [
      t.screenToCanvas(Offset.zero),
      t.screenToCanvas(Offset(size.width, 0)),
      t.screenToCanvas(Offset(0, size.height)),
      t.screenToCanvas(Offset(size.width, size.height)),
    ];

    double lo = corners[0].dx, hi = corners[0].dx;
    double top = corners[0].dy, bot = corners[0].dy;
    for (final c in corners) {
      lo = min(lo, c.dx);
      hi = max(hi, c.dx);
      top = min(top, c.dy);
      bot = max(bot, c.dy);
    }

    if (grid.type == GridType.lines) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha:0.07)
        ..strokeWidth = grid.lineWidth / t.scale;

      final c0 = (lo / grid.cellWidth).floor();
      final c1 = (hi / grid.cellWidth).ceil();
      for (int c = c0; c <= c1; c++) {
        final x = c * grid.cellWidth;
        canvas.drawLine(Offset(x, top), Offset(x, bot), paint);
      }

      final h = grid.cellHeight;
      final r0 = (top / h).floor();
      final r1 = (bot / h).ceil();
      for (int r = r0; r <= r1; r++) {
        final y = r * h;
        canvas.drawLine(Offset(lo, y), Offset(hi, y), paint);
      }
    } else {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha:0.12)
        ..style = PaintingStyle.fill;
      final dotR = (grid.lineWidth + 0.5) / t.scale;

      final c0 = (lo / grid.cellWidth).floor();
      final c1 = (hi / grid.cellWidth).ceil();
      final h = grid.cellHeight;
      final r0 = (top / h).floor();
      final r1 = (bot / h).ceil();

      for (int c = c0; c <= c1; c++) {
        for (int r = r0; r <= r1; r++) {
          canvas.drawCircle(Offset(c * grid.cellWidth, r * h), dotR, paint);
        }
      }
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.baseWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.points.length == 1) {
      canvas.drawCircle(
        Offset(stroke.points[0].x, stroke.points[0].y),
        stroke.baseWidth / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path();
    path.moveTo(stroke.points[0].x, stroke.points[0].y);

    for (int i = 1; i < stroke.points.length; i++) {
      if (i < stroke.points.length - 1) {
        final cur = stroke.points[i];
        final nxt = stroke.points[i + 1];
        path.quadraticBezierTo(cur.x, cur.y, (cur.x + nxt.x) / 2, (cur.y + nxt.y) / 2);
      } else {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}
