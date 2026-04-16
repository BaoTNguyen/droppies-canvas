# Excalidraw Feature Overview

> Canvas/whiteboard application with hand-drawn style, infinite canvas, real-time collaboration, and AI diagram generation.

---

## Master Feature List

### Drawing & Input
| # | Feature | File |
|---|---------|------|
| 1 | [Drawing Tools](01_drawing_tools.md) | `shapes.tsx`, `App.tsx`, `lasso/`, `laser-trails.ts` |
| 2 | [Element Properties & Styling](02_element_properties_styling.md) | `element/src/types.ts`, `shape.ts`, `EyeDropper.tsx`, `actionStyles.ts` |

### Canvas & Navigation
| # | Feature | File |
|---|---------|------|
| 3 | [Canvas & View Modes](03_canvas_view_modes.md) | `App.tsx`, `actionCanvas.tsx`, `snapping.ts`, `staticScene.ts` |

### Editing Operations
| # | Feature | File |
|---|---------|------|
| 4 | [Selection & Editing](04_selection_editing.md) | `App.tsx`, `lasso/`, `actionGroup.tsx`, `actionAlign.tsx`, `zindex.ts` |
| 5 | [Text & Container Binding](05_text_container_binding.md) | `element/src/textElement.ts`, `wysiwyg/textWysiwyg.tsx` |
| 6 | [Arrows & Binding](06_arrows_binding.md) | `element/src/binding.ts`, `elbowArrow.ts`, `flowchart.ts` |
| 7 | [Frames](07_frames.md) | `element/src/frame.ts`, `actionFrame.ts`, `staticScene.ts` |

### Media & Content
| # | Feature | File |
|---|---------|------|
| 8 | [Images & Media](08_images_media.md) | `App.tsx`, `element/src/cropElement.ts`, `element/src/embeddable.ts` |
| 9 | [Shape Libraries](09_shape_libraries.md) | `LibraryMenu.tsx`, `data/library.ts`, `actionAddToLibrary.ts` |

### AI & Automation
| # | Feature | File |
|---|---------|------|
| 10 | [AI / Text-to-Diagram](10_ai_text_to_diagram.md) | `TTDDialog/`, `DiagramToCodePlugin/`, `excalidraw-app/components/AI.tsx` |

### Collaboration & Sync
| # | Feature | File |
|---|---------|------|
| 11 | [Real-Time Collaboration](11_realtime_collaboration.md) | `excalidraw-app/collab/`, `data/encryption.ts`, `data/reconcile.ts`, `data/firebase.ts` |
| 12 | [Persistence & Export](12_persistence_export.md) | `excalidraw-app/data/LocalData.ts`, `data/filesystem.ts`, `scene/export.ts`, `subset/` |
| 13 | [Undo/Redo History](13_undo_redo_history.md) | `excalidraw/history.ts`, `element/src/delta.ts`, `element/src/fractionalIndex.ts` |

### Discovery & UX
| # | Feature | File |
|---|---------|------|
| 14 | [Search & Command Palette](14_search_command_palette.md) | `SearchMenu.tsx`, `CommandPalette/` |
| 15 | [Stats Panel](15_stats_panel.md) | `components/Stats/`, `actionToggleStats.tsx` |
| 16 | [Localization & Accessibility](16_localization_accessibility.md) | `i18n.ts`, `locales/`, `PenModeButton.tsx`, `HelpDialog.tsx` |

---

## One-Line Feature Summaries

| # | Feature | Summary |
|---|---------|---------|
| 1 | Drawing Tools | 14 tools (shapes, freedraw, text, eraser, laser, lasso) with keyboard shortcuts and tool lock |
| 2 | Element Styling | Per-element stroke/fill/color/opacity/roughness with eye-dropper and copy-paste styles |
| 3 | Canvas & View Modes | Infinite canvas 10–3000% zoom; dark/grid/zen/view modes; object + gap snapping |
| 4 | Selection & Editing | Box and lasso selection; group/ungroup; align/distribute; z-index; element locking |
| 5 | Text & Containers | WYSIWYG inline editor; text bound to rectangles/diamonds/ellipses/arrows with auto-wrap |
| 6 | Arrows & Binding | A*-routed elbow arrows; element endpoint binding; flowchart node creation; 12 arrowhead types |
| 7 | Frames | Named grouping frames with clipping; wrap-in-frame action; Magic Frame for AI generation |
| 8 | Images & Media | 9 image formats; non-destructive crop editor; live iframe embeds (YouTube, Vimeo, web services) |
| 9 | Shape Libraries | IDB-persisted reusable shape collections; URL token import; community portal browser |
| 10 | AI / TTD | Mermaid-to-elements conversion; multi-turn AI chat for diagram generation; diagram-to-code plugin |
| 11 | Collaboration | Socket.IO multiplayer with AES-GCM E2E encryption; follow mode; 30fps live cursors |
| 12 | Persistence & Export | 300ms autosave (localStorage + IDB); .excalidraw files; PNG/SVG with WASM font subsetting |
| 13 | Undo/Redo | Unbounded delta-based undo stacks; CRDT-compatible; fractional index z-order |
| 14 | Search & Palette | Canvas text search with highlight overlays; fuzzy command palette over all actions/tools |
| 15 | Stats Panel | Numeric position/size/angle/font editing for selected elements; multi-element atomic units |
| 16 | Localization | 58 locales via Crowdin (85% threshold); RTL; auto pen/tablet detection; platform shortcut labels |

