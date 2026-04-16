---
name: Frames
description: Named grouping frames, frame clipping, wrap selection in frame, Magic Frame for AI generation, frame rendering controls
type: project
---

# Frames

## Overview
Frames are named rectangular containers that visually group elements. They can clip their contents, display a name label, and be exported independently. Magic Frames are a special variant that trigger AI-powered diagram-to-code generation. Frames are first-class elements but have notable limitations around align/distribute.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| frame.ts | `packages/element/src/frame.ts` | full file | Frame membership, containment, clipping helpers |
| getFrameChildren | `packages/element/src/frame.ts` | 234 | Returns all elements with `frameId === id` |
| getElementsCompletelyInFrame | `packages/element/src/frame.ts` | 86 | Elements fully within frame bounds |
| elementOverlapsWithFrame | `packages/element/src/frame.ts` | 140 | OR of inside/intersecting/containing |
| getRootElements | `packages/element/src/frame.ts` | 263 | Frames + non-frame-children (for group/z-index ops) |
| frameClip | `packages/excalidraw/renderer/staticScene.ts` | 132–156 | Canvas 2D clip path from frame bounds |
| Frame clip application | `packages/excalidraw/renderer/staticScene.ts` | 321–334 | Per-element clip when `frameRendering.clip` is on |
| actionWrapSelectionInFrame | `packages/excalidraw/actions/actionFrame.ts` | 163–219 | Creates frame around selection with 16px padding |
| actionSelectAllElementsInFrame | `packages/excalidraw/actions/actionFrame.ts` | 40 | Selects all frame children |
| actionRemoveAllElementsFromFrame | `packages/excalidraw/actions/actionFrame.ts` | 77 | Removes all children from selected frame |
| MagicGenerationData type | `packages/element/src/types.ts` | 105–114 | `{ status: "pending" \| "done" \| "error"; html? }` |
| onMagicFrameGenerate | `packages/excalidraw/components/App.tsx` | 2512 | Calls `plugins.diagramToCode.generate()` |
| magicGenerations Map | `packages/excalidraw/components/App.tsx` | 2467–2468 | In-memory cache of pending/done generation states |
| updateMagicGeneration | `packages/excalidraw/components/App.tsx` | 2470–2500 | Updates element customData + in-memory map |
| actionAlign TODO | `packages/excalidraw/actions/actionAlign.tsx` | 51 | Frames excluded from align — known limitation |
| actionDistribute TODO | `packages/excalidraw/actions/actionDistribute.tsx` | 43 | Frames excluded from distribute — known limitation |

## How It Works

### Frame Creation & Membership
When elements are dragged into a frame's bounds, `getElementsCompletelyInFrame()` (frame.ts:86) and `elementOverlapsWithFrame()` (line 140) determine membership. Each child element carries `frameId: string | null` pointing to its frame. Frame membership is updated via `addElementsToFrame()` and `removeElementsFromFrame()` after any operation that might change containment.

### Wrap Selection in Frame
`actionWrapSelectionInFrame` (actionFrame.ts:163): computes `getCommonBounds(selectedElements)` + `PADDING = 16` on all sides → creates a `newFrameElement()` at those bounds. If elements belong to a group, they are removed from the group. `addElementsToFrame()` sets `frameId` on all selected elements. Selection is then set to just the new frame.

### Frame Clipping
`frameClip()` (staticScene.ts:132): translates the canvas context to the frame's scroll-adjusted position, creates a clip path using `context.roundRect()` (with `FRAME_STYLE.radius / zoom` for DPI-independent corners) or falls back to `context.rect()`, then calls `context.clip()`. All elements with matching `frameId` and `appState.frameRendering.clip === true` are rendered inside a `context.save()/restore()` wrapping this clip. New elements being drawn inside a frame are also clipped (`renderNewElementScene.ts:58–66`). SVG export uses `<clipPath>` in `staticSvgScene.ts:73`.

### Magic Frame / AI Generation
`ExcalidrawMagicFrameElement` is a separate element type (`type: "magicframe"`) with a `name` field. When a Magic Frame is "generated," the system:
1. Calls `onMagicFrameGenerate(magicFrame)` (App.tsx:2512) → `plugins.diagramToCode.generate()`
2. The plugin collects elements overlapping the frame as visual context
3. Sends to the AI backend; receives `{ html }` response
4. Stores result in `MagicGenerationData` on the linked `ExcalidrawIframeElement.customData.generationData`

States: `"pending"` (in-memory only, not persisted), `"done"` (html stored on element), `"error"` (with message/code). Pending state is never written to the element — only done/error are persisted.

Auto-wrap: if the user selects elements and activates the D2C tool without a Magic Frame, App.tsx:2627–2674 automatically wraps them in a `newMagicFrameElement()` with 50px padding.

### Frame Rendering Controls
`appState.frameRendering` object controls:
- `enabled`: whether frames render at all
- `clip`: whether contents are clipped to frame bounds
- `name`: whether the name label is shown
- `outline`: whether the frame border is drawn

## Dependencies
- `appState.frameRendering` (rendering flags)
- `plugins.diagramToCode` (Magic Frame AI generation, optional — plugin architecture)
- `VITE_APP_AI_BACKEND` (environment variable for AI backend URL)
- `context.roundRect()` (frame clip — polyfill needed in older browsers)

## Pros
- **Frames enable subset export:** Any frame's contents can be exported independently as PNG/SVG — critical for multi-diagram documents.
- **Clipping is visually clean:** Canvas 2D clip paths with rounded corners produce clean frame bounds without additional CSS.
- **Magic Frame is a plugin extension point:** The `plugins.diagramToCode` API means any AI backend can be connected — not hardcoded to a specific service.
- **Wrap selection in frame is one action:** `actionWrapSelectionInFrame` handles bounds calculation, padding, and element re-parenting automatically.
- **Frame name labels and outline are independently toggleable:** Different visual density for different use cases (presentation vs. working canvas).

## Cons
- **Align and distribute are fully disabled for frames:** Both `actionAlign` and `actionDistribute` refuse to run if any frame is in the selection (TODOs at actionAlign.tsx:51 and actionDistribute.tsx:43). This is a serious limitation for positioning frames programmatically.
- **Magic Frame generation state is lost on reload:** Pending generation state is in-memory only (App.tsx:2467). If the page reloads mid-generation, the pending state is lost with no recovery UI.
- **Frame elements cannot contain bound text:** `ExcalidrawTextContainer` does not include frame types — text cannot be embedded in a frame like it can in a rectangle.
- **No nested frames:** A frame's `frameId` field references another frame's ID — the code does not support nested frame hierarchies.
- **`element/src/types.ts:119` TODO:** `// TODO move later to AI-specific frame` — `generationData` is stored on `ExcalidrawIframeElement.customData` as a temporary placement, not on the magicframe element itself.
- **Frame membership is not enforced on z-index operations:** Moving a frame forward/backward does not automatically move its children, potentially breaking visual stacking.

## Notes
- `getElementsCompletelyInFrame()` explicitly excludes elements that already belong to a different frame — elements can only be in one frame at a time.
- `getRootElements()` (frame.ts:263) is used extensively in group and z-index operations to prevent treating frame children as independent elements.
- Frame clipping in SVG export uses `<clipPath>` elements, which are supported in all modern SVG viewers — no compatibility issue.
