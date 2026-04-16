---
name: AI / Text-to-Diagram (TTD)
description: Mermaid-to-Excalidraw conversion, AI chat agent for diagram generation, DiagramToCodePlugin, TTDStreamFetch SSE utility
type: project
---

# AI / Text-to-Diagram (TTD)

## Overview
Two distinct AI features exist under the "Text-to-Diagram" umbrella. The Mermaid tab converts Mermaid syntax directly to Excalidraw elements. The AI chat tab drives multi-turn conversation with an AI backend to generate Mermaid diagrams. The DiagramToCodePlugin handles the reverse direction: canvas selection → AI → HTML/code. Chat history persists in IndexedDB.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| TTDDialog.tsx | `packages/excalidraw/components/TTDDialog/TTDDialog.tsx` | 26–135 | Root dialog, two tabs: AI chat + Mermaid editor |
| TextToDiagram.tsx | `packages/excalidraw/components/TTDDialog/TextToDiagram.tsx` | full file | AI chat tab with hooks |
| MermaidToExcalidraw.tsx | `packages/excalidraw/components/TTDDialog/MermaidToExcalidraw.tsx` | full file | Direct Mermaid editor tab |
| TTDContext.tsx | `packages/excalidraw/components/TTDDialog/TTDContext.tsx` | full file | Jotai atoms: errorAtom, chatHistoryAtom, showPreviewAtom |
| TTDChatPanel.tsx | `packages/excalidraw/components/TTDDialog/Chat/TTDChatPanel.tsx` | full file | Chat UI rendering |
| ChatHistoryMenu.tsx | `packages/excalidraw/components/TTDDialog/Chat/ChatHistoryMenu.tsx` | full file | Sidebar of saved chat sessions |
| convertMermaidToExcalidraw | `packages/excalidraw/components/TTDDialog/common.ts` | 43 | Calls `api.parseMermaidToExcalidraw()` from lazy-loaded pkg |
| TTDStreamFetch | `packages/excalidraw/components/TTDDialog/utils/TTDStreamFetch.ts` | 84 | SSE stream fetch for AI chat responses |
| parseSSEStream | `packages/excalidraw/components/TTDDialog/utils/TTDStreamFetch.ts` | 48 | Generator that parses chunked SSE |
| TTDStorage.ts | `excalidraw-app/data/TTDStorage.ts` | full (51 lines) | `TTDIndexedDBAdapter` for chat history |
| IDB_TTD_CHATS key | `excalidraw-app/app_constants.ts` | 49 | `"excalidraw-ttd-chats"` |
| DiagramToCodePlugin | `packages/excalidraw/components/DiagramToCodePlugin/DiagramToCodePlugin.tsx` | full (19 lines) | Registers `generate` fn into `app.plugins.diagramToCode` |
| AI.tsx (app-level) | `excalidraw-app/components/AI.tsx` | 23–101 | Implements both AI endpoints for the hosted app |
| AI backend env var | `packages/excalidraw/vite-env.d.ts` | 20 | `VITE_APP_AI_BACKEND` |

## How It Works

### Mermaid → Excalidraw
`MermaidToExcalidraw.tsx` renders a text editor. On change (debounced), `convertMermaidToExcalidraw()` (common.ts:43) calls `api.parseMermaidToExcalidraw(definition)` from the lazily-imported `@excalidraw/mermaid-to-excalidraw` package (loaded on first dialog open, TTDDialog.tsx:73). The result is rendered in a preview canvas. On insert, elements are added to the main scene. Auto-fix utilities (`mermaidAutoFix.ts`, `mermaidValidation.ts`) attempt to correct common Mermaid syntax errors before parsing.

### AI Chat Agent
`TextToDiagram.tsx` uses five hooks:
- `useChatAgent` — manages the active chat session
- `useTTDChatStorage` — loads/saves chats via `TTDIndexedDBAdapter`
- `useMermaidRenderer` — renders Mermaid output to preview
- `useTextGeneration` — calls the AI backend via `TTDStreamFetch`
- `useChatManagement` — handles session create/delete/switch

`TTDStreamFetch()` (TTDStreamFetch.ts:84): POSTs `{ messages }` to `${VITE_APP_AI_BACKEND}/v1/ai/text-to-diagram/chat-streaming`, expects SSE. Parses `data: ...` lines via `parseSSEStream` generator (line 48). Handles `StreamChunk` types: `"content"` (accumulate delta), `"done"`, `"error"`. Extracts `X-Ratelimit-Limit` and `X-Ratelimit-Remaining` headers. Returns `{ generatedResponse, error, rateLimit?, rateLimitRemaining? }`.

