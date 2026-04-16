# Online Collaboration

## Summary
Multiple users can draw on the same canvas simultaneously in real time. One user hosts a session and shares a lobby address; others paste that address into the Connect dialog. Once connected, every participant sees each other's cursor positions, display names, and live strokes as they are drawn. A built-in text chat panel lets collaborators communicate without leaving the application. A player-list panel shows who is connected and lets any user jump the camera to any other participant's current viewport location.

## How It Works
Connectivity is established via WebRTC peer-to-peer (STUN/TURN) with a developer-hosted signaling server (`wss://signalserver.infinipaint.com:8000` in `default_p2p.json`). The host creates a `NetServer` and clients create a `NetClient`, both wrapped in the `World` class. All mutable canvas state — canvas components, layers, bookmarks, grids — is modelled as `NetObj*` types managed by `NetworkingObjects::NetObjManager`. Mutations are serialized with `cereal::PortableBinaryOutputArchive` and sent as binary deltas; the `DelayUpdateSerializedClassManager` batches updates to reduce chattiness. `ClientData` objects (one per connected user) carry camera coordinates, cursor position, window size, display name, and cursor color; `World::draw_other_player_cursors()` renders remote cursors each frame. Chat messages are dispatched through `ClientData::send_chat_message()` and stored in `World::chatMessages`.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| World-level networking wiring | `infinipaint-0.4.2/src/World.hpp` | `World::netServer`, `World::netClient`, `start_hosting()`, `init_client()` |
| Per-client state | `infinipaint-0.4.2/src/ClientData.hpp` | `ClientData`, `InitStruct`, `send_chat_message()`, `draw_cursor()` |
| Network object manager | `infinipaint-0.4.2/src/Helpers/NetworkingObjects/NetObjManager.hpp` | `NetObjManager` |
| P2P config (STUN/TURN) | `infinipaint-0.4.2/data/config/default_p2p.json` | `signalingServer`, `turnList` |
| Chat UI entry point | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::chat_box()`, `chatMessageInput` |
| Player list UI | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::player_list()` |
| Host/connect menu | `infinipaint-0.4.2/src/Toolbar.hpp` | `HOST_MENU`, `CONNECT_MENU` enum entries |
| Delayed update batching | `infinipaint-0.4.2/src/Helpers/NetworkingObjects/DelayUpdateSerializedClassManager.hpp` | `DelayUpdateSerializedClassManager` |

## User-Facing Pros
- **Zero-install joining**: A client only needs the lobby address string — no accounts, no login flow, and (in the web build) no software installation.
- **Live cursor visibility**: Remote cursors render every frame with the participant's chosen display name and a unique color, providing spatial awareness of collaborator activity.
- **Camera-jump to collaborator**: The player list lets any user teleport their view to any connected participant's exact position, enabling quick screen-sharing-like workflows without a separate tool.
- **Chat is session-persistent**: Chat messages survive during the session and display timestamps, so latecomers can read recent conversation context.
- **All canvas state is synchronized**: Layers, bookmarks, grids, and all object types replicate automatically — there is no manual "send to collaborators" step.

## User-Facing Cons / Limitations
- **NAT traversal may fail silently**: The manual explicitly warns that router/firewall settings can block direct P2P connections. The single TURN relay is a shared resource with no rate-limit documentation.
- **No access control**: Any user with the lobby address can join and draw without any authentication or permission system — there are no read-only viewer roles.
- **Undo is not fully conflict-safe**: The `UndoManager` header comment explicitly documents that simultaneous erasure of the same object by two clients can generate duplicate strokes after undo.
- **No reconnection on drop**: If a client loses the connection, there is no automatic reconnect mechanism visible in the code; the user must rejoin manually.
- **Single relay server**: The `default_p2p.json` lists one TURN server at `turn.infinipaint.com`; if that server goes down, users behind symmetric NATs cannot connect.

## Decision Guidance
Keep this feature — it is a central differentiator of Infinipaint compared to single-user drawing tools. Before widening the user base, address the access-control gap (at minimum, a host-settable password), document the TURN server capacity/SLA, and consider whether the undo conflict acknowledged in the codebase is acceptable for the target audience.

## Related Features
- [LayerManagement.md](LayerManagement.md) — layer tree is replicated across clients
- [Bookmarks.md](Bookmarks.md) — bookmark list is also a networked ordered structure
- [UndoRedo.md](UndoRedo.md) — undo has known multi-client collision edge cases
- [CanvasNavigation.md](CanvasNavigation.md) — camera jump uses `DrawCamera::smooth_move_to()`