---

## Decision Matrix

Rate each feature on **User Value** (how much end users benefit), **Code Quality** (maintainability, debt level), and **Complexity Cost** (how hard it is to maintain/extend). H = High, M = Medium, L = Low.

| # | Feature | User Value | Code Quality | Complexity Cost | Notes |
|---|---------|-----------|--------------|-----------------|-------|
| 1 | Drawing Tools | H | H | M | Laser is hidden from default toolbar — discoverability gap |
| 2 | Element Styling | H | H | L | Simple, well-structured; eye-dropper disabled on mobile |
| 3 | Canvas & View Modes | H | H | M | Grid+snap mutually exclusive is an odd constraint |
| 4 | Selection & Editing | H | M | M | Align/distribute broken for frames is a known gap |
| 5 | Text & Containers | H | M | M | No rich text; frame text binding absent |
| 6 | Arrows & Binding | H | M | H | A* router + COMPLEX_BINDINGS flag adds significant complexity |
| 7 | Frames | H | M | M | Magic Frame AI state not persisted; align/distribute blocked |
| 8 | Images & Media | M | M | M | Hardcoded embed allowlist limits flexibility |
| 9 | Shape Libraries | M | M | L | No instance isolation (known TODO); flat structure |
| 10 | AI / TTD | M | M | H | Two overlapping AI features; external backend required; Mermaid-only intermediate |
| 11 | Collaboration | H | H | H | Architecturally solid E2E encryption; Firebase dependency is a lock-in |
| 12 | Persistence & Export | H | H | M | WASM font subsetting is impressive; localStorage overflow risk |
| 13 | Undo/Redo | H | H | M | No size cap; known edge case bugs (#7348) |
| 14 | Search & Palette | M | M | L | Search limited to text content only; palette items not cached |
| 15 | Stats Panel | M | H | L | Angle disabled for frames with no UI explanation |
| 16 | Localization | M | H | L | 58 locales; document.dir side effect for embedding hosts |

---

## Key Technical Observations

### Things That Are Well Done
- **E2E encryption architecture:** Key lives only in the URL fragment — architecturally correct and a genuine privacy guarantee.
- **Delta-based history:** Memory-efficient, CRDT-compatible, multiplayer-safe.
- **Elbow arrow A\* routing:** Sophisticated pathfinding with obstacle avoidance — well beyond typical canvas tool capability.
- **HarfBuzz WASM font subsetting:** Production SVG exports with clean font embedding, no CDN dependencies.
- **Lasso selection with real-time polygon testing:** Far more precise than standard box selection for complex layouts.

### Known Product Gaps (with code evidence)
- **Align/distribute blocked for frames** — `actionAlign.tsx:51`, `actionDistribute.tsx:43` (`// TODO enable aligning frames when implemented properly`)
- **Group selection not synced in collab** — `renderer/interactiveScene.ts:1881` (`// TODO: support multiplayer selected group IDs`)
- **Invisible elements recorded in undo/redo** — `actionFinalize.tsx:142,232,346` (`// TODO: #7348`)
- **Paste doesn't strip element formatting** — `App.tsx:3736` (`// TODO: remove formatting from elements if isPlainPaste`)
- **Arrow/line type conflation in restore path** — `data/restore.ts:502` (`// TODO: Separate arrow from linear element`)
- **Library not isolated per editor instance** — `data/library.ts:253` (`// TODO uncomment after/if we make jotai store scoped...`)

### Feature Flags
- **`COMPLEX_BINDINGS`** (default: `false`) — advanced arrow binding modes (inside/orbit/skip). Enable via browser console: `setFeatureFlag("COMPLEX_BINDINGS", true)`. Being experimented with, tracked in Sentry.

### Unreleased Breaking API Changes (already in tree)
- `excalidrawAPI` prop renamed to `onExcalidrawAPI`
- New lifecycle props: `onMount`, `onInitialize`, `onUnmount`
- New `ExcalidrawAPIProvider` / `useExcalidrawAPI` / `useAppStateValue` hooks
- New `onExport` async generator hook
- `ExcalidrawAPI.isDestroyed` flag
