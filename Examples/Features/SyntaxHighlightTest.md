---
background: Black
foreground: White
border: Cyan
h1: PressStart2P
h2: Silkscreen
pagination: true
paginationStyle: dots
---

# Syntax Highlighting

---

## Code Blocks with TextMate

---

### PowerShell

```powershell
function Get-DiskReport {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($computer in $ComputerName) {
            Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $computer |
                Where-Object DriveType -eq 3 |
                Select-Object @{N='Computer';E={$computer}},
                              DeviceID,
                              @{N='SizeGB';E={[math]::Round($_.Size / 1GB, 2)}},
                              @{N='FreeGB';E={[math]::Round($_.FreeSpace / 1GB, 2)}}
        }
    }
}
```

---

### Python

```python
from dataclasses import dataclass
from pathlib import Path
import json

@dataclass
class Config:
    host: str = "localhost"
    port: int = 8080
    debug: bool = False

    @classmethod
    def from_file(cls, path: Path) -> "Config":
        with open(path) as f:
            data = json.load(f)
        return cls(**data)

    def base_url(self) -> str:
        scheme = "http" if self.debug else "https"
        return f"{scheme}://{self.host}:{self.port}"
```

---

### C#

```csharp
using System.Linq;

public record Person(string Name, int Age);

public static class Extensions
{
    public static IEnumerable<Person> Adults(
        this IEnumerable<Person> people) =>
        people.Where(p => p.Age >= 18)
              .OrderBy(p => p.Name);
}
```

---

### Side-by-Side Comparison

```javascript
async function fetchUsers(api) {
    const response = await fetch(api);
    const users = await response.json();
    return users.filter(u => u.active);
}
```

|||

```rust
async fn fetch_users(api: &str)
    -> Result<Vec<User>>
{
    let response = reqwest::get(api).await?;
    let users: Vec<User> =
        response.json().await?;
    Ok(users.into_iter()
        .filter(|u| u.active)
        .collect())
}
```

---

### SQL and YAML

```sql
SELECT
    d.name        AS department,
    COUNT(e.id)   AS headcount,
    AVG(e.salary) AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE e.hire_date >= '2025-01-01'
GROUP BY d.name
HAVING COUNT(e.id) > 5
ORDER BY avg_salary DESC;
```

|||

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - api
  api:
    build: ./backend
    environment:
      DATABASE_URL: postgres://db:5432/app
```

---

### Fallback Behavior

- Unsupported languages render as plain monochrome text in a rounded panel
- The language name still appears as the panel header
- No errors — graceful degradation

```brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.
>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
```

---

## 60+ Languages Supported

---

### Highlight Reel

- PowerShell, Python, C#, JavaScript, TypeScript
- Rust, Go, Java, Swift, Ruby, Lua
- SQL, YAML, JSON, XML, HTML, CSS
- Dockerfile, Makefile, Shell Script
- And many more via TextMate grammars

Use the language identifier after the opening fence:

````markdown
```powershell
# your code here
```
````

---

## That's TextMate!
