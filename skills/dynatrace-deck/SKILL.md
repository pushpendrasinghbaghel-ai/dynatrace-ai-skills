---
name: dynatrace-deck
description: Build dark, brand-compliant Dynatrace PowerPoint decks (.pptx) from the corporate template ΓÇö customer solution overviews, RFP responses, POC readouts, architecture and pitch decks. Use this whenever someone asks for a Dynatrace-branded deck, slides, presentation or "PPT" for a customer or internal audience, wants an existing deck rebranded or made brand-compliant, mentions the Dynatrace corporate template / DT Flow / Blank_black layout, or asks for a dense dark "consulting style" deck with stat tiles, bordered panels and requirement-mapping tables. Also use it when a deck must carry the Dynatrace logo lockup, footer and slide numbers correctly, or when a previously generated deck opens with wrong colours, missing logo, or overflowing text.
argument-hint: "Audience, deck goal, and source content location, e.g. 'Acme CTO, platform modernization POC readout, use requirements in docs/rfp.md'"
---

# Dynatrace branded deck builder

Generates dark, information-dense PowerPoint decks that inherit the real Dynatrace
theme ΓÇö DT Flow typography, the official logo lockup, footer and slide numbers ΓÇö
by building on the corporate template rather than imitating it.

The visual language is deliberately dense: a numbered eyebrow, one declarative
headline, a short deck paragraph, then bordered panels of arrow bullets, tables
with status badges, and a strip of four stat tiles. It reads like a consulting
readout, not a marketing deck.

## Authoritative references

- Corporate template asset described in this skill (`TPLT_Corporate_PPT_2026.potx`).
- Local design reference: [DESIGN_SYSTEM.md](./references/DESIGN_SYSTEM.md).
- Local implementation reference: [dtdeck.py](./scripts/dtdeck.py) and [brand.py](./scripts/brand.py).

## Grounding notes

This skill is grounded in Dynatrace brand/template assets and the validated local builder scripts in this repo rather than public product documentation.

## When to Use

- Build a new Dynatrace-branded customer or internal presentation.
- Rebrand an existing deck to Dynatrace theme and logo/footer conventions.
- Fix visual issues such as text overflow, wrong colors, or layout collisions before delivery.

## Before you build: get the content right

Slide mechanics are the easy part. Research, read source documents, and settle the
argument **first**. A beautifully typeset deck with weak content is a worse outcome
than plain slides with the right facts, and restructuring after the build is
expensive. Only start writing the build script once you know what each slide says.

Two habits that repeatedly matter:

- **Ground every claim in a source.** If the deck answers an RFP, quote the
  requirement language. If a number is an assumption rather than a measurement,
  label it as one on the slide. Sales decks get read adversarially.
- **Don't import content wholesale from another customer's deck.** Reference decks
  are useful for *pattern*, not for prose. Lifting slides drags in claims that were
  true for someone else, plus their confidential data.

## Setup: the template asset

Everything brand-related is sourced from the corporate template, which is **not
bundled** with this skill (it is Dynatrace-internal, and this skill is intended to
be shareable). Place it at:

```
assets/TPLT_Corporate_PPT_2026.potx
```

`scripts/brand.py` locates it automatically; it also accepts `--template`. If it is
missing, the script fails with instructions rather than silently producing an
unbranded deck. Keep `assets/*.potx` out of version control.

## Workflow

1. **Write a build script** that imports `scripts/dtdeck.py` and lays out the slides.
   Start from `scripts/example_deck.py` ΓÇö it exercises every component.
2. **Run it** to produce a raw `.pptx` built on the template's `Blank_black` layout.
3. **Run `scripts/brand.py`** to apply branding and slim the package.
4. **Render and actually look at it** (see Verify below). This step is not optional.
5. **Fix overflow**, re-render, then deliver.

```bash
python3 my_deck.py                          # -> /tmp/raw.pptx
python3 scripts/brand.py /tmp/raw.pptx \
    --out ~/Desktop/Customer_Deck.pptx \
    --footer "Acme Corp  ┬╖  Platform Modernization"
```

## Components

