# Distraction-Free Mode

## What It Does
Toggles all UI panels (toolbar, menubar, statusbar) on and off with a single keystroke, leaving only the canvas visible. Intended for focused drawing sessions where the interface chrome is not needed.

## How to Use It
- Press the `toggle_distraction_free_mode` keybinding (default: **Tab**) to hide/show UI
- The toolbar, menubar (including the tab bar), and statusbar all hide simultaneously
- Press the same key again to restore the UI
- Toggling does not affect canvas interaction — drawing and all shortcuts continue to work while in distraction-free mode

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| Main | `lorien/Main.gd` | 217–223 | `_toggle_distraction_free_mode()` — sets visibility on all 3 panels |
| Main | `lorien/Main.gd` | 163–164 | Input handler that triggers toggle |

## Architecture Notes
`_toggle_distraction_free_mode` flips a boolean `_ui_visible` and sets `.visible` on four nodes:
- `_menubar.get_parent()` (the parent container of the menubar)
- `_menubar` itself
- `_statusbar`
- `_toolbar`

Both the parent container and the menubar node are toggled to handle the layout correctly — hiding only the menubar without its container would leave an empty gap.

The implementation is 6 lines. It does not persist — UI is always visible after a fresh launch.

## Pros
- Dead simple implementation with no state to manage beyond a single boolean
- Effective: all three UI panels disappear cleanly, leaving a full-canvas view
- Drawing shortcuts (Ctrl+Z, tool keys, etc.) continue to work in distraction-free mode

## Cons / Limitations
- **Not persisted**: if you quit in distraction-free mode, the UI is back on next launch
- **No visual hint** that distraction-free mode is active: there is no persistent indicator to remind the user how to exit the mode (easy to forget if using the app infrequently)
- **Cannot selectively hide panels**: it's all-or-nothing — no way to hide just the statusbar or just the toolbar
- The menubar parent and menubar itself are both toggled separately, which is a fragile dependency on the scene tree structure — if the hierarchy changes, only one will toggle

## Decision Guidance
This is a minimal but functional feature. The only meaningful improvement would be persisting the state across launches. The "how do I get my UI back" discoverability problem is worth addressing with a brief tooltip or a small floating hint that appears when entering distraction-free mode.
