# Undo / Redo

## Summary
Infinipaint maintains an undo/redo stack with up to 250 steps that allows users to reverse and replay canvas mutations. Operations that are undoable include placing, erasing, moving, and resizing canvas objects; creating, deleting, renaming, and reordering layers; and creating or removing bookmarks. The undo stack tracks which action was current at the last save, enabling the application to accurately flag unsaved changes. In collaborative sessions the undo stack is per-client — each user can undo their own recent actions independently.

## How It Works
`WorldUndoManager` maintains two `std::deque<std::unique_ptr<WorldUndoAction>>` queues (undo and redo) capped at 250 entries each. Each undoable operation creates a concrete subclass of `WorldUndoAction` that implements `undo()` and `redo()` as lambdas or method calls. Because canvas objects have `NetworkingObjects::NetObjID` identifiers that can be reassigned when new objects are created over the network, `WorldUndoManager` keeps a bidirectional `undoIDToNetID` / `netIDToUndoID` map so that undo actions can find their target objects even if their network IDs change. `set_save_action()` records a pointer to the action that was at the top when the file was saved; the manager compares against this pointer to derive `World::hasUnsavedLocalChanges`. `World::undo_with_checks()` and `redo_with_checks()` delegate to `WorldUndoManager` after ensuring no tool is mid-stroke (via `DrawingProgram::prevent_undo_or_redo()`).

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Undo manager | `infinipaint-0.4.2/src/WorldUndoManager.hpp` | `WorldUndoManager`, undo/redo queues, `set_save_action()` |
| Undo action base | `infinipaint-0.4.2/src/WorldUndoManager.hpp` | `WorldUndoAction`, `undo()`, `redo()` virtual methods |
| NetID / UndoID mapping | `infinipaint-0.4.2/src/WorldUndoManager.hpp` | `undoIDToNetID`, `netIDToUndoID`, `reassign_netid()` |
| Unsaved changes tracking | `infinipaint-0.4.2/src/World.hpp` | `World::hasUnsavedLocalChanges` |
| Guard during mid-stroke | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `DrawingProgram::prevent_undo_or_redo()` |
| World undo entry points | `infinipaint-0.4.2/src/World.hpp` | `World::undo_with_checks()`, `World::redo_with_checks()` |
| Layer undo integration | `infinipaint-0.4.2/src/DrawingProgram/Layers/DrawingProgramLayerManager.hpp` | `add_undo_place_component()`, `add_undo_erase_components()` |

## User-Facing Pros
- **250-step depth**: The queue limit of 250 actions is generous for typical session lengths and avoids memory exhaustion on long drawing sessions.
- **Save-point awareness**: The manager knows exactly which action was current when the file was last saved and computes `hasUnsavedLocalChanges` precisely, so the application only prompts "unsaved changes" when there are actual uncommitted edits.
- **Guards against mid-stroke undo**: `prevent_undo_or_redo()` blocks undo while a brush stroke is in progress, preventing the partial-stroke edge case that would leave orphaned data.
- **NetID remapping**: When collaborative edits reassign network object IDs, the undo manager automatically remaps its internal references, keeping the undo stack valid even after concurrent remote operations.
- **Layer-level undo**: Layer creation, deletion, and reordering operations are undoable as `WorldUndoAction` subclasses, not just canvas object placement.

## User-Facing Cons / Limitations
- **Per-client stack, not shared**: Undo is local to each participant. If User A undoes an action that User B subsequently built upon, the resulting state can be inconsistent. The code comment in `UndoManager.hpp` explicitly acknowledges this collision scenario.
- **No undo history panel**: While `get_front_undo_queue_names()` exists on `WorldUndoManager` to retrieve a list of action names, there is no UI panel displaying the full stack so users can jump to an arbitrary past state.
- **Undo queue is lost on session end**: The undo stack is not serialized to the `.infpnt` file (the save format restores canvas state but not the action history), so reopening a file starts with an empty stack.
- **Redo stack is cleared on new action**: Any new drawing action after one or more undos clears the entire redo queue — standard behavior but can frustrate users who undo too many steps.

## Decision Guidance
Keep this feature. The NetID-remapping design is an important robustness detail for the collaborative context. The most valuable improvement would be persisting the undo queue to disk (at the cost of larger file sizes) and exposing a UI history list for power users. The collaborative undo collision limitation is a known hard problem; the current approach of per-client stacks is the pragmatic choice for a WebRTC-based system without an authoritative transform server.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — stroke commits push undo actions
- [LayerManagement.md](LayerManagement.md) — layer operations push undo actions
- [SelectionAndTransform.md](SelectionAndTransform.md) — transforms push undo actions
- [OnlineCollaboration.md](OnlineCollaboration.md) — undo has documented multi-client collision edge cases
