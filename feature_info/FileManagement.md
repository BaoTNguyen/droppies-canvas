# File Management

## Summary
Infinipaint saves and loads canvas sessions as `.infpnt` binary files that capture the complete canvas state — layers, components, bookmarks, grids, camera position, and embedded resources. Files can be opened via a menu dialog, by dragging and dropping onto the window, or via a URL drop (which triggers a background download). Dropping a non-`.infpnt` file (image, PDF, etc.) adds it as an embedded resource on the canvas rather than opening it as a new document. Multiple tabs (worlds) can be open simultaneously, each with its own file path and undo stack. Auto-save on quit prompts users to save unsaved tabs.

## How It Works
`World` implements `save_file()` and `load_file()` using `cereal::PortableBinaryOutputArchive` / `PortableBinaryInputArchive`. The archive traverses all subsystems: `DrawingProgram` (components and layers), `BookmarkManager`, `GridManager`, `ResourceManager` (binary blobs for images/files), and `DrawCamera`. A `VersionNumber` is written at the top of the archive so that `load_file()` can apply backwards-compatible migration logic when reading older files. `ResourceManager` embeds referenced file data (images, dropped files) as `ResourceData` binary blobs so the `.infpnt` file is fully self-contained. `MainProgram::worlds` is a `std::vector<std::shared_ptr<World>>` that supports multiple open tabs, and `new_tab()` creates a new `World` instance. The `Toolbar::save_func()` and `save_as_func()` drive the save flow; `Toolbar::open_file_selector()` uses SDL3's native file dialog (`SDL_ShowOpenFileDialog`) or a built-in fallback picker. Drag-and-drop file handling distinguishes `.infpnt` files (open as tab) from all other types (add to canvas).

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| World save/load | `infinipaint-0.4.2/src/World.hpp` | `World::save_file()`, `World::load_file()`, `save_to_file()`, `load_from_file()` |
| File extension constant | `infinipaint-0.4.2/src/World.hpp` | `World::FILE_EXTENSION = "infpnt"` |
| Resource embedding | `infinipaint-0.4.2/src/ResourceManager.hpp` | `ResourceManager`, `ResourceData`, `save_file()`, `load_file()` |
| Multi-tab management | `infinipaint-0.4.2/src/MainProgram.hpp` | `MainProgram::worlds`, `new_tab()`, `set_tab_to_close()` |
| Save/open toolbar actions | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::save_func()`, `save_as_func()`, `open_file_selector()` |
| Drag-drop file handling | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `DrawingProgram::add_file_to_canvas_by_path()`, `add_file_to_canvas_by_data()` |
| URL download of dropped files | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `DrawingProgram::droppedDownloadingFiles`, `update_downloading_dropped_files()` |
| Version number | `infinipaint-0.4.2/src/VersionConstants.hpp` | `VersionNumber` |

## User-Facing Pros
- **Self-contained binary format**: Embedded `ResourceData` blobs mean the `.infpnt` file includes all referenced images and files — sharing a single file with a collaborator gives them a complete session with no missing assets.
- **Drag-and-drop file adding**: Dropping an image file onto the canvas embeds it immediately as a canvas component without requiring an Import menu, reducing friction for reference-image workflows.
- **Multi-tab support**: Multiple canvas files can be open simultaneously in the same window, enabling cross-document copy-paste or side-by-side comparison.
- **URL drop with background download**: Dropping a web URL triggers a background `FileDownloader` fetch so the user can continue working while the asset loads.
- **Unsaved-changes guard**: `World::hasUnsavedLocalChanges` and the close-popup dialog prevent accidental data loss when closing tabs or the application.

## User-Facing Cons / Limitations
- **No autosave to disk**: The code has `autosave_to_directory()` as a method on `World`, but there is no timer-driven autosave visible in the Toolbar or MainProgram update loop; the feature appears to be infrastructure without a configured trigger.
- **File format is opaque binary**: The `.infpnt` format is a `cereal` portable binary archive — it cannot be diffed, version-controlled in a readable form, or inspected without the application itself.
- **No import/export from standard formats**: There is no mechanism to open a PSD, SVG, or ORA file as a canvas session; only `.infpnt` is treated as a document, and other formats are always added as embedded images.
- **Resource deduplication is unclear**: If the same image is dropped twice onto the canvas, it is not obvious from the `ResourceManager` API whether it deduplicates the binary blob or stores two copies.

## Decision Guidance
Keep the `.infpnt` format as the primary format — the self-contained binary design is appropriate for the collaborative use case. Wire up the existing `autosave_to_directory()` method to a user-configurable timer before any production release, as data loss from a crash is the highest-severity user experience failure. Consider a JSON or ZIP-based format as a secondary export option for interoperability.

## Related Features
- [OnlineCollaboration.md](OnlineCollaboration.md) — hosted sessions use the same serialization path as file save
- [UndoRedo.md](UndoRedo.md) — the undo stack is not persisted to file
- [LayerManagement.md](LayerManagement.md) — layer tree is a top-level section of the saved archive
- [Bookmarks.md](Bookmarks.md) — bookmarks are serialized into the file
