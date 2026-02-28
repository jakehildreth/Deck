### 2026.2.28.2
- Add New-TableRenderable private helper to render markdown tables via Format-SpectreTable
- Add table detection regex to ContentSlide, ImageSlide, and ConvertTo-CodeBlockSegments parsers
- Add table rendering dispatch to ContentSlide, ImageSlide, and MultiColumnSlide foreach loops
- Tables support left, center, and right column alignment via markdown separator syntax

### 2026.2.28
- Replace PwshSpectreConsole direct dependency with TextMate for syntax-highlighted code blocks
- Add New-CodeBlockPanel private helper to DRY up triplicated code block rendering
- Code blocks with supported languages now render with full syntax highlighting via Format-TextMate
- Unsupported languages gracefully fall back to plain monochrome rendering
- Fix duplicate ConvertTo-CodeBlockSegments call in Show-MultiColumnSlide

### 1.0.0
- Initial release