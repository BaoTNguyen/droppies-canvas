# Keyboard Shortcuts

## What It Does
All major actions are bound to keyboard shortcuts, and every shortcut is remappable through the Settings dialog. Multiple bindings per action are supported. Bindings are persisted in `user://settings.cfg`.

## How to Use It
- **Settings > Keybindings tab** to view and edit all bindings
- Click any binding entry and press a new key to rebind it
- Click the **+** button on an action to add a secondary binding
- Changes take effect immediately without restart

## Default Shortcuts

| Action | Default Key | Description |
|--------|------------|-------------|
| `shortcut_new_project` | Ctrl+N | Create new project |
| `shortcut_open_project` | Ctrl+O | Open project file |
| `shortcut_save_project` | Ctrl+S | Save current project |
| `shortcut_export_project` | Ctrl+E | Export to SVG |
| `shortcut_undo` | Ctrl+Z | Undo last action |
| `shortcut_redo` | Ctrl+Y | Redo last undone action |
| `shortcut_brush_tool` | B | Switch to brush tool |
| `shortcut_rectangle_tool` | R | Switch to rectangle tool |
| `shortcut_circle_tool` | C | Switch to circle/ellipse tool |
| `shortcut_line_tool` | L | Switch to line tool |
| `shortcut_eraser_tool` | E | Switch to eraser tool |
| `shortcut_select_tool` | S | Switch to selection tool |
| `toggle_distraction_free_mode` | Tab | Toggle UI visibility |
| `toggle_fullscreen` | F11 | Toggle fullscreen |
| `center_canvas_to_mouse` | H | Center view on cursor |
| `canvas_zoom_in` | + | Zoom in |
| `canvas_zoom_out` | - | Zoom out |
| `canvas_pan_left/right/up/down` | Arrow keys | Pan canvas |
| `duplicate_strokes` | Ctrl+D | Duplicate selected strokes |
| `copy_strokes` | Ctrl+C | Copy selected strokes |
| `paste_strokes` | Ctrl+V | Paste strokes |
| `delete_selected_strokes` | Delete | Delete selected strokes |
| `deselect_all_strokes` | Escape | Deselect all |
| `toggle_player` | (see code) | Toggle platformer easter egg |
| `player_move_left/right` | A/D | Player movement |
| `player_jump` | Space | Player jump |
| `player_crouch` | S | Player crouch |

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| Settings | `lorien/Misc/Settings.gd` | 73–111 | Load/save shortcuts to/from ConfigFile; de-conflict new actions |
| KeyBindingsList | `lorien/UI/Components/KeyBindingsList.gd` | — | Renders the binding table in the settings dialog |
| KeyBindingsLineBindings | `lorien/UI/Components/KeyBindingsLineBindings.gd` | — | Editable row for one action's bindings |
| AddKeyDialog | `lorien/UI/Dialogs/AddKeyDialog.gd` | — | Modal that captures a single key press |
| Utils | `lorien/Misc/Utils.gd` | — | `bindable_actions()` — returns the list of all rebindable action names |
| Main | `lorien/Main.gd` | 131–166 | `_unhandled_input` — routes shortcut events to handlers |
| I18nParser | `lorien/Misc/I18nParser.gd` | 76–90 | `_i18n_filter_shortcut_list` — injects shortcut hints into translation strings |

## Architecture Notes
Shortcuts use Godot's `InputMap` system. `Settings._load_shortcuts` replaces the default `InputMap` event list for each action with the saved binding list from the config file. `Settings.store_shortcuts` writes the current `InputMap` state back to the config.

`_setup_default_shortcuts` runs on startup for any action that has no saved binding. It de-conflicts new actions against already-bound actions: if a new action would share a key with an existing bound action, that key is removed from the new action's defaults. This prevents silent collisions when new shortcuts are added in updates.

Translation strings can embed current shortcut labels using the `{shortcut_list:action_name}` template syntax (processed by `I18nParser`). This means help text in the UI always shows the current binding, not a hardcoded string.

## Pros
- Every action is remappable — no hardcoded shortcuts in the input handling code
- Multiple bindings per action is supported, so users can have both Ctrl+Z and a gamepad button for undo simultaneously
- Shortcut labels are embedded in translation strings dynamically, so localized help text always reflects the current keybindings
- De-conflicting on new action addition prevents silent binding collisions after app updates

## Cons / Limitations
- **Tool shortcuts conflict with player movement**: `shortcut_select_tool` defaults to **S**, and `player_crouch` also defaults to **S**. The player mode is a separate mode, but both are registered in the InputMap simultaneously — potential for confusion
- **No conflict detection at edit time**: the UI allows you to bind the same key to multiple actions without warning
- **No "reset to defaults" button** in the keybindings tab: if a user makes a mess of their bindings, they must manually reset each action or delete `user://settings.cfg`
- Shortcut display in toolbar tooltips is not currently implemented — hovering over a toolbar button does not show the associated shortcut key

## Decision Guidance
The keybinding system is solid and more complete than most apps at this scale. The main practical improvement would be conflict detection in the UI — silently allowing duplicate bindings leads to hard-to-debug behavior where only the first matching action fires. A "reset to defaults" button would also reduce support burden.
