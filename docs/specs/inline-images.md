# Inline Images — Spec

How an author places an image inline with flowing slide content, and how Deck renders it.

This is the decision record for map [#42](https://github.com/jakehildreth/Deck/issues/42), assembled from tickets [#43](https://github.com/jakehildreth/Deck/issues/43) (syntax), [#44](https://github.com/jakehildreth/Deck/issues/44) (sizing/alignment), [#45](https://github.com/jakehildreth/Deck/issues/45) (bullets and Strict), and [#46](https://github.com/jakehildreth/Deck/issues/46) (multiple images). Implementation is a separate effort; this document is what it implements.

---

## Syntax

Two author-facing syntaxes converge on one internal representation (IR).

**Marp-style keywords in alt text** — keywords first, remaining alt text becomes the caption:

```markdown
![right w:40%](path.png)
![center w:30% A figure caption](path.png)
```

**HTML `<img>` tag:**

```markdown
<img src="path.png" align="right" width="40%">
<img src="path.png" width="30%" alt="A figure caption">
```

### Trigger rule (backwards compatible)

Alt-text keywords **or** an `<img>` tag = an inline image block. A bare `![alt](path)` with no keywords, with text on the slide, still means the **60/40 image slide** — unchanged.

## Internal representation

Every inline image parses to one record:

| Field | Values | Default |
|-------|--------|---------|
| `path` | local path or web URL | — (required) |
| `width` | cells or % of content width | 100% of content width |
| `align` | `left` / `right` / `center` / none | none (full-width block) |
| `caption` | free text | none |

## Sizing and alignment

**Width.** `w:40%` / `width="40%"` = percent of the slide's **content width** (panel width minus padding). A bare integer (`w:24` / `width="24"`) = absolute terminal cells. Default: 100% of content width.


> **Naming note.** The `caption` field is whatever alt text remains after the sizing/alignment keywords are stripped. Deck renders it dim beneath the image. This deliberately reuses the Markdown/HTML *alt* slot as a *visible caption*, not as accessibility (screen-reader) text. That is safe because Deck's only output surface is the terminal, which has no accessibility tree. **If PDF/PPTX export is ever added**, those formats carry a real accessibility tree and `alt` must be true alternative text — at that point caption and alt must be split into separate syntax. Until then, alt-as-caption is the accepted design.

**Alignment.**

- `left` / `right` = **float**: an explicit-width Grid; text wraps in the text column beside the image; full-width flow resumes below.
- `center` = **block**, centered horizontally. A caption, when present, renders dim beneath.
- **none** (default) = full-width block; centering is moot at full width. To get a centered figure the author writes an explicit reduced width (e.g. `![center w:30% "caption"](img.png)`).

**Float at full width.** A float at 100% width leaves no text column, so the renderer ignores `align` and renders a plain block. Silently — no warning, no Strict error.

## Progressive bullets

An inline image is a **static block**, the same class as a code block: visible on slide entry, never filtered by bullet reveal, and it does not move as `*` bullets appear.

Reveal stability comes from the existing rules: hidden progressive bullets render as blank placeholder lines, and slide height is measured from the unfiltered (full) content. For a floated image the float region's height is pinned to `MAX(image, text)` measured at full content, so a bullet appearing in the wrap column does not reflow the image.

## Strict validation

`Show-Deck -Strict` treats an inline image under the content-slide branch, extended with the two checks image slides already get:

1. **Existence** — every inline image path is checked on disk, resolved against the markdown file's directory, skipping web URLs and images inside code fences. A missing inline image is a **hard error**, consistent with the 60/40 image slide.
2. **Height budget** — the image's rendered height counts toward the slide's height limit. The computation is **layout-aware**: a float row is `MAX(image, text)`; a centered/flow block is `text + image` (additive). Layout-aware, not worst-case, so Strict's verdict matches what the author sees.

## Multiple images

Any number per slide. Each is a block; blocks flow top-to-bottom in source order.

- **No align** — images stack vertically in source order.
- **Float left/right** — each float claims its own horizontal band on its side. Two right-floats stack on the right, one above the other, text wrapping beside each. Floats do **not** pack side-by-side into one band; a second float starts a new band below the first.

**Side-by-side images** are out of scope for inline images. The existing multi-column slide (`|||`) is the answer for that layout.

## Migration

`{width=N}` on the 60/40 image slide is **deprecated** and removed. Migrate to the width keyword / attribute syntax:

```
![alt](path){width=80}      →    ![alt w:80](path)
                                or    <img src="path" width="80">
```

A bare `![alt](path)` + text with no keywords still means the 60/40 image slide, unchanged. After removal, a legacy `{width=N}` renders as literal text beside the image rather than constraining width — a breaking change, flagged in the changelog.

## Prototypes

- `prototype/inline-images` — rendering variants for syntax and layout (ticket #43).
- `prototype/strict-image-height` — Strict height math for float vs block (ticket #45).
