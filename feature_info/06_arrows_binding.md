---
name: Arrows & Binding
description: Arrow-to-element binding, elbow arrow A* routing, flowchart node creation, arrowhead types, COMPLEX_BINDINGS feature flag
type: project
---

# Arrows & Binding

## Overview
Arrows can bind their endpoints to other elements (snapping to edges or centers). Elbow arrows use A* pathfinding to route around obstacles with axis-aligned segments. Flowchart mode lets users click-through to generate connected nodes. Multiple arrowhead types are available at both ends.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| bindOrUnbindBindingElement | `packages/element/src/binding.ts` | 145–222 | Top-level binding coordinator during arrow drag |
| getBindingStrategyForDragging_simple | `packages/element/src/binding.ts` | 621 | Standard bind strategy (hover radius snap) |
| getBindingStrategyForDragging_complex | `packages/element/src/binding.ts` | 872–927 | COMPLEX_BINDINGS: inside/orbit/skip modes |
| BindingStrategy type | `packages/element/src/binding.ts` | 87–105 | `{ mode, element, focusPoint } \| { mode: null } \| { mode: undefined }` |
| BASE_BINDING_GAP | `packages/element/src/binding.ts` | 112–113 | 5px gap from element edge to arrow endpoint |
| updateElbowArrowPoints | `packages/element/src/elbowArrow.ts` | 907 | Public entry point for elbow arrow routing |
| routeElbowArrow | `packages/element/src/elbowArrow.ts` | 1439 | A* pathfinding on dynamic grid |
| calculateGrid | `packages/element/src/elbowArrow.ts` | ~1200 | Builds sparse grid from element bounding boxes |
| astar | `packages/element/src/elbowArrow.ts` | ~1350 | A* with heading-aware cost |
| addNewNode | `packages/element/src/flowchart.ts` | 240 | Creates new flowchart node + connecting arrow |
| addNewNodes | `packages/element/src/flowchart.ts` | 292 | Public: create multiple nodes from start node |
| getNodeRelatives | `packages/element/src/flowchart.ts` | 64 | Traverses arrows to find predecessors/successors |
| Arrowhead types | `packages/element/src/types.ts` | 320 | Full union of all arrowhead type strings |
| COMPLEX_BINDINGS flag | `packages/common/src/utils.ts` | 1282–1288 | Feature flag, default false, localStorage-persisted |

## How It Works

### Arrow-to-Element Binding
During arrow endpoint drag, `bindOrUnbindBindingElement()` (binding.ts:145) determines a `BindingStrategy` for each end. The strategy is computed by `getBindingStrategyForDraggingBindingElementEndpoints()` (line 575) which routes to `_simple` or `_complex` based on the `COMPLEX_BINDINGS` feature flag. The simple strategy checks if the dragged endpoint is within `maxBindingDistance_simple()` of a bindable element. On mouse-up, `bindBindingElement()` writes `startBinding`/`endBinding` on the arrow element and adds `{ type: "arrow", id }` to the target element's `boundElements` array.

### Elbow Arrow Routing
`updateElbowArrowPoints()` (elbowArrow.ts:907) is called whenever an elbow arrow needs re-routing. It calls `getElbowArrowData()` (line 1192) to build the routing data: resolves bound elements, computes `dynamicAABBs` (bounding boxes + 40px `BASE_PADDING` buffer), dongle positions (exit points from element edges), and heading directions.

`routeElbowArrow()` (line 1439) runs:
1. `calculateGrid(dynamicAABBs)` — builds a sparse grid where nodes correspond to element boundary intersections
2. Maps start/end dongle positions to grid nodes
3. Marks endpoint nodes as `closed` to prevent the path from stepping on them
4. Calls `astar(startNode, endNode, grid, startHeading, endHeading)` — standard A* with heading-aware cost (turning costs more than going straight)
5. Extracts global points; prepends/appends actual start/end points around the dongles

`handleSegmentRenormalization()` (line 113) deduplicates collinear/parallel segments after manual drag, respecting `fixedSegments`.