### Chat History Storage
`TTDIndexedDBAdapter` (TTDStorage.ts): IDB database `"excalidraw-ttd-chats-db"`, store `"excalidraw-ttd-chats-store"`, key `"ttdChats"`. Static `loadChats()` / `saveChats(chats)` methods via `idb-keyval`. `SavedChat` type: `{ id, title, messages, currentPrompt, timestamp }`.

### DiagramToCodePlugin (Canvas → Code)
`DiagramToCodePlugin.tsx` (19 lines): a React component that calls `app.setPlugins({ diagramToCode: { generate: props.generate } })` via `useLayoutEffect`. It injects a `generate` function into the app's plugin system. Returns `null` — no DOM output.

In `excalidraw-app/components/AI.tsx:23–101`, the `generate` callback:
1. Exports the magic frame's children to a JPG blob → data URL
2. Extracts text content from elements within the frame
3. POSTs to `${VITE_APP_AI_BACKEND}/v1/ai/diagram-to-code/generate`
4. Returns `{ html }` which is stored in the linked iframe element's `customData.generationData`

### AI Backends
The frontend is provider-agnostic. Two backend endpoints are consumed:
- `POST /v1/ai/text-to-diagram/chat-streaming` — SSE stream
- `POST /v1/ai/diagram-to-code/generate` — JSON response

The bundled `packages/excalidraw/data/ai/types.ts` contains OpenAI-compatible type definitions, suggesting the default backend proxies OpenAI, but any compatible backend works.

## Dependencies
- `@excalidraw/mermaid-to-excalidraw` (lazy-loaded npm package)
- `VITE_APP_AI_BACKEND` environment variable
- `idb-keyval` for chat history IDB
- `app.plugins.diagramToCode` (optional plugin slot)

## Pros
- **Mermaid support is comprehensive:** `@excalidraw/mermaid-to-excalidraw` handles flowcharts, sequence diagrams, ER diagrams, and more — a wide variety of diagram types out of the box.
- **Multi-turn chat preserves context:** Chat history is sent with each request — the AI can refine previous diagrams based on follow-up prompts.
- **Chat history is persisted:** Sessions survive page reload (IDB-backed). The `ChatHistoryMenu` lets users return to previous conversations.
- **Streaming responses:** `TTDStreamFetch` uses SSE — the Mermaid output appears incrementally, giving responsive UI feedback for slow AI responses.
- **Rate limit exposure:** `X-Ratelimit-Limit` / `X-Ratelimit-Remaining` headers are extracted and surfaced in the UI — users know when they're approaching limits.
- **DiagramToCode is pluggable:** Any `generate` function can be injected — teams can connect their own internal AI services.

## Cons
- **Two separate AI features with confusing naming:** "Text-to-Diagram" (AI chat → Mermaid → elements) and "Diagram-to-Code" (canvas elements → AI → HTML) are both "AI" but in opposite directions, creating conceptual confusion.
- **Mermaid is the only intermediate format:** The AI chat always generates Mermaid, which is then parsed into elements. Mermaid's syntax limits what diagrams are expressible — it cannot produce free-form layouts.
- **`@excalidraw/mermaid-to-excalidraw` is lazy-loaded:** First dialog open incurs a network fetch. Slow connections see a delay before the dialog is functional.
- **Auto-fix utilities are heuristic:** `mermaidAutoFix.ts` attempts to correct common errors, but can silently mutate the user's input — unexpected behavior if the correction is wrong.
- **Backend is entirely external:** There is no local/offline fallback. If `VITE_APP_AI_BACKEND` is unreachable, both AI features fail completely.
- **No prompt templates or starting points:** Users face a blank chat input — no example prompts, diagram type suggestions, or guided flows.
- **DiagramToCode produces HTML only:** The output is raw HTML inserted in an iframe element — not parsed back into Excalidraw elements. The canvas diagram cannot be regenerated from the AI output.

## Notes
- `TTDDialog.WelcomeMessage` is a named sub-component exported separately for host integration — allows custom welcome screen copy.
- The `onTextSubmit` callback (TTD API) is the integration point for custom AI backends — documented in the library's public API.
- Chat sessions are per-device/per-browser — no cloud sync for chat history, even in collaborative sessions.
