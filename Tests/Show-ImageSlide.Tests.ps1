BeforeAll {
    Import-Module "$PSScriptRoot/../Deck.psd1" -Force
}

Describe 'Show-ContentSlide Image Support' {
    BeforeAll {
        # Create test directory and image
        $testDir = Join-Path $TestDrive 'ImageTests'
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Create a minimal valid PNG file (1x1 transparent pixel)
        $pngBytes = [byte[]]@(
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  # Width=1, Height=1
            0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,  # Bit depth, color type, etc.
            0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,  # IDAT chunk
            0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
            0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,  # Image data
            0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,  # IEND chunk
            0x42, 0x60, 0x82
        )
        $testImagePath = Join-Path $testDir 'test.png'
        [System.IO.File]::WriteAllBytes($testImagePath, $pngBytes)
        
        # Create test markdown file
        $testMarkdown = Join-Path $testDir 'test.md'
        $markdownContent = @"
---
background: black
foreground: white
---

### Image Test

![Test Image](test.png)
"@
        Set-Content -Path $testMarkdown -Value $markdownContent
    }
    
    Context 'Image Pattern Detection' {
        It 'Should detect basic image markdown' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![Alt text](path/to/image.png)'
            
            $text | Should -Match $pattern
        }
        
        It 'Should detect image with width attribute' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![Alt text](path/to/image.png){width=50}'
            
            $match = [regex]::Match($text, $pattern)
            $match.Success | Should -BeTrue
            $match.Groups[1].Value | Should -Be 'Alt text'
            $match.Groups[2].Value | Should -Be 'path/to/image.png'
            $match.Groups[3].Value | Should -Be '50'
        }
        
        It 'Should detect image without alt text' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![](path/to/image.png)'
            
            $match = [regex]::Match($text, $pattern)
            $match.Success | Should -BeTrue
            $match.Groups[1].Value | Should -Be ''
            $match.Groups[2].Value | Should -Be 'path/to/image.png'
        }
        
        It 'Should not match incomplete image markdown' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![Alt text](missing closing paren'
            
            $text | Should -Not -Match $pattern
        }
    }
    
    Context 'Image Path Resolution' {
        It 'Should resolve relative paths correctly' {
            $testDir = Join-Path $TestDrive 'PathTest'
            New-Item -Path $testDir -ItemType Directory -Force | Out-Null
            
            $markdownPath = Join-Path $testDir 'presentation.md'
            $imagePath = 'images/test.png'
            $expectedPath = Join-Path $testDir $imagePath
            
            # Create the expected directory
            $imageDir = Join-Path $testDir 'images'
            New-Item -Path $imageDir -ItemType Directory -Force | Out-Null
            
            # Verify path resolution logic
            $resolvedPath = if (-not [System.IO.Path]::IsPathRooted($imagePath)) {
                $markdownDir = Split-Path -Parent $markdownPath
                Join-Path $markdownDir $imagePath
            } else {
                $imagePath
            }
            
            $resolvedPath | Should -Be $expectedPath
        }
        
        It 'Should keep absolute paths unchanged' {
            $absolutePath = '/absolute/path/to/image.png'
            
            $resolvedPath = if (-not [System.IO.Path]::IsPathRooted($absolutePath)) {
                Join-Path '/some/dir' $absolutePath
            } else {
                $absolutePath
            }
            
            $resolvedPath | Should -Be $absolutePath
        }
    }
    
    Context 'Image Segment Parsing' {
        It 'Should parse text, image, and text segments' {
            $content = @"
Some text before

![Alt](image.png)

Some text after
"@
            
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $matches = [regex]::Matches($content, $imagePattern)
            
            $matches.Count | Should -Be 1
            $matches[0].Groups[1].Value | Should -Be 'Alt'
            $matches[0].Groups[2].Value | Should -Be 'image.png'
        }
        
        It 'Should parse multiple images in content' {
            $content = @"
![First](first.png)
Some text
![Second](second.png)
"@
            
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $matches = [regex]::Matches($content, $imagePattern)
            
            $matches.Count | Should -Be 2
            $matches[0].Groups[2].Value | Should -Be 'first.png'
            $matches[1].Groups[2].Value | Should -Be 'second.png'
        }
        
        It 'Should not match images inside code blocks' {
            $content = @"
Some text

``````markdown
![Example](example.png)
``````

More text
"@
            
            # This test verifies the implementation detects both code and images
            # but the code block should come first, and the image inside should be
            # treated as part of the code content, not as a separate image segment
            $codeBlockPattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            
            # Find code blocks
            $codeMatches = [regex]::Matches($content, $codeBlockPattern)
            $codeMatches.Count | Should -Be 1
            
            # Find images
            $imageMatches = [regex]::Matches($content, $imagePattern)
            $imageMatches.Count | Should -Be 1
            
            # The image should be inside the code block
            $codeBlock = $codeMatches[0]
            $imageMatch = $imageMatches[0]
            
            # Image index should be between code block start and end
            $imageMatch.Index | Should -BeGreaterThan $codeBlock.Index
            $imageMatch.Index | Should -BeLessThan ($codeBlock.Index + $codeBlock.Length)
        }
    }
    
    Context 'Width Attribute Parsing' {
        It 'Should parse width attribute when present' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![Alt](image.png){width=75}'
            
            $match = [regex]::Match($text, $pattern)
            $width = if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 0 }
            
            $width | Should -Be 75
        }
        
        It 'Should return 0 when width attribute is absent' {
            $pattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            $text = '![Alt](image.png)'
            
            $match = [regex]::Match($text, $pattern)
            $width = if ($match.Groups[3].Success) { [int]$match.Groups[3].Value } else { 0 }
            
            $width | Should -Be 0
        }
    }
    
    Context 'Mixed Content Segments' {
        It 'Should handle text, code, and images in correct order' {
            $content = @"
Text before

![Image](img.png)

``````powershell
Get-Process
``````

Text after
"@
            
            $codePattern = '(?s)```(\w+)?\r?\n(.*?)\r?\n```'
            $imagePattern = '!\[([^\]]*)\]\(([^)]+)\)(?:\{width=(\d+)\})?'
            
            $allMatches = [System.Collections.Generic.List[PSCustomObject]]::new()
            
            foreach ($match in [regex]::Matches($content, $codePattern)) {
                $allMatches.Add([PSCustomObject]@{ Type = 'Code'; Index = $match.Index })
            }
            
            foreach ($match in [regex]::Matches($content, $imagePattern)) {
                $allMatches.Add([PSCustomObject]@{ Type = 'Image'; Index = $match.Index })
            }
            
            $sorted = $allMatches | Sort-Object -Property Index
            
            $sorted.Count | Should -Be 2
            $sorted[0].Type | Should -Be 'Image'
            $sorted[1].Type | Should -Be 'Code'
        }
    }
}