### Flowchart Node Creation
`addNewNode()` (flowchart.ts:240) creates a copy of the source element (preserving styles), then calls `createBindingArrow()` to connect them with an elbow arrow, and `bindBindingElement()` on both ends. `getOffsets()` (line 150) places the new node: checks for clear space in the chosen direction; if occupied, fans out alternating left/right. Constants: `VERTICAL_OFFSET = 100`, `HORIZONTAL_OFFSET = 100`. Arrow keys in flowchart mode trigger `addNewNodes()` from `App.tsx`.

### Arrowhead Types
`Arrowhead` union (types.ts:320):
`"arrow" | "bar" | "circle" | "circle_outline" | "triangle" | "triangle_outline" | "diamond" | "diamond_outline" | CardinalityArrowhead`

`CardinalityArrowhead`: `"cardinality_one" | "cardinality_many" | "cardinality_one_or_many"`

Legacy names (`"dot"`, `"crowfoot_one"`, etc.) are mapped by `normalizeArrowhead()` in `arrowheads.ts:3–21`.

### COMPLEX_BINDINGS Feature Flag
Disabled by default (`packages/common/src/utils.ts:1288`). Enables:
- Three bind modes: `"inside"` (endpoint inside element), `"orbit"` (wrap around outside), `"skip"` (no binding)
- Multiple simultaneous binding target highlights during hover
- `appState.bindMode` as a global binding mode setting

Enable via browser console: `setFeatureFlag("COMPLEX_BINDINGS", true)` (persisted to localStorage).

## Dependencies
- `appState.editingLinearElement` (which arrow endpoint is being dragged)
- `appState.bindMode` (only used when COMPLEX_BINDINGS enabled)
- `ShapeCache` for element bounding box calculations
- `@excalidraw/math` geometry primitives for intersection tests

## Pros
- **Elbow arrow A* routing is sophisticated:** Automatically routes around obstacles with axis-aligned segments — appropriate for flowcharts and ER diagrams. Segment renormalization removes redundant elbows.
- **Flowchart node creation is keyboard-driven:** Arrow keys generate connected nodes, making flowchart construction fast without switching tools.
- **8 arrowhead types including cardinality symbols:** ER diagram notation (one, many, one-or-many) is built-in — no workarounds needed.
- **Binding gap gives visual breathing room:** `BASE_BINDING_GAP = 5px` keeps arrow endpoints slightly away from shape edges, improving readability.
- **COMPLEX_BINDINGS is staged:** The feature flag allows experimentation with "inside" endpoint binding without destabilizing the default experience.
- **Arrow labels:** Text can be bound to an arrow element, appearing along its path.

## Cons
- **Elbow routing can produce suboptimal paths:** The A* grid is built from element bounding boxes with a fixed 40px padding — this can produce long detours around small obstacles or wide padding around tightly packed elements.
- **`fixedSegments` can get confused:** `handleSegmentRenormalization()` (line 113) acknowledges edge cases in the TODO comments — manually dragged segments can produce unexpected normalization results.
- **COMPLEX_BINDINGS is localhost-only:** There is no UI to toggle it — users must open the browser console. It's tracked in Sentry as a feature experiment but not documented in the UI.
- **Flowchart fan-out algorithm is simplistic:** `getOffsets()` uses `(linkedNodes.length + 1) % 2` alternation — works for simple trees but produces awkward layouts for dense graphs.
- **No curved arrows through waypoints:** Arrow type "curved" controls the overall curvature, but you cannot manually place waypoints on a curved arrow.
- **`binding.ts` has a complex/simple split** that makes the codebase harder to follow — two completely different binding algorithms exist simultaneously, gated by a flag.

## Notes
- `data/restore.ts:502` TODO: `// TODO: Separate arrow from linear element` — arrows and lines share the `ExcalidrawLinearElement` type internally, which adds complexity to binding logic that only applies to arrows.
- `COMPLEX_BINDINGS` is tracked in Sentry at `excalidraw-app/sentry.ts:91–92` — its usage rate is being measured even though the feature is undocumented.
- `BASE_PADDING = 40` (elbowArrow.ts) is the clearance given to element bounding boxes during routing — it is not user-configurable.
