---
background: Black
foreground: White
border: Cyan1
borderStyle: rounded
pagination: true
paginationStyle: fraction
autoAdvance: 2000
---

# Auto-Advance Demo

---

## Global Timer

---

### Global Timer Active

This slide uses the global `autoAdvance: 2000` from frontmatter.

Each state (bullet reveal or slide) advances automatically after **2000ms**.

- Static bullet (visible immediately)
* Progressive bullet one (revealed on first tick)
* Progressive bullet two (revealed on second tick)

---

### Fast Transition

<!-- autoAdvance: 400 -->

Per-slide override: `<!-- autoAdvance: 400 -->`

This slide cycles at **400ms** — fast enough to simulate a fade or wipe effect.

Chain multiple slides like this to build animation sequences.

---

### Manual Advance Required

<!-- autoAdvance: 0 -->

Per-slide override: `<!-- autoAdvance: 0 -->`

Auto-advance is **disabled** on this slide.

Press any forward key to continue.
