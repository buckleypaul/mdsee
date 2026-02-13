# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

mdsee is a minimal macOS CLI tool that opens a native window to view markdown files with automatic refresh on file changes. It's written in Swift using Swift Package Manager and requires macOS 12.0+.

**Key Features**: GitHub Flavored Markdown support, syntax highlighting, live file watching, dark mode, themeable UI, Table of Contents sidebar, find in page, and PDF export.

## Building and Running

```bash
# Build debug version
swift build

# Build release version
swift build -c release

# Run directly with Swift
swift run mdsee path/to/file.md

# Run the built binary
.build/debug/mdsee path/to/file.md
```

The release binary is located at `.build/release/mdsee` after building.

## Architecture

### Dual Process Model
The app uses a unique detached process architecture in `main.swift`:
1. Parent process validates arguments and file path, then spawns a detached child via `posix_spawn` with `POSIX_SPAWN_SETSID`
2. Parent exits immediately, returning control to terminal
3. Detached child runs the actual NSApplication
4. Theme name is passed via `MDSEE_THEME` environment variable to avoid complex argument parsing in child

### Component Flow

**main.swift** → Argument parsing & validation → Spawn detached process → **AppDelegate** → **MarkdownRenderer** → **WKWebView**
                                                                      ↓
                                                              **FileWatcher** → Auto-reload on changes

### Key Components

**AppDelegate.swift** (614 lines)
- Main application coordinator
- Sets up NSWindow, WKWebView, menu system
- Implements find-in-page functionality (custom UI + JavaScript highlighting)
- Handles PDF export via WKWebView's createPDF
- Manages Table of Contents toggle
- Observes system appearance changes for dark mode
- Generates custom app icon programmatically

**MarkdownRenderer.swift**
- Uses Apple's swift-markdown library to parse markdown into an AST
- Implements `HTMLVisitor` (MarkupVisitor protocol) to traverse AST and generate HTML
- Handles GFM features: tables, task lists, strikethrough, etc.
- Generates unique heading IDs with slug collision handling (used for TOC anchors)
- Injects themed HTML template with placeholders: `{{CONTENT}}`, `{{THEME_CSS}}`, `{{HIGHLIGHT_JS_LINKS}}`

**Theme System**
- **Theme.swift**: Data structures (`ThemeFile`, `ResolvedTheme`, `ThemeColors`, `ThemeFont`)
  - Supports both adaptive themes (separate light/dark configs) and single-mode themes
  - Per-heading-level color support via `HeadingColors` struct
  - Uses `.merged(with:)` pattern to apply fallbacks to default GitHub-style theme
- **ThemeEngine.swift**:
  - Loads YAML themes from bundled Resources/themes/ and user ~/.config/mdsee/themes/
  - Resolves themes into CSS custom properties (`:root` with `@media (prefers-color-scheme: dark)`)
  - Generates highlight.js stylesheet links with media queries for adaptive themes
  - User themes override bundled themes with same name

**FileWatcher.swift**
- Uses `DispatchSource.makeFileSystemObjectSource` to watch file modifications
- Monitors `.write`, `.delete`, `.rename`, `.extend` events
- Automatically reopens file descriptor if file is deleted/renamed (common with some editors)

**Config.swift**
- Loads user config from `~/.config/mdsee/config.yaml`
- Currently supports `theme` preference as default when `--theme` not specified

**Resources/template.html**
- HTML template with embedded CSS using CSS custom properties
- Includes highlight.js from CDN
- Table of Contents sidebar with IntersectionObserver-based scroll spy
- JavaScript functions: `buildTOC()`, `toggleTOC()`, and highlight.js initialization

## Theme System Details

Themes are YAML files with this structure:
```yaml
name: theme-name
# Adaptive theme (separate light/dark modes):
light:
  colors: { ... }
  font: { ... }
  highlightjs: "github"
dark:
  colors: { ... }
  font: { ... }
  highlightjs: "github-dark"

# OR single-mode theme:
mode: "light"  # or "dark"
colors: { ... }
font: { ... }
highlightjs: "github"
```

The `headings` color property can be either a string (all headings same color) or an object with per-level colors (`h1`, `h2`, etc. plus `default` fallback).

## Important Patterns

**Process Detachment**: Never modify the detachment logic in main.swift without understanding the parent/child model. The parent MUST exit cleanly for the terminal to be usable again.

**Find-in-Page**: Implemented entirely via JavaScript injection (no native WKWebView find API). Highlights are `<span class="mdsee-highlight">` with background colors. Current match uses `.mdsee-current` class.

**Markdown Rendering**: The `HTMLVisitor` is mutable due to state tracking for heading ID collisions (`seenIDs`). When modifying visitor methods, preserve the mutating keyword and call pattern.

**Theme Resolution**: All theme colors have fallbacks to GitHub light/dark defaults. When adding new theme properties, update both `ThemeColors` and the `.merged(with:)` implementation, plus the CSS variable generation in ThemeEngine.

**WebView Base URL**: `loadHTMLString(_:baseURL:)` uses the markdown file's directory as base URL so relative image paths work correctly.

## Release Process

When creating a new release, follow these steps:

1. **Update CHANGELOG.md**:
   - Move unreleased changes to a new version section with the release date
   - Follow [Keep a Changelog](https://keepachangelog.com/) format
   - Categorize changes as Added, Changed, Fixed, Removed, etc.
   - Add comparison link at the bottom

2. **Create Git Tag**:
   - Tag the release: `git tag v1.x.x`
   - Push tag: `git push origin v1.x.x`

3. **Update Homebrew Formula**:
   - Update Formula/mdsee.rb with new version URL and SHA256
   - The formula builds from source using `swift build -c release`
   - Binary is installed to Homebrew's bin directory

4. **Create GitHub Release**:
   - Create release from tag on GitHub
   - Copy relevant section from CHANGELOG.md as release notes

## Debugging Tips

- Enable WebKit developer tools: The WKWebViewConfiguration sets `developerExtrasEnabled = true`, so you can right-click → Inspect Element
- File watching issues: Check the FileWatcher's event mask if certain file changes aren't triggering reloads
- Theme not applying: Verify theme YAML syntax, check that `ThemeEngine.loadTheme()` successfully decodes it
- Process issues: Check if parent process is exiting correctly (should return control to terminal immediately)
