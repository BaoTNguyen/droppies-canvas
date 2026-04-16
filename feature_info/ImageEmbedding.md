# Image and File Embedding

## Summary
Users can add images and arbitrary files to the canvas by dragging and dropping them onto the window, dragging a URL onto the window, or using the Edit tool to interact with already-placed files. Supported image formats for display include PNG, JPEG, WEBP, and others decodable by Skia's codec library. Non-image files are also accepted and stored as embedded binary resources; clicking them with the Edit tool downloads the file back to the user's computer. Images render as canvas objects that can be selected, moved, scaled, and rotated like any other canvas component. All embedded resource data travels with the `.infpnt` file and is shared with collaborators over the network.

## How It Works
When a file is dropped, `DrawingProgram::add_file_to_canvas_by_path()` (or `add_file_to_canvas_by_data()` for in-memory data) creates an `ImageCanvasComponent` or a generic file component and calls `ResourceManager::add_resource_file()` to store the binary blob. The `ResourceManager` keeps a `std::vector<NetworkingObjects::NetObjOwnerPtr<ResourceData>>` where each `ResourceData` holds the file name and a `std::shared_ptr<std::string>` for the binary content. Network transmission uses the same `NetObj` callback system as other world objects, so collaborating clients receive the resource data automatically. For rendering, `ResourceManager::get_display_data()` returns a `ResourceDisplay*` (subclassed as `ImageResourceDisplay` or `FileResourceDisplay` or `SvgResourceDisplay`) that caches the decoded Skia image and draws it. URL drops kick off a `FileDownloader` task tracked in `droppedDownloadingFiles`; a progress indicator is shown while the asset loads.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Resource storage | `infinipaint-0.4.2/src/ResourceManager.hpp` | `ResourceManager`, `ResourceData`, `add_resource_file()`, `add_resource()` |
| Image display renderer | `infinipaint-0.4.2/src/ResourceDisplay/ImageResourceDisplay.hpp` | `ImageResourceDisplay` |
| File display (non-image) | `infinipaint-0.4.2/src/ResourceDisplay/FileResourceDisplay.hpp` | `FileResourceDisplay` |
| SVG display renderer | `infinipaint-0.4.2/src/ResourceDisplay/SvgResourceDisplay.hpp` | `SvgResourceDisplay` |
| Base resource display | `infinipaint-0.4.2/src/ResourceDisplay/ResourceDisplay.hpp` | `ResourceDisplay` |
| Image canvas component | `infinipaint-0.4.2/src/CanvasComponents/ImageCanvasComponent.hpp` | `ImageCanvasComponent` |
| Drop handling in drawing program | `infinipaint-0.4.2/src/DrawingProgram/DrawingProgram.hpp` | `add_file_to_canvas_by_path()`, `update_downloading_dropped_files()`, `droppedDownloadingFiles` |
| Supported decoders | `infinipaint-0.4.2/src/ResourceManager.hpp` | `ResourceManager::decoders` (5-element array) |
| Download helper | `infinipaint-0.4.2/src/Helpers/FileDownloader.hpp` | `FileDownloader`, `DownloadData` |
| Edit tool file download | `infinipaint-0.4.2/src/DrawingProgram/Tools/EditTools/ImageEditTool.hpp` | `ImageEditTool` |

## User-Facing Pros
- **Fully embedded resources**: Images and files are stored inside the `.infpnt` archive as binary blobs, so the canvas is portable — sharing the file requires no separate asset folder.
- **URL drop with live progress**: Dropping a web URL triggers a background download with a visible progress indicator; users do not have to manually download and re-drop the file.
- **SVG rendering**: The `SvgResourceDisplay` renders SVG resources as resolution-independent vector graphics on the canvas, preserving quality at any zoom level.
- **File round-trip**: Non-image files dropped onto the canvas retain their original binary content and can be re-downloaded via the Edit tool click, making the canvas usable as a lightweight file-sharing board.
- **Collaborative resource sync**: Resources are transmitted via the `NetObj` system to all connected clients, so remote collaborators automatically receive embedded images without manual transfer.

## User-Facing Cons / Limitations
- **No image editing**: Once placed, an image cannot be cropped, recolored, or adjusted within the application — it is a static embedded resource.
- **File size is uncapped**: There is no visible file-size check before a resource is embedded; embedding a large video file would bloat the `.infpnt` archive and degrade network sync performance for collaborators.
- **Mipmap levels are heuristic**: `DrawData::mipMapLevelOne` and `mipMapLevelTwo` thresholds are computed heuristically; very large embedded images at intermediate zoom levels may render at suboptimal quality.
- **No deduplication guarantee**: If the same image file is dropped twice, the code path creates two `ResourceData` entries; the `ResourceManager` API does not appear to check for existing identical blobs by content hash.

## Decision Guidance
Keep this feature. Embedded resources are a key part of the "infinite whiteboard" use case — users expect to drag reference images onto a canvas and have them stay there permanently. Add a file-size warning threshold before embedding (e.g., warn at >10 MB) to prevent accidental performance degradation. Content-hash deduplication in `add_resource_file()` would reduce file size for workflows that frequently copy-paste the same image.

## Related Features
- [FileManagement.md](FileManagement.md) — resources are serialized into the `.infpnt` archive
- [OnlineCollaboration.md](OnlineCollaboration.md) — resources are transmitted to collaborators via NetObj callbacks
- [SelectionAndTransform.md](SelectionAndTransform.md) — image components can be selected, moved, and scaled
- [CanvasExport.md](CanvasExport.md) — embedded images are composited into screenshot exports
