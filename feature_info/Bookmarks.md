# Bookmarks

## Summary
Users can save named camera positions (bookmarks) to quickly return to important areas of the canvas. Bookmarks are displayed in a collapsible panel and can be organized into named folders via drag-and-drop. Double-clicking a bookmark (or pressing its arrow icon) animates the camera to the saved position. Multiple bookmarks can be selected at once for bulk moves or deletion. Bookmarks are part of the shared canvas state and are synchronized to all collaborators in real time.

## How It Works
The bookmark tree mirrors the layer tree architecture: a `BookmarkManager` owns a root `NetworkingObjects::NetObjOwnerPtr<BookmarkListItem>` which is an ordered list structure. Each `BookmarkListItem` stores either a bookmark (a `CoordSpaceHelper` camera snapshot plus a name) or a folder containing further items. The GUI is implemented with `GUIStuff::TreeListing`, a reusable tree widget that handles multi-select (`Shift+click`, `Ctrl+click`), drag-and-drop reordering, and expand/collapse. Camera jumps call `DrawCamera::smooth_move_to()`. Serialization uses `cereal::PortableBinaryOutputArchive` for file persistence and the `NetObj*` framework for network sync, matching the same pattern as layers.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Bookmark manager | `infinipaint-0.4.2/src/Bookmarks/BookmarkManager.hpp` | `BookmarkManager`, `bookmarkListRoot` |
| Bookmark list item (node/leaf) | `infinipaint-0.4.2/src/Bookmarks/BookmarkListItem.hpp` | `BookmarkListItem` |
| Tree listing GUI widget | `infinipaint-0.4.2/src/GUIStuff/Elements/TreeListing.hpp` | `GUIStuff::TreeListing` |
| Toolbar menu entry | `infinipaint-0.4.2/src/Toolbar.hpp` | `Toolbar::bookmark_menu()`, `bookmarkMenuPopupOpen` |
| Camera jump trigger | `infinipaint-0.4.2/src/DrawCamera.hpp` | `DrawCamera::smooth_move_to()` |
| Camera snapshot type | `infinipaint-0.4.2/src/CoordSpaceHelper.hpp` | `CoordSpaceHelper` |

## User-Facing Pros
- **Folder organization**: Bookmarks can be grouped into named folders, which is important for canvases that span many topics or sections — users do not have to scroll through a flat, unorganized list.
- **Animated jump with easing**: Navigation to a bookmark animates over a configurable duration and easing curve rather than teleporting, preserving the user's spatial orientation.
- **Multi-select and bulk reorder**: Shift-click and Ctrl-click selection combined with drag-and-drop lets users reorganize bookmarks in bulk without doing it one at a time.
- **Collaborative sync**: All connected clients see the same bookmark list; a host can set up named waypoints (e.g., "Task A", "Reference Image") for the whole team.

## User-Facing Cons / Limitations
- **No thumbnail preview**: Bookmarks show only a text name; there is no screenshot or minimap thumbnail of what the camera will see at that position, making it hard to identify the right bookmark in a long list.
- **Zoom level is saved but rotation is implicit**: The `CoordSpaceHelper` snapshot includes rotation, but the bookmark creation UI does not display the current rotation angle, so users may not know the canvas will land in a rotated state when they jump to a bookmark.
- **No keyboard shortcut for individual bookmarks**: There is no mechanism to assign a hotkey (e.g., Ctrl+1 through Ctrl+9) to jump to a specific bookmark; users must open the panel and double-click.
- **Deletion requires explicit selection**: Clicking a bookmark once selects it, then the trash icon removes it — there is no right-click context menu shortcut.

## Decision Guidance
Keep this feature. It is essential for large-canvas productivity and the networked sync is valuable in collaborative sessions. Thumbnail previews would be the highest-impact improvement and could be implemented by rendering a small offscreen surface at the bookmark's `CoordSpaceHelper` position.

## Related Features
- [CanvasNavigation.md](CanvasNavigation.md) — bookmark jumps use `DrawCamera::smooth_move_to()`
- [OnlineCollaboration.md](OnlineCollaboration.md) — bookmark state is synchronized over the network
