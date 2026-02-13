# Changelog

All notable changes to mdsee will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-02-13

### Added
- Table of Contents sidebar with scroll spy functionality
- Export as PDF feature accessible via File menu
- CLAUDE.md with comprehensive architecture and development guide
- CHANGELOG.md with complete release history

### Changed
- Print command (⌘P) now opens Export as PDF dialog instead of native print dialog

## [1.5.1] - 2026-02-12

### Fixed
- Fixed print functionality to use native NSPrintOperation for proper PDF generation

## [1.5.0] - 2026-02-12

### Added
- Print/save as PDF support with ⌘P keyboard shortcut
- Text selection and copy functionality in the markdown viewer
- Academic theme with Palatino font and scholarly styling
- Per-level heading colors with backward compatibility for themes

### Changed
- Enhanced theme system to support different colors for each heading level (h1-h6)

### Documentation
- Updated README with comprehensive themes and PDF export documentation

## [1.4.0] - 2026-01-28

### Added
- Find in page functionality with ⌘F keyboard shortcut
- JavaScript-based text highlighting for search matches
- Next/previous match navigation in find interface

## [1.3.0] - 2026-01-28

### Added
- Full theming system with YAML-based theme definitions
- Catppuccin themes (Latte, Frappé, Macchiato, Mocha variants)
- Support for both bundled and user-defined themes in `~/.config/mdsee/themes/`
- Theme configuration via `--theme` flag or `~/.config/mdsee/config.yaml`
- Adaptive themes with separate light/dark mode configurations

## [1.2.0] - 2026-01-28

### Added
- Custom programmatically-generated app icon for better macOS integration

## [1.1.0] - 2026-01-28

### Changed
- Application now runs as a detached window process instead of blocking the terminal
- Implemented dual-process model: parent validates and spawns, child runs NSApplication
- Terminal returns control immediately after launching viewer

## [1.0.2] - 2026-01-28

### Fixed
- Fixed Homebrew formula to properly use libexec for binary and bundle installation

## [1.0.1] - 2026-01-28

### Fixed
- Fixed Homebrew formula to include resource bundle for proper theme support

## [1.0.0] - 2026-01-28

### Added
- Initial release of mdsee
- GitHub Flavored Markdown rendering support
- Syntax highlighting for code blocks via highlight.js
- Live file watching with automatic refresh on changes
- Dark mode support following system appearance
- Minimal native macOS window interface
- Swift-based implementation using WKWebView
- Support for relative image paths

[1.6.0]: https://github.com/paulbuckley/mdsee/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/paulbuckley/mdsee/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/paulbuckley/mdsee/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/paulbuckley/mdsee/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/paulbuckley/mdsee/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/paulbuckley/mdsee/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/paulbuckley/mdsee/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/paulbuckley/mdsee/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/paulbuckley/mdsee/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/paulbuckley/mdsee/releases/tag/v1.0.0
