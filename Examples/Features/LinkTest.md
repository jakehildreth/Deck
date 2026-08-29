---
border: rounded
foreground: white
---

# clickable links & strikethrough

---

### clickable links (OSC 8)

markdown links become clickable hyperlinks in terminals that support OSC 8
(windows terminal, iterm2, ghostty, wezterm). elsewhere they degrade to plain text.

- [Deck repo](https://github.com/jakehildreth/Deck)
- [Spectre.Console](https://spectreconsole.net/)
- inline: see the [docs](https://example.com/docs) for details.

---

### links in table cells

links work in cells too:

| resource | link |
|----------|------|
| repo | [Deck](https://github.com/jakehildreth/Deck) |
| social | [@jeffhicks](https://techhub.social/@JeffHicks) |

---

### strikethrough warning

~~this text is struck through.~~

if the terminal is not known to support strikethrough, deck warns once per
session. detection is a heuristic on WT_SESSION / TERM_PROGRAM / TERM.

override detection with `DECK_STRIKETHROUGH=true` or `false`.

---

### both bullet styles

- dash bullet
* asterisk bullet
- `-5%` (no space) stays literal data
