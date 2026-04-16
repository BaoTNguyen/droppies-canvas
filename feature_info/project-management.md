# Project Management

## What It Does
Each canvas workspace is a "project" stored as a single `.lorien` binary file. The app supports multiple projects open simultaneously as tabs. Users can create new projects, open existing ones (via dialog, drag-and-drop, or CLI argument), save, save-as, and close projects. Unsaved-changes protection prompts before closing or quitting.

## How to Use It
- **Ctrl+N** to create a new (unsaved) project tab
- **Ctrl+O** or the open button to open a `.lorien` file via file dialog
- **Drag and drop** a `.lorien` file onto the window to open it
- **Pass a `.lorien` path as a CLI argument** to open it on launch
- **Ctrl+S** to save; prompts for a file path if unsaved
- **Main Menu > Save As** to save to a new path
- Click a tab to switch between open projects
- Click the **×** on a tab to close it; prompts to save if dirty
- Closing the last tab creates a new blank project automatically
- The menubar tab title shows `(*)` next to the name when a project has unsaved changes

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| ProjectManager | `lorien/ProjectManager/ProjectManager.gd` | 1–113 | In-memory registry: add, remove, activate, save, load projects |
| Project | `lorien/ProjectManager/Project.gd` | — | Data class: id, filepath, dirty flag, loaded flag, strokes array, undo_redo |
| Serializer | `lorien/ProjectManager/Serializer.gd` | 1–144 | Binary read/write of `.lorien` files (DEFLATE compressed) |
| ProjectMetadata | `lorien/ProjectManager/ProjectMetadata.gd` | 1–28 | Camera zoom/offset stored in file header metadata |
| Menubar | `lorien/UI/Menubar.gd` | 1–90 | Tab bar UI: create, activate, update, remove tabs |
| Main | `lorien/Main.gd` | 261–455 | Orchestrates open/save/close flows and dialog prompts |
| StatePersistence | `lorien/Misc/StatePersistence.gd` | 1–46 | Persists open project paths and active project across sessions |

## Architecture Notes
**File format** (`.lorien`, DEFLATE-compressed binary):
1. `uint32` — version number (currently `1`)
2. Pascal string — metadata (key=value CSV pairs: camera_zoom, camera_offset_x/y)
3. Repeated stroke records:
   - `uint8` type (`0` = brush stroke)
   - `uint8 r, g, b` — color (no alpha stored)
   - `uint16` — brush size
   - `uint16` — point count
   - `[float x, float y, uint8 pressure]` × point count

The format has a deprecated `TYPE_ERASER_STROKE_DEPRECATED = 1` entry that is silently skipped on load, preserving backward compatibility.

**Multi-project state**: `ProjectManager` keeps an array of `Project` objects. Projects are loaded lazily — the file is read only when the project is first made active (`make_project_active` calls `_load_project` if `project.loaded == false`). New/unsaved projects are considered loaded by definition. This lazy strategy means a user can open many file tabs without reading all their data upfront.

**Unsaved changes tracking**: The `dirty` flag is set on `Project` whenever strokes are added/removed or the camera moves. It is cleared on `save_project`. The tab title updates on every frame via `_process` (`update_tab_title`).

**Session restore**: On quit, `StatePersistence` writes the list of open project file paths and the active project path to `user://state.cfg`. On next launch, these are re-opened in order.

## Pros
- Lazy loading is a smart design: opening 10 tabs doesn't read 10 files — only the currently active one is parsed
- DEFLATE compression on the binary format gives compact files for typical canvas data
- Drag-and-drop and CLI argument opening are both implemented — power-user workflows are supported
- The `(*)` dirty indicator updates every frame reliably, so the user always knows what's unsaved
- Session restore opens all previously-open projects and reactivates the last active one — the app returns exactly to where you left off

## Cons / Limitations
- **No autosave**: there is a `_show_autosave_not_implemented_alert` function that explicitly notifies the user autosave is missing. An unsaved project can be lost if the app crashes
- **No file validation on load**: the `Serializer` has three consecutive `TODO: !IMPORTANT! all of this needs validation` comments — a corrupted or malformed file will crash or produce undefined behavior rather than a clean error message
- **Alpha is not stored**: stroke colors are saved as 3-byte RGB; transparent strokes are not supported
- **No backup/versioning**: saving overwrites the file in place with no backup copy or version history
- **File format version is `1` and never incremented**: there is no migration path if the format changes in a future version
- The `save_all_projects()` method skips projects that have no filepath — so if you have an unsaved new project with changes, quitting with "save all" silently skips it

## Decision Guidance
The project management core is solid, but the lack of autosave and file validation are real risks. The validation gap is the more urgent one — a corrupt file currently crashes the app instead of showing an error. For a production tool, these two gaps (autosave + load validation) should be addressed before shipping to users who rely on data integrity.
