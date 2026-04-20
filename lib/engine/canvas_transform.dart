import 'dart:math';
import 'package:flutter/painting.dart';

class CanvasTransform {
  double translationX = 0.0;
  double translationY = 0.0;
  double scale = 1.0;
  double rotationDeg = 0.0;

  static const double minScale = 0.05;
  static const double maxScale = 50.0;

  void pan(double dx, double dy) {
    translationX += dx;
    translationY += dy;
  }

  void zoom(double factor, Offset focalPoint) {
    if (factor <= 0) return;
    final newScale = (scale * factor).clamp(minScale, maxScale);
    final ratio = newScale / scale;
    translationX = focalPoint.dx - (focalPoint.dx - translationX) * ratio;
    translationY = focalPoint.dy - (focalPoint.dy - translationY) * ratio;
    scale = newScale;
  }

  void rotateTo(double degrees) {
    rotationDeg = degrees % 360;
    if (rotationDeg < 0) rotationDeg += 360;
  }

  void resetToIdentity() {
    translationX = 0.0;
    translationY = 0.0;
    scale = 1.0;
    rotationDeg = 0.0;
  }

  Offset screenToCanvas(Offset screenPoint) {
    final dx = (screenPoint.dx - translationX) / scale;
    final dy = (screenPoint.dy - translationY) / scale;
    final rad = -rotationDeg * pi / 180;
    final cosR = cos(rad);
    final sinR = sin(rad);
    return Offset(dx * cosR - dy * sinR, dx * sinR + dy * cosR);
  }

  Offset canvasToScreen(Offset canvasPoint) {
    final rad = rotationDeg * pi / 180;
    final cosR = cos(rad);
    final sinR = sin(rad);
    final rx = canvasPoint.dx * cosR - canvasPoint.dy * sinR;
    final ry = canvasPoint.dx * sinR + canvasPoint.dy * cosR;
    return Offset(rx * scale + translationX, ry * scale + translationY);
  }
}