`dtdeck.py` gives you a page grid (left margin 0.88", content width 11.71", so the
right edge lands at 12.59") and these builders. Full signatures and the design
tokens are in `references/DESIGN_SYSTEM.md` ΓÇö read it before your first deck.

| Component | Use for |
|---|---|
| `eyebrow(s, "01", "Section name")` | Blue mono kicker, top of slide |
| `headline(s, "One declarative sentence")` | The claim the slide makes |
| `deck(s, "Two or three sentencesΓÇª")` | Context under the headline |
| `block(s, top, title, badge, colour, bullets)` | Bordered panel of arrow bullets. **Auto-heights.** Returns its bottom edge |
| `tiles(s, [(label, value, caption, colour)] * 4)` | Four stat tiles |
| `table(s, headers, widths, rows)` | Grid with optional badge cells |
| `footnote(s, "Lead-in:", "ΓÇª")` | Caveat / source line |

Chain blocks by feeding the returned bottom edge into the next `top`:

```python
y = block(s, Inches(1.95), 'Ingest everything', 'SCALE', BLUE, [
    'Bullet text.',
    ('Bold lead-in. ', 'then normal continuation.'),
])
y = block(s, y + Inches(0.18), 'Protect and segregate', 'COMPLIANCE', LIME, [...])
```

A bullet is either a string, or a `(bold, normal)` tuple when you want a lead-in
phrase emphasised.

## Verify by looking at the slides

LibreOffice is far more forgiving than PowerPoint, and malformed shape XML fails
*silently* ΓÇö it renders correctly in your check and wrong on the customer's screen.
So render to images and inspect them:

```bash
soffice --headless --convert-to pdf --outdir /tmp/r deck.pptx
pdftoppm -png -r 100 /tmp/r/deck.pdf /tmp/r/pg
# then read the PNGs ΓÇö tile them into a contact sheet for a fast scan
```

Look specifically for text overrunning a panel's bottom border, footnotes colliding
with the footer band, badges overlapping panel titles, and any shape that came out
teal (see Pitfalls). Checking a colour numerically beats squinting:

```python
from PIL import Image
im = Image.open('/tmp/r/pg-01.png').convert('RGB')
print(im.getpixel((200, 600)))   # a panel fill should be near-black, not (73,194,179)
```

## Pitfalls that have actually bitten

**Teal panels in PowerPoint, correct in LibreOffice.** In DrawingML, `spPr` children
are order-sensitive: fill and line must precede `effectLst`. Appending a fill after
the effects element makes PowerPoint discard it and fall back to the shape's
`<p:style>` theme reference ΓÇö which is `accent1`, a teal. `dtdeck.panel()` inserts
fills at the correct position and strips `<p:style>`; if you hand-roll a shape, do
the same.

**Text overflowing panels.** `block()` estimates wrapped line count from the panel
width, so always pass `width=` for narrow columns ΓÇö otherwise it sizes for the full
grid and clips. Two-column layouts: build both columns, then start the next row from
`max(left_bottom, right_bottom)`.

**Content colliding with the footer.** The footer and slide number sit at ~7.20".
Keep everything above ~7.10". A four-tile strip is 1.14" tall, so `top=5.95` is the
practical floor.

**PowerPoint's 259-character path limit.** Deep session/scratch directories blow
past it and PowerPoint refuses to open the file with a misleading path error while
Preview opens it fine (Protected View copies the file to a temp path first, adding
overhead beyond the visible path). Deliver to a short path such as the Desktop.

**Other customers' branding riding along.** Corporate templates carry 60+ layouts,
some customised for named accounts. `brand.py` keeps only the layout in use and
sweeps orphaned media ΓÇö this removes stray logos and typically cuts the file from
~14 MB to ~2 MB. Worth confirming no unexpected customer name survives:

```bash
python3 -c "
from pptx import Presentation
p = Presentation('deck.pptx')
print(' '.join(sh.text_frame.text for s in p.slides for sh in s.shapes if sh.has_text_frame))"
```

## Reference decks

`references/DESIGN_SYSTEM.md` documents the layout geometry, colour ramp, type
scale and slide archetypes this skill reproduces, distilled from a Dynatrace +
Bindplane customer readout deck. The pattern is captured in prose and code; no
customer deck is bundled, and none should be ΓÇö those files carry named individuals,
POC results and account data that must not travel into another engagement.

If you are handed a reference deck to match, extract the *pattern* from it ΓÇö
geometry, palette, slide archetypes ΓÇö and leave its content behind.
