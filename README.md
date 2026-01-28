# mdsee

A minimal macOS CLI tool that opens a native window to view markdown files with automatic refresh on file changes.

## Installation

### Via Homebrew (recommended)

```bash
brew tap USERNAME/mdsee
brew install mdsee
```

### From source

```bash
git clone https://github.com/USERNAME/mdsee.git
cd mdsee
swift build -c release
cp .build/release/mdsee /usr/local/bin/
```

## Usage

```bash
mdsee <file.md>
```

Simply run `mdsee` with a markdown file path. A native window will open displaying the rendered markdown.

**Features:**
- GitHub Flavored Markdown (GFM) support
- Syntax highlighting for code blocks
- Automatic live reload when the file changes
- Dark mode support (adapts to macOS appearance)
- Tables, task lists, blockquotes, and more

## Examples

```bash
# View a README
mdsee README.md

# View any markdown file
mdsee ~/Documents/notes.md
```

## Error Handling

- No argument provided: Prints usage and exits with code 1
- File doesn't exist: Prints error to stderr and exits with code 1
- File is not readable: Prints error to stderr and exits with code 1

## Requirements

- macOS 12.0 or later

## License

MIT
