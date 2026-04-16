---
name: Real-Time Collaboration
description: Socket.IO multiplayer sync, AES-GCM E2E encryption, follow mode, live cursors, Firebase storage, reconciliation
type: project
---

# Real-Time Collaboration

## Overview
Multiple users can edit the same canvas simultaneously via Socket.IO with end-to-end AES-GCM encryption. The encryption key lives only in the URL fragment — the server never sees plaintext. Live cursors update at ~30fps. A "follow mode" lets one user track another's viewport. Scene state is reconciled using fractional indices and version nonces.

## Code Location

| Component | File | Lines | Role |
|-----------|------|-------|------|
| Portal.tsx | `excalidraw-app/collab/Portal.tsx` | full (257 lines) | Socket.IO connection management, message broadcast |
| Collab.tsx | `excalidraw-app/collab/Collab.tsx` | full file | Main collab coordinator, event handling |
| CollabError.tsx | `excalidraw-app/collab/CollabError.tsx` | full file | Collab error display |
| encryption.ts | `packages/excalidraw/data/encryption.ts` | full file | AES-GCM 128-bit encrypt/decrypt, key generation |
| ENCRYPTION_KEY_BITS | `packages/common/src/constants.ts` | ~line 60 | 128 (AES-GCM key length) |
| reconcile.ts | `packages/excalidraw/data/reconcile.ts` | full file | Remote+local element reconciliation |
| shouldDiscardRemoteElement | `packages/excalidraw/data/reconcile.ts` | 23 | Discard logic: editing, version, nonce tie-break |
| firebase.ts | `excalidraw-app/data/firebase.ts` | full file | Firestore scene storage, Firebase Storage file sync |
| FirebaseStoredScene type | `excalidraw-app/data/firebase.ts` | ~45 | `{ sceneVersion, iv: Bytes, ciphertext: Bytes }` |
| FollowMode.tsx | `packages/excalidraw/components/FollowMode/FollowMode.tsx` | full (44 lines) | "Following {username}" badge with disconnect button |
| renderRemoteCursors | `packages/excalidraw/clients.ts` | 57 | Draws cursor shapes for collaborators on canvas |
| CURSOR_SYNC_TIMEOUT | `excalidraw-app/app_constants.ts` | 8 | 33ms (~30fps) cursor throttle |
| onPointerUpdate (throttled) | `excalidraw-app/collab/Collab.tsx` | 914–925 | Throttled cursor position broadcast |
| WS_EVENTS | `excalidraw-app/app_constants.ts` | 16–21 | Socket event names |
| fractionalIndex.ts | `packages/element/src/fractionalIndex.ts` | full file | `generateNKeysBetween` for z-order encoding |

## How It Works

### Connection & Broadcast
`Portal.open(socket, id, key)` (Portal.tsx:37) stores the socket, roomId, and roomKey. It registers handlers for `"init-room"`, `"new-user"`, and `"room-user-change"`. `_broadcastSocketData(data, volatile)` (line 85) serializes → JSON → UTF-8 → encrypts → emits via `WS_EVENTS.SERVER` (reliable) or `WS_EVENTS.SERVER_VOLATILE` (volatile, cursor-only).

Socket events:
- `"server-broadcast"` — reliable scene deltas
- `"server-volatile-broadcast"` — volatile (cursor positions, idle status)
- `"user-follow"` / `"user-follow-room-change"` — follow mode

### End-to-End Encryption
`encryption.ts` uses **AES-GCM 128-bit** (Web Crypto API):
- `generateEncryptionKey()` (line 12): `crypto.subtle.generateKey({ name: "AES-GCM", length: 128 }, true, ["encrypt","decrypt"])`
- `encryptData(key, data)` (line 50): generates a random 12-byte IV, returns `{ encryptedBuffer, iv }`
- `decryptData(iv, encrypted, privateKey)` (line 80): standard AES-GCM decrypt

The encryption key is stored as a JWK string in the URL fragment (never in the URL path or sent to the server). Even Firebase/Firestore receives only ciphertext (`{ sceneVersion, iv, ciphertext }` — firebase.ts:~45).

### Reconciliation
`reconcileElements(localElements, remoteElements, localAppState)` (reconcile.ts:73):
- `shouldDiscardRemoteElement(localAppState, local, remote)` (line 23): discards remote if: element is currently being edited by local user, OR local version > remote version, OR same version and local `versionNonce` ≤ remote `versionNonce`
- Result: remotes win by default, sorted by `orderByFractionalIndex`, de-duplicated via `syncInvalidIndices`
- Fractional index validation is throttled at 60 seconds (line 69) to avoid performance impact on fast-paced edits

