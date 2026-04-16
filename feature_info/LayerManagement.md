# Layer Management

## Summary
Users can organize canvas content into a hierarchical list of named layers and layer folders, similar to the layer panels in professional illustration software. Each layer holds a collection of canvas components (strokes, shapes, text boxes, images) and can be independently shown or hidden, reordered by drag-and-drop, and given an opacity value and a Skia blend mode. A pencil icon indicates which layer is currently active for drawing. Layers and folders are synced across all participants in an online collaboration session in real time.

## How It Works
The layer tree is rooted at a `DrawingProgramLayerListItem` owned by `DrawingProgramLayerManager`. Each list item is either a `DrawingProgramLayer` (leaf, holds a `CanvasComponentContainer` component list) or a `DrawingProgramLayerFolder` (node, holds a child ordered list). The tree is stored as a `NetworkingObjects::NetObjOrderedList`, which serializes via `cereal` for file save/load and propagates mutations over the network. Display metadata (name, alpha, visibility, blend mode) is held in separate `NetObjOwnerPtr<NameData>` and `NetObjOwnerPtr<DisplayData>` sub-objects so that individual property changes can be sent as small delta messages rather than full layer payloads. The GUI is rendered by `DrawingProgramLayerManagerGUI` and embedded in `Toolbar::layer_menu()`.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Layer manager (API) | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerManager.hpp` | `DrawingProgramLayerManager` |
| Layer list item (node/leaf) | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerListItem.hpp` | `DrawingProgramLayerListItem`, `DrawingProgramLayerListItemMetaInfo` |
| Leaf layer logic | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayer.hpp` | `DrawingProgramLayer` |
| Folder layer logic | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerFolder.hpp` | `DrawingProgramLayerFolder` |
| GUI panel | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerManagerGUI.hpp` | `DrawingProgramLayerManagerGUI` |
| Blend mode enum + serialization | `infinipaint-0.4.2/src/DrawingProgram/Layers/SerializedBlendMode.hpp` | `SerializedBlendMode` |
| Toolbar layer menu entry point | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::layer_menu()` |
| Undo data structure | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerListItem.hpp` | `DrawingProgramLayerListItemUndoData` |

## User-Facing Pros
- **Full blend mode library**: All 29 Skia blend modes are exposed (Source Over, Multiply, Screen, Overlay, etc.), which covers standard compositing operations without needing an external program.
- **Drag-and-drop reordering with folder support**: Layers and folders can be rearranged interactively, and folders can be opened/closed to manage complex documents without scrolling through a flat list.
- **Visibility toggle per layer**: The eye icon lets users hide layers without deleting content, useful for comparing design iterations.
- **Collaborative layer sync**: Layer additions, deletions, renames, and reorders propagate to all connected clients, so remote collaborators always see the same layer structure.
- **Per-layer opacity**: Numeric alpha control allows non-destructive transparency adjustments to entire layer groups.

## User-Facing Cons / Limitations
- **No layer locking**: There is no way to lock a layer against accidental edits; any collaborator or the user themselves can draw on any visible layer.
- **Blend modes apply per layer, not per object**: Individual canvas components (strokes, shapes) cannot have their own blend mode — only the enclosing layer's blend mode is composited.
- **No layer thumbnail preview**: The layer panel shows only the layer name and icons; users cannot visually identify layer contents without toggling visibility.
- **Eraser operates across all visible layers by default**: The `LayerSelector` enum exposes both `ALL_VISIBLE_LAYERS` and `LAYER_BEING_EDITED` modes, but the eraser's behavior with multi-layer documents requires careful workflow management.

## Decision Guidance
Keep this feature. The networked ordered-list design is well-suited to collaborative editing and the serialization is compact. Prioritize adding a layer lock mechanism before exposing the application to users who need to protect reference layers from accidental strokes.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — drawing tools commit objects to the active layer
- [UndoRedo.md](UndoRedo.md) — layer creation/deletion/reorder operations are undoable
- [OnlineCollaboration.md](OnlineCollaboration.md) — layer state is part of the synchronized world
