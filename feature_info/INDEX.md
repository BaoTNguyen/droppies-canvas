# Lorien Feature Index

Lorien v0.6.0 — Godot 3.x infinite canvas drawing app. One file per feature below.

| Feature | File | Summary | Keep / Revisit / Replace |
|---------|------|---------|--------------------------|
| Infinite Canvas | [infinite-canvas.md](infinite-canvas.md) | Unlimited pan/zoom workspace with per-project camera state persistence | |
| Brush Tool | [brush-tool.md](brush-tool.md) | Freehand drawing with pressure sensitivity, optimizer, and auto-split at 1,000 points | |
| Shape Tools | [shape-tools.md](shape-tools.md) | Line (15° snap), rectangle, and circle/ellipse tools — all baked to polylines on commit | |
| Eraser Tool | [eraser-tool.md](eraser-tool.md) | Whole-stroke deletion by painting; segment-intersection hit detection; undoable | |
| Selection Tool | [selection-tool.md](selection-tool.md) | Rubber-band select, move, copy/paste/duplicate, delete, and recolor strokes | |
| Color Palette System | [color-palette-system.md](color-palette-system.md) | Named palettes (1 built-in + custom), per-session memory, create/edit/delete dialogs | |
| Project Management | [project-management.md](project-management.md) | Multi-tab projects, lazy loading, binary DEFLATE file format, drag-and-drop open | |
| SVG Export | [svg-export.md](svg-export.md) | Exports all strokes as `<polyline>` elements; loses pressure/width data | |
| Settings & Preferences | [settings.md](settings.md) | 15+ settings across General, Appearance, Rendering, and Keybindings tabs | |
| Grid Overlay | [grid-overlay.md](grid-overlay.md) | Dots or lines reference grid; zoom-aware scaling; visual only (no snap) | |
| Undo / Redo | [undo-redo.md](undo-redo.md) | Per-project unlimited undo stack; covers draw, erase, move, delete, paste | |
| Session Persistence | [session-persistence.md](session-persistence.md) | Restores open project tabs, active project, and window size on next launch | |
| Distraction-Free Mode | [distraction-free-mode.md](distraction-free-mode.md) | Hides toolbar/menubar/statusbar with one key; all shortcuts still work | |
| Keyboard Shortcuts | [keyboard-shortcuts.md](keyboard-shortcuts.md) | Every action is remappable; multiple bindings per action; persisted in settings.cfg | |
| Localization | [localization.md](localization.md) | Custom plain-text i18n format; runtime language switching; shortcut hints in strings | |
| Rendering & Performance | [rendering-and-performance.md](rendering-and-performance.md) | AA modes, visibility culling, FPS throttling, HiDPI scaling | |
| Platformer Easter Egg | [platformer-easter-egg.md](platformer-easter-egg.md) | Hidden: spawn a physics character that walks on drawn strokes as platforms | |

---

## Quick-Reference: Known Gaps by Priority

| Gap | Feature | Severity |
|-----|---------|----------|
| No file validation on load | Project Management | High — corrupt file crashes the app |
| No autosave | Project Management | High — unsaved work lost on crash |
| Clear canvas has no undo | Undo/Redo | High — irreversible one-click data loss |
| Recolor has no undo | Selection Tool / Undo-Redo | Medium |
| SVG export loses pressure/width | SVG Export | Medium |
| Whole-stroke-only eraser | Eraser Tool | Medium |
| No free-form color picker for brush | Color Palette System | Medium |
| Off-screen strokes not selectable | Selection Tool | Medium |
| No snap-to-grid | Grid Overlay | Low–Medium |
| No stroke stabilizer / smoothing | Brush Tool | Low–Medium |
| No "fit all content" zoom shortcut | Infinite Canvas | Low |
| Shortcut templates resolve at parse time | Localization | Low |
