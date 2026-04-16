# Settings & Preferences

## What It Does
A persistent settings system covering four categories: General (brush defaults, project directory, pressure sensitivity, language), Appearance (theme, UI scale, canvas color, grid), Rendering (anti-aliasing, brush rounding, foreground/background FPS), and Keybindings (remappable shortcuts for every action). Settings survive app restarts and are stored in a plain-text config file.

## How to Use It
- **Main Menu > Settings** to open the settings dialog
- Changes take effect immediately for most settings
- Some settings (theme, anti-aliasing, brush rounding) require a restart — a "restart required" label appears in the dialog
- **Keybindings tab**: click a binding slot to record a new key combination; a "+" button adds additional bindings per action
- Settings are saved to `user://settings.cfg` automatically on every change

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| Settings | `lorien/Misc/Settings.gd` | 1–111 | Autoloaded node; all get/set of settings keys; shortcut load/save |
| SettingsDialog | `lorien/UI/Dialogs/SettingsDialog.gd` | 1–253 | Full dialog UI with 4 tabs |
| Config | `lorien/Config.gd` | 1–28 | All default values and file paths as constants |
| KeyBindingsList | `lorien/UI/Components/KeyBindingsList.gd` | — | Renders the keybinding table |
| KeyBindingsLineBindings | `lorien/UI/Components/KeyBindingsLineBindings.gd` | — | Per-action binding display and edit |
| AddKeyDialog | `lorien/UI/Dialogs/AddKeyDialog.gd` | — | Records a new key press for a binding |

## Architecture Notes
`Settings` is an autoloaded singleton backed by Godot's `ConfigFile` (an INI-style file). All reads go through `Settings.get_value(key, default)` and all writes through `Settings.set_value(key, value)` — the file is written to disk on every `set_value` call (no batching).

**Available settings keys** (all defined as constants in `Settings.gd`):
| Key | Default | Notes |
|-----|---------|-------|
| `general_pressure_sensitivity` | 1.5 | Multiplier applied after pressure curve |
| `general_default_brush_size` | 12 | Pixels |
| `general_default_project_dir` | OS docs folder | File dialogs start here |
| `general_language` | "en" | Locale code |
| `appearance_theme` | DARK | Requires restart |
| `appearance_ui_scale_mode` | AUTO | AUTO or CUSTOM |
| `appearance_ui_scale` | 1.0 | Only used when mode is CUSTOM |
| `appearance_grid_pattern` | DOTS | DOTS, LINES, or NONE |
| `appearance_grid_size` | 25 | Pixels between grid elements |
| `appearance_canvas_color` | #202124 | Background color |
| `rendering_aa_mode` | TEXTURE_FILL | Requires restart |
| `rendering_foreground_fps` | 144 | Target FPS when focused |
| `rendering_background_fps` | 10 | Target FPS when unfocused |
| `rendering_brush_rounding` | ROUNDED | Requires restart (affects new strokes only) |
| `color_palette_uuid_last_used` | "defaultpalette" | UUID of last active palette |

**UI Scale**: AUTO mode selects scale based on platform — macOS uses `OS.get_screen_scale()`, Windows uses DPI/96, Linux uses a heuristic based on screen resolution (≥192 DPI + ≥1400px → 2×; ≥1700px → 1.5×). CUSTOM mode allows a user-specified float within the range computed from screen resolution.

**Keybindings** are stored in a separate `[shortcuts]` section of the same config file. On startup, `Settings._setup_default_shortcuts` initializes any new action that has no saved binding, removing conflicts with existing bound actions before saving.

## Pros
- Every setting is a named constant — no magic strings scattered through the codebase; easy to find all usages
- All default values are centralized in `Config.gd` — one file to review to understand the baseline behavior
- The keybinding system is full-featured: multiple bindings per action, a dedicated dialog for key capture, and persistent storage
- UI scale handles HiDPI correctly across macOS, Windows, and Linux with platform-appropriate detection logic
- FPS throttling when unfocused (default 10 FPS) is a thoughtful performance detail

## Cons / Limitations
- **Settings are written to disk on every individual change** with no debouncing — rapidly dragging a spinbox fires a file write per tick, which is wasteful on slow disks
- Settings that require a restart show a label but do not offer to restart; the user must do it manually and may forget
- `general_default_project_dir` is updated only when the user types a valid directory path, but there's no browse button — users must type the path manually
- No settings export/import: sharing a setup between machines requires manually copying `user://settings.cfg`
- The `_setup_default_shortcuts` logic that de-conflicts new actions against old ones is complex and may silently remove a binding the user intended to keep when a new action is added in an update

## Decision Guidance
Settings are comprehensive and well-organized. The most impactful improvement would be debouncing disk writes (batch them with a small timer). The restart-required settings are a friction point for new users who change the theme and don't realize a restart is needed — adding an automatic restart prompt would eliminate confusion.