### Live Cursors
`renderRemoteCursors()` (clients.ts:57) iterates `renderConfig.remotePointerViewportCoords` (built in `InteractiveCanvas.tsx:98–135` from `appState.collaborators`). Each cursor is drawn with the collaborator's color. Out-of-bounds or idle cursors render at `globalAlpha = 0.3`. Mouse-down state draws a 15px circle. Cursor broadcast is throttled to 33ms via `onPointerUpdate = throttle(..., CURSOR_SYNC_TIMEOUT)` (Collab.tsx:914–925).

### Follow Mode
`FollowMode.tsx` (44 lines) renders a floating badge "Following {username}" with a disconnect button. Follow requests are sent via `portal.broadcastUserFollowed()` (Portal.tsx:250), emitting `WS_EVENTS.USER_FOLLOW_CHANGE`. When a user is followed, their viewport bounds are broadcast via `portal.broadcastVisibleSceneBounds()` (Portal.tsx:226) whenever `appState.followedBy.size > 0` — followers' viewports pan to match.

### Firebase Storage
Firestore stores encrypted scenes at `"scenes/{roomId}"` with a transaction that reconciles against the server version before writing (firebase.ts:187). Firebase Storage stores binary files (images) at `{prefix}/{fileId}` with 1-year cache-control headers. File prefixes: `/files/shareLinks` and `/files/rooms`. File uploads are flushed from a queue in `Portal.close()` (line 63).

## Dependencies
- `socket.io-client` npm package
- `firebase/app`, `firebase/firestore`, `firebase/storage`
- `VITE_APP_FIREBASE_CONFIG` environment variable
- `VITE_APP_WS_SERVER_URL` environment variable (Socket.IO server)
- Web Crypto API (AES-GCM)

## Pros
- **True E2E encryption:** The server never sees plaintext — the key lives only in the URL fragment. This is architecturally correct and a genuine privacy guarantee.
- **Reconciliation favors currently-editing users:** `shouldDiscardRemoteElement` protects elements being actively edited — remote changes do not interrupt active edits.
- **Fractional indexing enables correct multiplayer undo:** Every undo/redo produces elements with new versions — treated as new actions by other clients, not conflicting reverts.
- **30fps cursor updates feel smooth:** 33ms throttle is perceptually real-time for pointer tracking.
- **Follow mode is presentation-friendly:** Letting collaborators lock their viewport to a presenter's is useful for remote design reviews.
- **Files are cached 1 year:** Binary assets uploaded once are served from Firebase CDN without re-upload — collaboration on image-heavy canvases is efficient.

## Cons
- **Reconciliation can lose work in edge cases:** `shouldDiscardRemoteElement` discards remote when local version is higher — in some network partition scenarios, high-frequency local editing can silently drop valid remote changes.
- **`renderer/interactiveScene.ts:1881` TODO:** `// TODO: support multiplayer selected group IDs` — group selections are not synced between collaborators. Two users can select different groups of the same elements simultaneously without seeing each other's group selection.
- **Firebase is required for the hosted app:** There is no server-side fallback storage — if Firebase is unreachable, scene persistence and file sync fail. Self-hosters must provide their own Firebase project.
- **Collaboration pauses local autosave:** `LocalData.pauseSave("collaboration")` (Collab.tsx:506) stops IDB autosave during collab — if collaboration ends unexpectedly (network drop), the local save may lag behind the last synced state.
- **No offline collab queue:** If a user's network drops mid-session, their edits are not queued for re-sync — changes made offline are lost when the session reconnects.
- **Collab cursors render at `globalAlpha = 0.3` when out-of-bounds:** This is subtle — if a collaborator has scrolled far away, their cursor is barely visible at the canvas edge with no "scroll to collaborator" affordance.

## Notes
- The URL encryption key format is `#room={roomId},{key}` — both components must be present for decryption.
- `ENCRYPTION_KEY_BITS = 128` — AES-128-GCM rather than AES-256-GCM. This is a deliberate choice (performance vs. security tradeoff). Both are considered secure for this use case.
- Local autosave resumes when `Portal.close()` is called — the pause is always eventually lifted.
