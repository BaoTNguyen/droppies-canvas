---
name: Drawing Tools (Toolbar)
description: All shape/tool types available in the toolbar, tool switching, lasso vs box selection, tool lock, and laser pointer
type: project
---

# Drawing Tools (Toolbar)

## Overview
The toolbar gives users 14 distinct tools for drawing shapes, text, freehand lines, images, and special inputs (eraser, laser pointer). Each tool maps to a keyboard shortcut and most create persistent canvas elements. The toolbar dynamically substitutes the Lasso tool for Selection depending on user preference.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| SHAPES array | `packages/excalidraw/components/shapes.tsx` | 20–133 | Toolbar descriptor array (icon, value, key, numericKey) |
| getToolbarTools() | `packages/excalidraw/components/shapes.tsx` | 119–133 | Dynamically swaps lasso↔selection at index 0 |
| activeTool state | `packages/excalidraw/types.ts` | 336–345 | `{ type, locked, lastActiveTool, fromSelection }` |
| handleCanvasPointerDown | `packages/excalidraw/components/App.tsx` | 7480–7929 | Dispatches to per-tool draw logic on mouse/touch down |
| AnimatedTrail (laser trail) | `packages/excalidraw/animated-trail.ts` | 30–198 | SVG path trail animation via requestAnimationFrame |
| LaserTrails (laser collab) | `packages/excalidraw/laser-trails.ts` | 13–130 | Local + collaborator trails, fade-out decay curves |
| LassoTrail | `packages/excalidraw/lasso/index.ts` | 1–220 | Freehand polygon selection with real-time element hit testing |
| getLassoSelectedElementIds | `packages/excalidraw/lasso/utils.ts` | 22–90 | AABB → enclosure → intersection tests for lasso |
| toggleLock | `packages/excalidraw/components/App.tsx` | 4218–4242 | Tool lock toggle — keeps active tool after drawing |

## How It Works

1. **Tool selection:** The user clicks a toolbar button or presses a key shortcut. `findShapeByKey()` (shapes.tsx:135) maps the key to a `ToolType`. `updateActiveTool()` writes the new tool to `appState.activeTool`.

2. **Drawing dispatch:** On `pointerdown`, `handleCanvasPointerDown` (App.tsx:7480) reads `activeTool.type` and dispatches:
   - `"lasso"` → `this.lassoTrail.startPath(x, y)` (line 7755)
   - `"text"` → `handleTextOnPointerDown()` (line 7859)
   - `"freedraw"` → `handleFreeDrawElementOnPointerDown()` (line 7870)
   - `"frame"` / `"magicframe"` → `createFrameElementOnPointerDown()` (line 7882)
   - `"laser"` → `this.laserTrails.startPath(x, y)` (line 7887)
   - All other shapes → `createGenericElementOnPointerDown()` (line 7896)

3. **Tool lock:** `activeTool.locked` (default false). When false, any completed draw reverts the tool to `preferredSelectionTool.type`. When true, the tool stays active. Toggled by `toggleLock()` (App.tsx:4218) via the lock button or keyboard shortcut `Q`.

4. **Laser pointer:** `AnimatedTrail` renders an SVG `<path>` into the canvas overlay. Fade-out uses dual decay curves (time: 1000ms, length: 50 points) processed with `easeOut`. Collaborator laser trails are tracked per `SocketId` in a `Map` inside `LaserTrails`.

5. **Lasso selection:** `LassoTrail` extends `AnimatedTrail` (purple color, `rgba(105,101,219)`). Every `addPointToPath` call triggers `updateSelection()` which runs `getLassoSelectedElementIds()`: AABB fast-reject → polygon enclosure test → line segment intersection test. Selection updates live as the user draws.

## Dependencies
- `@excalidraw/laser-pointer` npm package (trail point computation)
- `points-on-curve` npm package (lasso path simplification)
- `appState.preferredSelectionTool` (lasso vs box mode persistence)
- `appState.activeTool.locked` (tool lock flag)

## Pros
- **Full keyboard coverage:** Every tool has a shortcut (H, V, R, D, O, A, L, P, T, 9, E, 0, F, K), reducing mouse travel significantly.
- **Lasso selection is genuinely useful:** Real-time polygon selection with AABB + enclosure + intersection tests makes selecting irregular groups natural.
- **Laser pointer is polished:** Dual decay curves (time + length) with `easeOut` give a satisfying visual trail; collaborator trails are per-socket so multi-user laser is supported.
- **Tool lock covers power users:** Holding the same tool indefinitely is useful for batch drawing workflows.
- **Laser works in view mode:** Uniquely, the laser tool bypasses the `viewModeEnabled` block (App.tsx:7929), so presenters can annotate in read-only mode.

## Cons
- **Laser pointer is hidden from the default toolbar:** `toolbar: false` in shapes.tsx:92 — it only appears when collaboration is active. Solo users never discover it.
- **Lasso is not in SHAPES by default:** It replaces selection only if `preferredSelectionTool.type === "lasso"`, but there is no obvious UI affordance to set this preference.
- **No multi-tool drawing:** You can only use one tool at a time; no simultaneous shape+text layering.
- **Freedraw roughness is always on:** Freedraw uses roughjs and inherits the `roughness` setting — there is no "smooth freehand" mode.
- **Laser trail performance:** `requestAnimationFrame` redraws every frame even when the trail is fading. No pause mechanism when no collaborators are active.

## Notes
- `App.tsx:7128` — `HACK: Disable transform handles for linear elements on mobile` — resize UX for lines/arrows on mobile is intentionally crippled.
- `DECAY_TIME = 1000 ms`, `DECAY_LENGTH = 50 points` are hardcoded in `laser-trails.ts:33–48` — no user setting.
- The `"laser"` tool type exists in `ToolType` alongside all other tools, but `SHAPES` marks it `toolbar: false` — so it is a first-class tool type with a second-class UI presence.
