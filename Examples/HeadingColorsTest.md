---
background: black
foreground: white
border: magenta1
h1: PressStart2P
h2: Silkscreen
h3: Micro5-Regular
h1Color: cyan
h2Color: yellow
h3Color: green
pagination: true
---

# <grey7>Title with Color Tag</grey7>

---

## <yellow>Section with Color</yellow>

---

### <green>Content Header with Color</green>

Body text remains in default foreground color.

You can use either format:
- `<colorname>text</colorname>`
- `<span style="color:colorname">text</span>`

---

# <red>Red Title</red>

---

## <magenta1>Magenta Section</magenta1>

---

### <span style="color:blue">Blue Content Header</span>

Color priority:
1. Inline color tags (highest)
2. h1Color/h2Color/h3Color settings
3. foreground setting (fallback)

---

# Title Using h1Color Setting

---

## Section Using h2Color Setting

---

### Content Using h3Color Setting

This header has no inline tags, so it uses the h3Color (green) from frontmatter.
