import 'drawing_engine.dart';

abstract class CanvasAction {
  void apply(DrawingEngine engine);
  void revert(DrawingEngine engine);
}

class UndoRedoHistory {
  late DrawingEngine engine;

  final _undoStack = <CanvasAction>[];
  final _redoStack = <CanvasAction>[];

  int get stackDepth => _undoStack.length;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void push(CanvasAction action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    final action = _undoStack.removeLast();
    action.revert(engine);
    _redoStack.add(action);
  }

  void redo() {
    if (!canRedo) return;
    final action = _redoStack.removeLast();
    action.apply(engine);
    _undoStack.add(action);
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
