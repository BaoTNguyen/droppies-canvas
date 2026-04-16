# Platformer Easter Egg

## What It Does
A hidden feature that spawns a small pixel-art character on the canvas who is subject to gravity and can walk, jump, and crouch. The character uses the drawn strokes as physical platforms — every visible stroke becomes a collision surface. Intended as a fun surprise, not a serious feature.

## How to Use It
- Press the `toggle_player` keybinding (undocumented by design — check the InputMap or source code)
- A character appears at the current cursor position
- Move with **A/D**, jump with **Space**, crouch with **S**
- Press the toggle key again to remove the player and return to normal drawing mode
- Works best with strokes that form horizontal surfaces

## Code Location
| Component | File Path | Key Lines | Role |
|-----------|-----------|-----------|------|
| Player | `lorien/Misc/Player/Player.gd` | 1–43 | `KinematicBody2D` with physics: walk, jump, crouch, gravity |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 139–155 | `enable_player()` — adds/removes player from scene tree |
| InfiniteCanvas | `lorien/InfiniteCanvas/InfiniteCanvas.gd` | 139–143 | `enable_colliders()` — adds `StaticBody2D` collision to all strokes |
| BrushStroke | `lorien/BrushStroke/BrushStroke.gd` | 67–87 | `enable_collider()` — builds segment-by-segment `StaticBody2D` per stroke |
| Main | `lorien/Main.gd` | 169–172 | `_toggle_player()` — calls both `enable_colliders` and `enable_player` |

## Architecture Notes
When the player is enabled, `enable_colliders(true)` iterates every stroke in `_strokes_parent` and calls `stroke.enable_collider(true)`. This creates a `StaticBody2D` child on each stroke containing one `CollisionShape2D` per consecutive point pair — each with a `SegmentShape2D`. For a stroke with N points, N-1 segment colliders are created.

The player is a `KinematicBody2D` using `move_and_slide` with `Vector2.UP` as the floor normal. It has two `CollisionShape2D` children — one for standing, one for crouching — and an `AnimatedSprite` with idle, walk, jump, and crouch animations. Speed is 400, jump power is 1,000, gravity accumulates at 60 units per frame.

When player mode is disabled, `enable_colliders(false)` calls `enable_collider(false)` on every stroke, which finds and frees the `StaticBody2D` child. The player node is removed from the viewport. Drawing mode resumes normally.

New strokes drawn while player mode is active have their collider enabled immediately via the `if _colliders_enabled` check in `InfiniteCanvas.end_stroke`.

## Pros
- Genuinely charming easter egg — the character correctly walks on drawn strokes including curves and diagonal lines
- The collision system is dynamically built from actual stroke geometry — no approximation; the player stands exactly on stroke surfaces
- New strokes drawn in player mode immediately become platforms
- Toggling cleanly tears down all colliders, leaving no performance cost when the mode is off

## Cons / Limitations
- **Serious performance risk on large canvases**: enabling colliders on a canvas with thousands of strokes creates thousands of `StaticBody2D` nodes and potentially tens of thousands of `SegmentShape2D` colliders — this can stall the main thread for several seconds or crash on memory
- The player and drawing tool share the **S** key (select tool / crouch) — while the drawing tool is disabled during player mode, the binding conflict is confusing
- No documentation or in-app hint about the easter egg (by design, but still)
- The `_toggle_player` is also called when `_player_enabled` is false but a dialog is open — the `is_dialog_open()` check in `_unhandled_input` does not gate this specific action

## Decision Guidance
This is a fun hidden feature worth keeping as-is for its charm. It should not be promoted as a serious feature. The performance risk on large canvases is real — adding a stroke count guard (e.g., refuse to enable if > 500 strokes) would prevent accidental freezes without diminishing the experience for the intended use case.
