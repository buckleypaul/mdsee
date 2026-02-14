# Zoom Controls Design

**Date:** 2026-02-14
**Feature:** Add Cmd+ and Cmd- keyboard shortcuts for zoom in/out

## Overview

Add zoom controls to mdsee that allow users to increase or decrease the entire page size using Cmd+ (zoom in) and Cmd- (zoom out) keyboard shortcuts.

## Requirements

- **Zoom scope:** Entire page (text, images, code blocks, tables - everything scales proportionally)
- **Persistence:** No - each file starts fresh at 100% zoom
- **Reset shortcut:** Not needed - users can manually zoom in/out to get back to 100%
- **Zoom range:** 50% (minimum) to 300% (maximum)
- **Zoom increments:** 10% per step (100% → 110% → 120%, etc.)

## Technical Approach

**Selected approach:** CSS zoom property via JavaScript injection

This approach uses the CSS `zoom` property by injecting JavaScript to set `document.body.style.zoom`. While technically non-standard, it's universally supported and is the simplest, most reliable solution that scales everything uniformly without layout complications.

### Alternatives Considered

1. **WKWebView magnification property** - Native API but primarily designed for PDFs, may behave unexpectedly with HTML
2. **CSS transform: scale()** - Standards-compliant but more complex, can cause scrollbar and overflow issues

## Architecture

The zoom feature is implemented entirely in **AppDelegate.swift**:

- **State:** Add `currentZoomLevel` property (Double, starts at 1.0 = 100%)
- **Menu items:** Add "Zoom In" and "Zoom Out" to View menu with Cmd+ and Cmd- shortcuts
- **Actions:** Two `@objc` methods (`zoomIn()` and `zoomOut()`) that:
  1. Adjust `currentZoomLevel` by ±0.1 (10%)
  2. Clamp value between 0.5 and 3.0
  3. Inject JavaScript to set `document.body.style.zoom`
- **Reset on load:** `loadMarkdown()` resets `currentZoomLevel` to 1.0

No changes needed to template.html, themes, or other components.

## Components & Code Changes

### AppDelegate.swift

1. **Add property** (around line 16):
   ```swift
   private var currentZoomLevel: Double = 1.0
   ```

2. **Update setupMenu()** - Add to View menu (after line 86):
   ```swift
   viewMenu.addItem(NSMenuItem.separator())
   viewMenu.addItem(withTitle: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+")
   viewMenu.addItem(withTitle: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-")
   ```

3. **Add action methods** (after line 110):
   ```swift
   @objc private func zoomIn() {
       currentZoomLevel = min(currentZoomLevel + 0.1, 3.0)
       applyZoom()
   }

   @objc private func zoomOut() {
       currentZoomLevel = max(currentZoomLevel - 0.1, 0.5)
       applyZoom()
   }

   private func applyZoom() {
       let js = "document.body.style.zoom = '\(currentZoomLevel)';"
       webView.evaluateJavaScript(js, completionHandler: nil)
   }
   ```

4. **Update loadMarkdown()** - Reset zoom (add at start of method, line 480):
   ```swift
   currentZoomLevel = 1.0
   ```

## Data Flow

### User triggers zoom

1. User presses Cmd+ or Cmd- (or clicks menu item)
2. `zoomIn()` or `zoomOut()` is called
3. Method adjusts `currentZoomLevel` by 0.1 in either direction
4. Value is clamped to [0.5, 3.0] range using `min()`/`max()`
5. `applyZoom()` injects JavaScript: `document.body.style.zoom = '1.2'`
6. Browser applies zoom instantly to entire page

### User loads/reloads markdown

1. `loadMarkdown()` is called (initially, via file watcher, or manual reload)
2. `currentZoomLevel` is reset to 1.0
3. New HTML is loaded into WebView at default 100% zoom
4. Previous zoom level is forgotten (fresh start)

## Error Handling & Edge Cases

### Error handling

- **JavaScript injection:** Uses `completionHandler: nil` since zoom is non-critical
- **Bounds checking:** `min()`/`max()` clamps prevent invalid zoom values
- **No persistence state:** No file I/O errors to handle
- **WebView timing:** JavaScript executes after WebView loads content

### Edge cases handled

- Rapid key presses: Each increment is clamped, can't exceed bounds
- Zoom at extreme values: Clamping prevents going below 50% or above 300%
- Markdown reload during zoom: Zoom resets to 100% (expected behavior)
- Find-in-page while zoomed: Highlights scale with zoom (part of DOM)
- TOC while zoomed: Works normally (positioned absolutely, zoom affects body only)

## Testing

1. Build and run: `swift run mdsee test.md`
2. Test Cmd+ repeatedly - verify zoom increases to 300% and stops
3. Test Cmd- repeatedly - verify zoom decreases to 50% and stops
4. Test Cmd+R (reload) - verify zoom resets to 100%
5. Test with find-in-page (Cmd+F) - verify highlights scale correctly
6. Test with TOC (Cmd+T) - verify sidebar positioning still works
7. Modify test.md externally - verify auto-reload resets zoom

## Implementation Plan

See the implementation plan in the writing-plans skill output.
