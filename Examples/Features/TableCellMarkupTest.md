---
border: rounded
foreground: white
---

# table cell markup

---

### the problem this fixes

before `ConvertTo-TableCell`, inline markdown in table cells rendered as raw text:

| cell content | before |
|--------------|--------|
| `**bold**` | `**bold**` |
| `` `code` `` | `` `code` `` |
| `[link](url)` | `[link](https://url)` |

the slides after this one show what renders now.

---

### bold and italic

| style | example | rendered |
|-------|---------|----------|
| bold | `**critical**` | **critical** |
| italic | `_optional_` | _optional_ |
| bold italic | `***both***` | ***both*** |
| mixed | plain **bold** plain | plain **bold** plain |

---

### inline code

cells with backtick spans should render code styling, and markdown inside the code span must not leak formatting:

| command | effect |
|---------|--------|
| `Get-Process` | lists processes |
| `**not bold**` | literal asterisks inside code |
| `[not a link](x)` | literal brackets inside code |

---

### links are clickable

in terminals with OSC 8 support (windows terminal, iterm2, ghostty, wezterm) links are clickable; elsewhere they render as plain display text:

| link markdown | renders as |
|---------------|------------|
| `[@jeffhicks](https://techhub.social/@JeffHicks)` | [@jeffhicks](https://techhub.social/@JeffHicks) |
| `[Deck repo](https://github.com/jakehildreth/Deck)` | [Deck repo](https://github.com/jakehildreth/Deck) |

---

### strikethrough and color

| kind | example |
|------|---------|
| strikethrough | ~~deprecated~~ replaced |
| html color | <green>online</green> / <red>offline</red> |

---

### leading markers become bullets

a leading `- ` or `* ` (marker + space) in a cell is a bullet and renders as `•`. data like `-5%` (no space) stays literal:

| metric | delta | note |
|--------|-------|------|
| cpu | - 5% | bullet |
| memory | * 12% | bullet |
| disk | -5% | literal, no space |

---

### everything at once

| endpoint | status | latency | notes |
|----------|--------|---------|-------|
| `/api/users` | <green>200</green> | `42ms` | **healthy** |
| `/api/orders` | <yellow>429</yellow> | `1.2s` | _rate limited_ |
| `/api/legacy` | ~~<red>500</red>~~ | - n/a | see [runbook](https://wiki.internal/runbook) |
