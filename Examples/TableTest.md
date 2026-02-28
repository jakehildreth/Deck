---
border: rounded
foreground: white
---

# table smoke test

---

### basic table

| name   | role      | status |
|--------|-----------|--------|
| alice  | engineer  | active |
| bob    | designer  | away   |
| carol  | manager   | active |

---

### alignment test

| left   | center | right |
|:-------|:------:|------:|
| aaa    | bbb    | ccc   |
| dddddd | ee     | f     |

---

### no-alignment separator

| col a | col b |
|-------|-------|
| defaults to left | should also be left |

---

### table + text mixed

some prose above the table.

| item  | count |
|-------|-------|
| alpha | 3     |
| beta  | 7     |

and more text below it.

---

### table + code block

here's a table:

| flag   | meaning     |
|--------|-------------|
| -Force | skip confirm |
| -WhatIf | dry run    |

and here's code:

```powershell
Get-Process | Select-Object -First 5
```