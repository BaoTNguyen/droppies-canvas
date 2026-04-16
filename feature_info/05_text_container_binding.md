---
name: Text & Container Binding
description: WYSIWYG inline text editor, text bound to shapes and arrows, auto-resize, wrap, vertical/horizontal alignment
type: project
---

# Text & Container Binding

## Overview
Text elements can be created standalone or bound inside container shapes (rectangles, diamonds, ellipses, arrows). Bound text wraps to fit the container, auto-resizes the container when text overflows, and repositions itself when the container is moved or resized. A WYSIWYG `<textarea>` overlay handles in-canvas editing.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| ExcalidrawTextContainer types | `packages/element/src/types.ts` | 270–274 | Union: rectangle \| diamond \| ellipse \| arrow |
| redrawTextBoundingBox | `packages/element/src/textElement.ts` | 46–140 | Main layout fn: wrap, measure, resize container |
| handleBindTextResize | `packages/element/src/textElement.ts` | 142–220 | Re-wrap on container resize handle drag |
| computeBoundTextPosition | `packages/element/src/textElement.ts` | 222–278 | Positions text inside container with V+H alignment |
| getBoundTextElement | `packages/element/src/textElement.ts` | 286–299 | Looks up bound text element by ID |
| App.startTextEditing | `packages/excalidraw/components/App.tsx` | 6137 | Entry point: find/create text element, open WYSIWYG |
| textWysiwyg | `packages/excalidraw/wysiwyg/textWysiwyg.tsx` | 426 | Creates `<textarea>` overlay for in-canvas editing |
| actionTextAutoResize | `packages/excalidraw/actions/actionTextAutoResize.ts` | full file | Resets `autoResize` flag to true on selected text |
| autoResize flag | `packages/element/src/types.ts` | ~ExcalidrawTextElement | `autoResize: boolean` — width-lock toggle |

## How It Works

1. **Text creation:** Double-clicking a shape activates `startTextEditing()` (App.tsx:6137), which either finds the existing bound text element via `getBoundTextElement()` or creates a new `ExcalidrawTextElement` with `containerId` set. Double-clicking empty canvas creates a standalone text element.

2. **WYSIWYG editor:** `textWysiwyg()` (wysiwyg/textWysiwyg.tsx:426) creates a `document.createElement("textarea")` positioned absolutely over the canvas at the element's screen coordinates. It mirrors font, size, color, and alignment to visually match the final element. Escape or click-outside commits the text; Escape without changes deletes an empty text element.

3. **Layout on text change:** `redrawTextBoundingBox(textElement, container, scene)` (textElement.ts:46):
   - If `container` exists: calls `getBoundTextMaxWidth(container, textElement)` → `wrapText(originalText, fontString, maxWidth)`
   - Measures via `measureText()` → computes needed `width`, `height`
   - If text exceeds container height/width, the container auto-expands
   - Calls `computeBoundTextPosition()` to place text using `verticalAlign` (top/center/bottom) and `textAlign` (left/center/right)
   - For arrows, delegates positioning to `LinearElementEditor.getBoundTextElementPosition()`

4. **Auto-resize:** When `textElement.autoResize === true`, `redrawTextBoundingBox` sets `boundTextUpdates.width = metrics.width` — the element width tracks the text. When `false` (manually resized), width is locked and text wraps to that fixed width. Container-bound text always has `autoResize = true`.

5. **Container resize:** `handleBindTextResize()` (textElement.ts:142) is called when the user drags a resize handle on a container. It re-wraps text and potentially grows the container vertically to accommodate it.

## Dependencies
- `appState.editingTextElement` (tracks which text element is being edited)
- `wrapText()` from text measurement utilities
- `measureText()` for font metrics
- `LinearElementEditor.getBoundTextElementPosition()` for arrow labels

## Pros
- **Four container types:** Rectangles, diamonds, ellipses, and arrows all support bound text — covers the majority of diagramming use cases.
- **Vertical alignment options:** Top/center/bottom — uncommon in canvas tools.
- **Container auto-expands:** Text never clips out of sight — the container grows to fit, which is the expected behavior for note-taking shapes.
- **WYSIWYG positioning:** The `<textarea>` overlay is positioned and styled to match the final render, so you see exactly what you get while typing.
- **auto-resize toggle:** Users can fix a text width (for manual wrapping) or let it grow freely — a genuine layout control.

## Cons
- **Frames cannot contain bound text:** `ExcalidrawTextContainer` explicitly excludes frame elements — text cannot be embedded in a frame the same way it can in a rectangle. This is a notable gap for frame-as-card workflows.
- **Arrow text labels use a separate positioning path:** `LinearElementEditor.getBoundTextElementPosition()` handles arrow labels differently from shape containers — inconsistency can surface as visual positioning bugs.
- **No rich text / markdown:** Text is plain Unicode only. No bold, italic, bullet lists, or code blocks inside a text element.
- **No table or grid text layout:** Multi-column text is not supported; each text element is a single flow.
- **Auto-resize has no minimum size:** A single-character text element can shrink its container to near-zero dimensions.
- **`App.tsx:3736` TODO:** `// TODO: remove formatting from elements if isPlainPaste` — pasting from another element does not strip element-level formatting, which can produce unexpected style inheritance.

## Notes
- The `autoResize` action (`actionTextAutoResize`) is available as a button in the Properties panel only when a text element with `autoResize: false` is selected.
- `containerId` on a text element and `boundElements: [{ type: "text", id }]` on the container form a bidirectional reference — both must be kept in sync during copy/paste and deletion.
