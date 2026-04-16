# Feature Index

| Feature | One-line summary | Complexity | Verdict Signal |
|---------|-----------------|------------|----------------|
| [BrushAndDrawingTools](BrushAndDrawingTools.md) | Freehand, geometric, and shape-drawing tools with pressure sensitivity and zoom-relative sizing | High | Keep |
| [LayerManagement](LayerManagement.md) | Hierarchical named layers with blend modes, alpha, visibility, and real-time collaborative sync | High | Keep |
| [OnlineCollaboration](OnlineCollaboration.md) | Real-time multi-user canvas editing via WebRTC P2P with live cursors and in-app chat | High | Keep |
| [RichTextEditing](RichTextEditing.md) | Inline rich-text boxes with per-character styling, alignment, RTL support, and font selection | High | Keep |
| [SelectionAndTransform](SelectionAndTransform.md) | Rect/lasso multi-select with translate, scale, rotate (including movable pivot), copy/paste | Medium | Keep |
| [CanvasNavigation](CanvasNavigation.md) | Infinite canvas pan, zoom, rotation with smooth animated bookmark jumps and temporary tool shortcuts | Medium | Keep |
| [Bookmarks](Bookmarks.md) | Named camera-position bookmarks organized in drag-and-drop folders, synced to all collaborators | Medium | Keep |
| [GridSystem](GridSystem.md) | Multiple configurable GPU-shader reference grids (circle points, square points, lines) with coordinate labels | Medium | Keep |
| [ColorPicker](ColorPicker.md) | Dual foreground/fill color slots with named palettes and a radial quick-access ring | Medium | Keep |
| [UndoRedo](UndoRedo.md) | 250-step per-client undo/redo stack with save-point awareness and NetID remapping for collaboration | Medium | Keep |
| [CanvasExport](CanvasExport.md) | Region-capture export to JPG, PNG, WEBP, or SVG at arbitrary resolution with transparent background support | Medium | Keep |
| [FileManagement](FileManagement.md) | Self-contained .infpnt binary sessions with multi-tab support, drag-drop open, and version migration | Medium | Keep |
| [TabletSupport](TabletSupport.md) | Pressure-sensitive strokes with configurable smoothing, button mapping, and eraser-tip auto-detection | Medium | Keep |
| [ImageEmbedding](ImageEmbedding.md) | Drag-and-drop or URL-based embedding of images and arbitrary files as canvas objects with network sync | Medium | Keep |

**Complexity**: Low / Medium / High — relative implementation complexity within this codebase  
**Verdict Signal**: Keep / Consider Replacing / Remove — based on the pros/cons analysis in each feature file
