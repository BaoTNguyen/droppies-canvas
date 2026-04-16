# Rich Text Editing

## Summary
Users can place text boxes anywhere on the infinite canvas using the Textbox tool, then type and style text inside them using an inline rich-text editor. Supported formatting includes bold, italic, underline, overline, strikethrough, per-character color, highlight color, font size, and font family selection. Paragraphs inside a text box can have independent alignment (left, center, right, justified) and text direction (LTR/RTL), enabling multilingual documents. Text boxes are canvas objects that participate in the same layer, selection, undo, and collaboration systems as drawn shapes.

## How It Works
Text layout and rendering is delegated to Skia's `skparagraph` module (`skia::textlayout::Paragraph`). The `RichText::TextBox` class wraps a list of `ParagraphData` structs, each owning a `std::unique_ptr<skia::textlayout::Paragraph>` and a `ParagraphStyleData` (alignment, direction). Inline style ranges are stored as a `TextStyleModContainer` — a vector of `PositionedTextStyleMod` pairs that map a `TextPosition` to a `TextStyleModifier::ModifierMap`. When text or styles change, `TextBox::rebuild()` reconstructs the Skia paragraphs from scratch. Cursor movement, selection, copy/cut/paste, and keyboard input are handled inside `TextBox` methods. The canvas component that wraps the text box is `TextBoxCanvasComponent`, and user interaction during editing is managed by `TextBoxEditTool`. The `TextBoxTool` creates new text boxes and immediately switches to the edit tool.

## Code Locations
| Role | File | Lines / Symbol |
|------|------|----------------|
| Core text layout engine | `infinipaint-0.4.2/src/RichText/TextBox.hpp` | `RichText::TextBox`, `TextData`, `TextPosition` |
| Text style modifiers | `infinipaint-0.4.2/src/RichText/TextStyleModifier.hpp` | `TextStyleModifier`, `DecorationTextStyleModifier`, `WeightTextStyleModifier`, `SlantTextStyleModifier`, `ColorTextStyleModifier`, `SizeTextStyleModifier`, `FontFamiliesTextStyleModifier` |
| Paragraph style (alignment/direction) | `infinipaint-0.4.2/src/RichText/ParagraphStyleData.hpp` | `ParagraphStyleData` |
| Canvas component wrapper | `infinipaint-0.4.2/src/CanvasComponents/TextBoxCanvasComponent.hpp` | `TextBoxCanvasComponent` |
| Placement tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/TextBoxTool.hpp` | `TextBoxTool` |
| Editing tool | `infinipaint-0.4.2/src/DrawingProgram/Tools/EditTools/TextBoxEditTool.hpp` | `TextBoxEditTool` |
| Font management | `infinipaint-0.4.2/src/FontData.hpp` | `FontData` |
| Formatting icons | `infinipaint-0.4.2/data/icons/RemixIcon/` | `bold.svg`, `italic.svg`, `underline.svg`, etc. |

## User-Facing Pros
- **Per-character style ranges**: Bold, italic, color, and size can be mixed within a single word or sentence rather than being restricted to whole text boxes, enabling typographically rich annotations.
- **RTL and mixed-direction support**: The `TextDirection` field per paragraph and the ICU library bundled in the project (`icudt77l-small.dat`) enable correct rendering of Arabic, Hebrew, and other right-to-left scripts.
- **Emoji rendering**: The bundled `NotoEmoji-VariableFont_wght.ttf` font and ICU grapheme-cluster handling ensure emoji display correctly and cursor movement skips them as single units.
- **Highlight color**: A dedicated `HighlightColorTextStyleModifier` provides text highlighting independent of the foreground color, useful for annotation workflows.
- **Collaborative editing**: Text box content and style data serialize over the network, so remote collaborators see typed text in near-real time.

## User-Facing Cons / Limitations
- **Rebuild-on-every-change cost**: `TextBox::rebuild()` reconstructs all Skia paragraphs from scratch whenever any text or style changes; for very long text boxes this may cause visible latency.
- **No spell check or autocorrect**: The editor processes raw keyboard input with no spell-check integration, which limits utility for prose note-taking.
- **Fixed tab width**: The tab stop width is hardcoded to 4 spaces (`unsigned tabWidth = 4`) in `TextBox` and cannot be configured by the user.
- **No text box linking/flow**: Text that overflows a text box has no way to flow into another box; each text box is an independent island with no chained-container concept.
- **Shift-to-square only makes squares**: Holding Shift during text box creation constrains to a square, but there is no aspect-ratio lock or golden-ratio helper for common note-card dimensions.

## Decision Guidance
Keep this feature. The Skia paragraph backend is robust and already handles the hardest parts (bidirectional text, font fallback, complex script shaping). The rebuild-on-every-change issue is the most actionable performance concern; consider incremental dirty-range tracking if users report lag in large text boxes. Spell check would require integrating an external library and is a reasonable future enhancement rather than a blocker.

## Related Features
- [BrushAndDrawingTools.md](BrushAndDrawingTools.md) — text boxes are canvas components placed alongside strokes
- [SelectionAndTransform.md](SelectionAndTransform.md) — text boxes can be selected, moved, and scaled
- [LayerManagement.md](LayerManagement.md) — text boxes reside in layers
- [UndoRedo.md](UndoRedo.md) — text edits push undo actions
