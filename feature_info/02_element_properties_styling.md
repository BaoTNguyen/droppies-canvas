---
name: Element Properties & Styling
description: Stroke/fill colors, fill styles, stroke width/style, roughness, opacity, fonts, arrowheads, copy-paste styles, eye-dropper
type: project
---

# Element Properties & Styling

## Overview
Every element on the canvas carries a rich set of visual properties: stroke color, background color, fill pattern, stroke width, stroke style, opacity, roughness, roundness, and (for text) font family/size/alignment. A dedicated eye-dropper can sample any canvas pixel. Styles can be copied from one element and pasted onto others in bulk.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Element style types | `packages/element/src/types.ts` | 19, 28, 42–51 | `FillStyle`, `StrokeStyle`, and per-element style fields |
| generateRoughOptions | `packages/element/src/shape.ts` | 193–264 | Maps element style props → roughjs options |
| Rendering (canvas) | `packages/element/src/renderElement.ts` | 254, 395–433 | Calls `rc.draw(shape)` with roughjs-generated shapes |
| Default element props | `packages/common/src/constants.ts` | 400–416 | `ROUGHNESS`, `STROKE_WIDTH`, `DEFAULT_ELEMENT_PROPS` |
| EyeDropper component | `packages/excalidraw/components/EyeDropper.tsx` | 1–238 | Pixel-pick from canvas via `ctx.getImageData()` |
| activeEyeDropperAtom | `packages/excalidraw/components/EyeDropper.tsx` | 34 | Jotai atom controlling eye-dropper activation state |
| actionCopyStyles | `packages/excalidraw/actions/actionStyles.ts` | 41–71 | Serialize selected element styles to `copiedStyles` string |
| actionPasteStyles | `packages/excalidraw/actions/actionStyles.ts` | 72–173 | Deserialize and apply `copiedStyles` to selected elements |
| COLOR_PALETTE | `packages/common/src/constants.ts` | 196–398 | Full palette definition for color picker swatches |

## How It Works

1. **Style storage:** Every `ExcalidrawElement` carries `strokeColor`, `backgroundColor`, `fillStyle`, `strokeWidth`, `strokeStyle`, `roughness`, `opacity`, `roundness` directly on the element object (element/src/types.ts:42–51).

2. **Rendering pipeline:** `renderElement.ts` creates a roughjs canvas context (`rc = rough.canvas(canvas)`). For shapes, it calls `ShapeCache.generateElementShape(element, renderConfig)` which internally calls `generateRoughOptions()` to translate element props into roughjs parameters:
   - `fillStyle` is passed directly — roughjs handles `"hachure"`, `"cross-hatch"`, `"solid"`, `"zigzag"` natively
   - `hachureGap = element.strokeWidth * 4` (shape.ts:219)
   - `fillWeight = element.strokeWidth / 2` (shape.ts:218)
   - `roughness` is capped via `adjustRoughness()` at 2.5

3. **Eye-dropper:** When activated (`activeEyeDropperAtom` non-null), `EyeDropper.tsx` renders a portal overlay. On `pointermove`, it calls `ctx.getImageData(x * devicePixelRatio, y * devicePixelRatio, 1, 1)` on the main canvas element to read the pixel color, converts to hex via `rgbToHex`, and previews it. On `pointerup`, `onSelect` finalizes the color. Alt key toggles between stroke/fill assignment (`swapPreviewOnAlt`).

4. **Copy/Paste styles:** `actionCopyStyles` (Ctrl+Alt+C) serializes the selected element into the module-level `copiedStyles: string` variable as JSON. `actionPasteStyles` (Ctrl+Alt+V) parses it and applies: `backgroundColor`, `strokeWidth`, `strokeColor`, `strokeStyle`, `fillStyle`, `opacity`, `roughness`, `roundness` for all elements; additionally `fontSize`, `fontFamily`, `textAlign`, `lineHeight` for text; `startArrowhead`/`endArrowhead` for arrows; frames get `roundness: null, backgroundColor: "transparent"`.

## Dependencies
- `roughjs` library for all shape rendering
- `appState.theme` (dark mode filter applied in `generateRoughOptions` via `applyDarkModeFilter`)
- `ShapeCache` (memoizes generated rough shapes per element version)
- `appState.selectedElementIds` (determines which elements receive pasted styles)

## Pros
- **4 fill styles via roughjs:** Hachure, cross-hatch, solid, zigzag give strong visual differentiation without custom rendering code — roughjs handles it.
- **Eye-dropper works on canvas pixels:** Samples any visible canvas content including element fills, backgrounds, and image pixels — not just palette colors.
- **Copy/paste styles is type-aware:** Arrows get arrowheads copied, frames get transparency forced, text gets font properties — avoids nonsensical style transfers.
- **Roughness adds expressiveness:** Three roughness levels (architect=0, artist=1, cartoonist=2) give a spectrum from technical drawing to sketchy whiteboard style.
- **Default props are sensible:** `fillStyle: "solid"`, `strokeWidth: 2`, `roughness: 1` produces clean results out of the box.

## Cons
- **`copiedStyles` is a module-level string (not persistent):** Pasted styles are lost on page reload. There is no "saved style" feature.
- **Eye-dropper is disabled on mobile** (`EyeDropper.tsx:98` — `// TODO reenable on mobile with a better UX`).
- **Only 3 stroke widths (thin/bold/extraBold):** No fine-grained numeric width control; values are 1, 2, and 4.
- **Roughness is element-global:** Cannot mix rough and smooth strokes within one element (e.g. rough outline, smooth fill).
- **No gradient fills or shadows:** The styling system is flat — no CSS-like effects beyond the roughjs primitives.
- **Eye-dropper preview offset bug:** `EyeDropper.tsx:105` has a FIXME noting the preview div offset is not corrected when the eye-dropper goes near viewport edges.

## Notes
- `DEFAULT_ELEMENT_PROPS` (constants.ts:412): new elements default to `fillStyle: "solid"`, not `"hachure"` — changed from the original Excalidraw "sketch" aesthetic toward cleaner defaults.
- The `roundness` type system distinguishes `RoundnessType.LEGACY`, `PROPORTIONAL_RADIUS`, and `FIXED_RADIUS` — older files may have the legacy format which is normalized on load via `restore.ts`.
