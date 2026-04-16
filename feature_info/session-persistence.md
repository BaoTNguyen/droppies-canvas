# Session Persistence

## What It Does
Automatically saves and restores the application state between launches. On quit, it records which project files were open, which was active, and the window size/maximized state. On the next launch, all those projects are reopened and the previously active one is focused.

## How to Use It
This feature is entirely automatic — there is no user-facing toggle or configuration. Simply close and reopen the app; the workspace is restored.

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| StatePersistence | `lorien/Misc/StatePersistence.gd` | 1–46 | Reads/writes `user://state.cfg` |
| Main | `lorien/Main.gd` | 175–214 | `_save_state()` on quit, `_apply_state()` on startup |
| Config | `lorien/Config.gd` | 10 | `STATE_PATH := "user://state.cfg"` |

## Architecture Notes
`StatePersistence` is an autoloaded `Node` backed by a `ConfigFile` at `user://state.cfg`. It stores:

| Key | Type | Content |
|-----|------|---------|
| `open_projects` | Array of Strings | File paths of all open projects |
| `active_project` | String | File path of the active project |
| `window_size` | Vector2 | Window dimensions in pixels |
| `window_maximized` | bool | Whether the window was maximized |

`_save_state()` is called in `_notification(NOTIFICATION_WM_QUIT_REQUEST)` just before `get_tree().quit()`. A 0.12 second timer yield is inserted before quitting to ensure the file write completes before the process exits.

`_apply_state()` is called at the end of `_ready()`. It uses a 0.12 second yield before opening projects (to allow the window to finish initializing). Projects are opened by calling `_on_open_project(path)` for each saved path. If a saved path no longer exists on disk, `_on_open_project` returns `false` silently.

## Pros
- Completely automatic — no user action required
- Window size and maximized state are restored, so the app reopens at the right size
- Missing files are silently skipped rather than causing errors
- The 0.12 second yield before quit is a pragmatic workaround for the write-timing issue

## Cons / Limitations
- **No restore of unsaved (new) projects**: only projects with a file path are saved. An unsaved project tab is lost on quit — the state restore only opens files that exist on disk
- **No camera position/zoom is saved at session level**: camera state is per-project and stored in the project file itself, but only saved when the project is explicitly saved. If you close the app without saving, the camera position for dirty projects is not persisted in the state file
- **Silent missing-file handling**: if a project file has been moved or deleted, it is silently skipped. There is no notification to the user that files from the previous session could not be found
- The 0.12 second delay before quitting is a timing hack — on very slow disks this may be insufficient; on fast disks it is unnecessary overhead
- `StatePersistence` writes to disk on every `set_value` call (same as `Settings`), with no debouncing

## Decision Guidance
Session restore is a valuable quality-of-life feature and it works correctly for saved projects. The main gap is the loss of unsaved new projects on quit — the exit dialog could be extended to warn about unsaved tabs that have no file path. The silent missing-file behavior is also worth revisiting: a notification would help users understand why their expected project didn't reopen.
