# mdsee

A minimal macOS CLI tool that opens a native window to view markdown files with automatic refresh on file changes.

## Installation

### Via Homebrew (recommended)

```bash
brew install buckleypaul/mdsee/mdsee
```

### From source

```bash
git clone https://github.com/buckleypaul/mdsee.git
cd mdsee
swift build -c release
cp .build/release/mdsee /usr/local/bin/
```

## Usage

```bash
mdsee <file.md>
mdsee --theme <theme-name> <file.md>
```

Simply run `mdsee` with a markdown file path. A native window will open displaying the rendered markdown.

**Features:**
- GitHub Flavored Markdown (GFM) support
- Syntax highlighting for code blocks
- Automatic live reload when the file changes
- Dark mode support (adapts to macOS appearance)
- Tables, task lists, blockquotes, and more
- Print and save as PDF (⌘P)
- Find in page (⌘F)
- Text selection and copy (⌘C)
- Multiple built-in themes

## Examples

```bash
# View a README
mdsee README.md

# View any markdown file
mdsee ~/Documents/notes.md

# Use a specific theme
mdsee --theme academic paper.md
mdsee --theme solarized notes.md
```

## Themes

mdsee comes with several built-in themes:

- **default** - GitHub-style theme with light/dark mode
- **academic** - Palatino serif fonts for scholarly documents
- **solarized** - Solarized light/dark color scheme
- **catppuccin** - Catppuccin color palette (frappe, latte, macchiato, mocha variants)
- **monokai** - Popular dark theme

Use the `--theme` flag to select a theme:

```bash
mdsee --theme academic document.md
```

## Printing and Exporting

Press **⌘P** to open the macOS print dialog. From there you can:
- Print to a physical printer
- Save as PDF using the "Save as PDF" button in the print dialog
- Adjust page layout and margins

This makes it easy to export your markdown documents to PDF format with full formatting preserved.

## Error Handling

- No argument provided: Prints usage and exits with code 1
- File doesn't exist: Prints error to stderr and exits with code 1
- File is not readable: Prints error to stderr and exits with code 1

## Requirements

- macOS 12.0 or later

## License

MIT
