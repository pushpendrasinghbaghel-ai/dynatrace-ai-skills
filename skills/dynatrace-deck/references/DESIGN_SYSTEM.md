# Design system

The visual language reproduced by `dtdeck.py`, distilled from a Dynatrace customer
readout deck built on the corporate template. Everything here is pattern and
measurement ΓÇö no customer content.

## Contents

- [Canvas and grid](#canvas-and-grid)
- [Colour](#colour)
- [Typography](#typography)
- [Components](#components)
- [Slide archetypes](#slide-archetypes)
- [Writing the words](#writing-the-words)
- [Rendering notes](#rendering-notes)

## Canvas and grid

| | inches |
|---|---|
| Slide | 13.333 ├ù 7.5 (16:9) |
| Left margin | 0.88 |
| Content width | 11.71 |
| Right edge | 12.59 |
| Eyebrow baseline | 0.24 |
| Headline | 0.72 |
| Deck paragraph | 1.30 |
| Body starts | ~1.90 |
| Footer band | 7.20 ΓÇö keep content above ~7.10 |

Everything is left-aligned to 0.88 and right-aligned to 12.59. The logo, panels,
tables and tiles all share those two edges; that shared alignment is most of what
makes the deck feel engineered rather than assembled.

Four tiles across: x = 0.88, 3.83, 6.79, 9.75, each 2.83 wide, 1.14 tall.
Two columns: 5.72 wide at x = 0.88 and 7.07.

## Colour

Background is black. Panels are a near-black gradient (`#131B30` ΓåÆ `#0E1424`)
with a thin iridescent border (cyan ΓåÆ blue ΓåÆ magenta ΓåÆ purple).

| Token | Hex | Use |
|---|---|---|
| `TXT` | `EAF0FF` | Headlines, panel titles, emphasised lead-ins |
| `TXT2` | `9DB0D6` | Body copy, bullets, tile captions |
| `LBL` | `6F84AE` | Mono labels, table headers, footnote body |
| `LIME` | `BDDF28` | Accent ΓÇö compliance, standards, "what you gain" |
| `BLUE` | `1497FF` | Accent ΓÇö scale, platform, arrow glyphs, eyebrows |
| `PURP` | `B23BE4` | Accent ΓÇö governance, operations |
| `CYAN` | `54C8E9` | Accent ΓÇö storage, continuity |
| `DARK` | `0A0E1A` | Text on a bright badge |

Accents carry meaning, not decoration. Pick one per panel and stay consistent
across the deck ΓÇö if lime means "compliance" on slide 4 it should not mean
"performance" on slide 9. Four accents is the ceiling; more and the eye stops
reading them as categories.

The theme's `accent1` is a teal (`#49C2B3`). You should never see it. If a shape
comes out teal, its explicit fill was rejected and PowerPoint fell back to the
theme ΓÇö see Rendering notes.

## Typography

| Role | Font | Size | Colour |
|---|---|---|---|
| Cover title | DTFlow-Medium bold | 44 | TXT / LBL for line 2 |
| Headline | DTFlow-Medium bold | 26 | TXT |
| Panel title | DTFlow-Medium bold | 16 | TXT |
| Deck paragraph | DTFlow-Light | 12 | TXT2 |
| Bullets | DTFlow-Light | 11 | TXT2 |
| Table cells | DTFlow-Light | 10 | TXT2 |
| Eyebrow | Consolas bold, `spc=240` | 11 | BLUE |
| Tile label / table header | Consolas, `spc=150` | 8.5 | LBL |
| Badge | Consolas, `spc=80` | 8 | DARK on accent |
| Tile value | DTFlow-Medium bold | 26 / 17 / 13 by length | accent |
| Footnote | DTFlow-Medium bold lead + Light | 10 | TXT2 / LBL |

Two families only. The wide-tracked mono is what gives the deck its instrument-panel
feel ΓÇö use it for labels and never for prose.

## Components

**Eyebrow** ΓÇö `01 ┬╖ SECTION NAME`, blue, mono, wide-tracked. Numbering the sections
lets people navigate verbally in a meeting ("go back to 04").

**Headline** ΓÇö one declarative sentence stating the slide's claim, not a topic
label. "Every source in scope, one repeatable pattern" beats "Ingestion coverage".
Keep it to one line at 26pt; if it wraps it collides with the deck paragraph.

**Deck paragraph** ΓÇö two or three sentences of context. This is where nuance and
caveats live so the panels can stay terse.

**Panel** (`block`) ΓÇö a titled group of arrow bullets with a badge in the top-right
corner. Auto-heights from its content. Three or four bullets is right; at six the
panel stops being scannable and should split.

**Badge** ΓÇö one word, uppercase, categorising the panel (`SCALE`, `COMPLIANCE`,
`EDGE`, `DOMAIN`). Right-aligned so it never collides with a long title.

**Tiles** ΓÇö four stat cards. Best used for figures a reader should carry away.
Keep captions to one line; two lines fit but crowd.

**Table** ΓÇö for requirement mapping and coverage matrices. Status pills in a narrow
second column read fast. Give `rowh >= 0.55` if any cell wraps.

**Footnote** ΓÇö bold lead-in plus grey body, for the caveat that keeps the slide
honest ("these are planning assumptions, not measurements").

## Slide archetypes

1. **Cover** ΓÇö eyebrow, two-line title (second line in `LBL`), positioning
   paragraph, four tiles establishing scale.
2. **Mandate** ΓÇö what the customer asked for. Three stacked panels, one per
   requirement cluster, closing with a footnote that frames the tension between them.
3. **Architecture** ΓÇö a full-width diagram with a one-line intro and a footnote
   qualifying any assumed numbers. Import the diagram as an image; do not rebuild
   it in shapes.
4. **Capability** ΓÇö two panels plus tiles. The workhorse slide.
5. **Coverage table** ΓÇö requirement in column one, status pill in column two,
   how it is delivered in column three. This is the slide procurement reads.
6. **Domains / quadrant** ΓÇö two rows of two panels for four parallel themes.
7. **Closing** ΓÇö what changes, what stays, plus tiles restating the headline numbers.

## Writing the words

- Panels state facts; the deck paragraph carries nuance.
- Mark assumptions as assumptions on the slide, not in the speaker notes.
- Prefer the customer's own vocabulary ΓÇö quote requirement language verbatim so
  reviewers can match it to their document.
- Sentence case throughout. Reserve uppercase for eyebrows, badges and mono labels.
- Avoid claiming validation that has not happened. "Addressed" and "In scope"
  describe a design; "Validated" describes a test you actually ran.

## Rendering notes

**Shape XML is order-sensitive.** In `spPr`, fill and line must come before
`effectLst`. Append a fill after the effects element and PowerPoint silently drops
it and falls back to the shape's `<p:style>` theme reference ΓÇö turning panels teal ΓÇö
while LibreOffice renders it correctly. `dtdeck.panel()` inserts positionally and
strips `<p:style>`. This is the single most expensive mistake in this pipeline
because your own render looks fine.

**Always view the output as images.** Convert to PDF, rasterise, and read the
slides. Tiling them into one contact sheet makes overflow obvious at a glance.

**Line-count estimation is approximate.** `block()` derives wrapping from panel
width; unusually long words or narrow columns can still overrun. The render is the
check.

**Fonts.** DT Flow must be installed for exact metrics. Without it PowerPoint
substitutes and text runs wider than the estimate ΓÇö expect some overflow on
machines that lack the corporate fonts.
