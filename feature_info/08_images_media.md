---
name: Images & Media
description: Image insertion (disk/clipboard), image cropping editor, embeddable iframe elements (YouTube, Vimeo, web), supported formats
type: project
---

# Images & Media

## Overview
Images can be inserted from disk or clipboard in 9 formats. An in-canvas crop editor lets users trim images non-destructively. Embeddable elements render live iframes for YouTube, Vimeo, and a curated list of web services. A pluggable `renderEmbeddable` prop allows custom iframe rendering.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| insertImages | `packages/excalidraw/components/App.tsx` | 11796–11856 | Creates placeholder elements, calls initializeImage per file |
| handleAppOnDrop | `packages/excalidraw/components/App.tsx` | 11858–11907 | Drop handler: checks for .excalidraw first, else image insert |
| IMAGE_MIME_TYPES | `packages/common/src/constants.ts` | 237–247 | 9 supported image formats |
| cropElement | `packages/element/src/cropElement.ts` | 34 | Per-handle crop calculation with MINIMAL_CROP_SIZE = 10px |
| actionToggleCropEditor | `packages/excalidraw/actions/actionCropEditor.tsx` | 13–59 | Sets `appState.croppingElementId` to enter crop mode |
| crop in App.tsx | `packages/excalidraw/components/App.tsx` | 12315 | Calls cropElement() during pointer move in crop mode |
| getEmbedLink | `packages/element/src/embeddable.ts` | 171 | Converts raw URL → embeddable iframe src |
| renderEmbeddable prop | `packages/excalidraw/types.ts` | 671 | `(element, appState) => JSX.Element \| null` |
| SVG embeddable export | `packages/excalidraw/renderer/staticSvgScene.ts` | 237 | `<foreignObject>` with `<iframe>` in SVG output |
| ALLOWED_PASTE_MIME_TYPES | `packages/common/src/constants.ts` | 273 | All IMAGE_MIME_TYPES + text/plain + text/html |

## How It Works

### Image Insertion
Images can be dropped onto the canvas (`handleAppOnDrop`, App.tsx:11858), pasted from clipboard (App.tsx:4068 via `parseDataTransferEvent`), or inserted via the image toolbar button (App.tsx:11628). In all cases, `insertImages()` (App.tsx:11796) is called:
1. Creates placeholder `ExcalidrawImageElement` objects positioned in a grid
2. Calls `initializeImage()` per file to load the image data and store it in `files` state
3. Calls `updateScene()` with the new elements

Files (binary image data) are stored separately from elements — in `app.state.files` (a `BinaryFiles` map keyed by `FileId`). This keeps element JSON lightweight.

### Supported Formats
9 MIME types: `image/svg+xml`, `image/png`, `image/jpeg`, `image/gif`, `image/webp`, `image/bmp`, `image/x-icon`, `image/avif`, `image/jfif`.

SVG images get special handling — they are stored as SVG strings and rendered inline, not as base64 data URLs.

### Image Crop Editor
Entering crop mode: `actionToggleCropEditor` (actionCropEditor.tsx:13) sets `appState.croppingElementId` to the selected image element's ID. This activates crop handles on the canvas.

`cropElement()` (cropElement.ts:34) is called during pointer move (App.tsx:12315). It takes the active transform handle direction (n/s/e/w/ne/nw/se/sw), the image's `naturalWidth`/`naturalHeight`, and the pointer coordinates. It computes new `crop` coordinates (pixel-level, relative to the original image) for the given handle, clamped to `MINIMAL_CROP_SIZE = 10`. The crop is stored as `{ x, y, width, height, naturalWidth, naturalHeight }` on the image element — the original image data is not modified.

### Embeddable Elements
`getEmbedLink(link)` (embeddable.ts:171) converts a raw URL to an embeddable `IframeDataWithSandbox`:
- YouTube: multiple URL patterns → `embed/` format
- Vimeo: player format
- Generic URLs in the allowlist: passed through with configured sandbox flags

The allowlist (embeddable.ts:~165) includes: `codesandbox.io`, `replit.com`, `stackblitz.com`, `x.com`, `reddit.com`, `forms.microsoft.com`, and others. URLs not in the allowlist are blocked.

`renderEmbeddable` is a React prop — if not provided by the host, embeddable elements render a default iframe. In SVG export, embeddable elements become `<foreignObject>` with an `<iframe>` child.

## Dependencies
- `app.state.files: BinaryFiles` (image data store, separate from elements)
- `appState.croppingElementId` (active crop mode)
- `VITE_APP_ALLOWED_EMBED_DOMAINS` env var (can extend the embed allowlist)
- `renderEmbeddable` prop (optional custom iframe renderer)

## Pros
- **9 image formats:** Broader support than most canvas tools — AVIF, WebP, GIF (animated), SVG inline all work.
- **Crop is non-destructive:** Original image data is never modified — the `crop` object on the element is just a viewport into the original. Crop can be reset.
- **Embeddable elements support live interaction:** YouTube videos play, CodeSandbox boxes run code — the iframe is truly interactive, not a screenshot.
- **Files stored separately from elements:** Binary image data doesn't bloat the element JSON, and unused files are garbage-collected after 24 hours.
- **8-directional crop handles:** All 8 transform handle directions (n/s/e/w/ne/nw/se/sw) work as crop handles.

## Cons
- **Embed allowlist is hardcoded:** Only specific domains can be embedded. Custom internal tools or unlisted services cannot be embedded without modifying `embeddable.ts` or setting `VITE_APP_ALLOWED_EMBED_DOMAINS`. The list is narrow.
- **No image resize with aspect-ratio lock by default:** Resizing an image does not lock aspect ratio unless Shift is held — unintuitive for most users.
- **No image filters/adjustments:** No brightness, contrast, saturation, or opacity blending beyond the global element opacity.
- **Crop editor has no numeric input:** Crop coordinates cannot be typed — only dragged via handles.
- **Embeddable SVG export uses `<foreignObject>`:** `<foreignObject>` has limited support in SVG viewers and PDF renderers — embeds may not display outside browsers.
- **No video file upload:** Only iframe-embedded videos (YouTube/Vimeo) work — local `.mp4` files cannot be inserted.
- **`MINIMAL_CROP_SIZE = 10px`:** Very small minimum — at low zoom, a 10px crop can be impossible to interact with.

## Notes
- SVG images inserted from disk are rendered via `<image>` in canvas SVG output (staticSvgScene.ts) — they remain as vector and scale cleanly.
- `isSupportedImageFile()` in `constants.ts` checks `IMAGE_MIME_TYPES` values — the MIME type list is the single source of truth for what is accepted.
- Image files in collab sessions are synced via Firebase Storage at `/files/rooms/{roomId}/{fileId}` — each file is independently uploaded and cached.
