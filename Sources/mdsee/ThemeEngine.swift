import Foundation
import Yams

class ThemeEngine {
    private var themes: [String: ResolvedTheme] = [:]
    private let userThemesDirectory: URL

    init() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/mdsee/themes")
        self.userThemesDirectory = configDir

        loadBundledThemes()
        loadUserThemes()
    }

    private func loadBundledThemes() {
        guard let themesURL = Bundle.module.url(forResource: "themes", withExtension: nil) else {
            return
        }

        loadThemesFromDirectory(themesURL)
    }

    private func loadUserThemes() {
        guard FileManager.default.fileExists(atPath: userThemesDirectory.path) else {
            return
        }

        loadThemesFromDirectory(userThemesDirectory)
    }

    private func loadThemesFromDirectory(_ directory: URL) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files where file.pathExtension == "yaml" || file.pathExtension == "yml" {
            if let theme = loadTheme(from: file) {
                themes[theme.name] = theme
            }
        }
    }

    private func loadTheme(from url: URL) -> ResolvedTheme? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8),
              let themeFile = try? YAMLDecoder().decode(ThemeFile.self, from: contents) else {
            return nil
        }

        return resolveTheme(themeFile)
    }

    private func resolveTheme(_ file: ThemeFile) -> ResolvedTheme {
        let hasLightMode: Bool
        let hasDarkMode: Bool
        let lightColors: ThemeColors
        let darkColors: ThemeColors
        let lightFont: ThemeFont
        let darkFont: ThemeFont
        let lightHighlightjs: String
        let darkHighlightjs: String

        if file.light != nil || file.dark != nil {
            // Adaptive theme with explicit light/dark modes
            hasLightMode = file.light != nil
            hasDarkMode = file.dark != nil

            lightColors = (file.light?.colors ?? ThemeColors()).merged(with: .defaultLight)
            darkColors = (file.dark?.colors ?? ThemeColors()).merged(with: .defaultDark)
            lightFont = (file.light?.font ?? ThemeFont()).merged(with: .defaultFont)
            darkFont = (file.dark?.font ?? ThemeFont()).merged(with: .defaultFont)
            lightHighlightjs = file.light?.highlightjs ?? "github"
            darkHighlightjs = file.dark?.highlightjs ?? "github-dark"
        } else {
            // Single-mode theme or uses top-level colors
            let mode = file.mode?.lowercased() ?? "light"
            let isLight = mode == "light"

            hasLightMode = isLight
            hasDarkMode = !isLight

            let baseColors = file.colors ?? ThemeColors()
            let baseFont = file.font ?? ThemeFont()
            let baseHighlightjs = file.highlightjs ?? (isLight ? "github" : "github-dark")

            if isLight {
                lightColors = baseColors.merged(with: .defaultLight)
                darkColors = .defaultDark
                lightFont = baseFont.merged(with: .defaultFont)
                darkFont = .defaultFont
                lightHighlightjs = baseHighlightjs
                darkHighlightjs = "github-dark"
            } else {
                lightColors = .defaultLight
                darkColors = baseColors.merged(with: .defaultDark)
                lightFont = .defaultFont
                darkFont = baseFont.merged(with: .defaultFont)
                lightHighlightjs = "github"
                darkHighlightjs = baseHighlightjs
            }
        }

        return ResolvedTheme(
            name: file.name,
            lightColors: lightColors,
            darkColors: darkColors,
            lightFont: lightFont,
            darkFont: darkFont,
            lightHighlightjs: lightHighlightjs,
            darkHighlightjs: darkHighlightjs,
            hasLightMode: hasLightMode,
            hasDarkMode: hasDarkMode
        )
    }

    func getTheme(named name: String) -> ResolvedTheme? {
        return themes[name]
    }

    func listThemes() -> [String] {
        return themes.keys.sorted()
    }

    func getDefaultTheme() -> ResolvedTheme {
        return themes["default"] ?? createBuiltinDefault()
    }

    private func createBuiltinDefault() -> ResolvedTheme {
        ResolvedTheme(
            name: "default",
            lightColors: .defaultLight,
            darkColors: .defaultDark,
            lightFont: .defaultFont,
            darkFont: .defaultFont,
            lightHighlightjs: "github",
            darkHighlightjs: "github-dark",
            hasLightMode: true,
            hasDarkMode: true
        )
    }

    func generateCSS(for theme: ResolvedTheme) -> String {
        var css = ""

        if theme.hasLightMode && theme.hasDarkMode {
            // Adaptive theme: use light as default, dark for dark mode
            css += ":root {\n"
            css += generateColorVars(theme.lightColors)
            css += generateFontVars(theme.lightFont)
            css += "}\n\n"

            css += "@media (prefers-color-scheme: dark) {\n"
            css += "    :root {\n"
            css += generateColorVars(theme.darkColors, indent: "        ")
            css += generateFontVars(theme.darkFont, indent: "        ")
            css += "    }\n"
            css += "}\n"
        } else if theme.hasDarkMode {
            // Dark-only theme: always use dark colors
            css += ":root {\n"
            css += generateColorVars(theme.darkColors)
            css += generateFontVars(theme.darkFont)
            css += "}\n"
        } else {
            // Light-only theme: always use light colors
            css += ":root {\n"
            css += generateColorVars(theme.lightColors)
            css += generateFontVars(theme.lightFont)
            css += "}\n"
        }

        return css
    }

    private func generateColorVars(_ colors: ThemeColors, indent: String = "    ") -> String {
        var css = ""
        css += "\(indent)--bg-color: \(colors.background ?? "#ffffff");\n"
        css += "\(indent)--text-color: \(colors.text ?? "#24292f");\n"

        // Generate heading color variables
        let defaultHeadingColor = colors.headings ?? "#1f2328"
        css += "\(indent)--heading-color: \(defaultHeadingColor);\n"

        // Generate per-level heading colors
        if let headingColors = colors.headingColors {
            // Use per-level colors with fallback logic
            css += "\(indent)--h1-color: \(headingColors.color(for: 1, fallback: defaultHeadingColor));\n"
            css += "\(indent)--h2-color: \(headingColors.color(for: 2, fallback: defaultHeadingColor));\n"
            css += "\(indent)--h3-color: \(headingColors.color(for: 3, fallback: defaultHeadingColor));\n"
            css += "\(indent)--h4-color: \(headingColors.color(for: 4, fallback: defaultHeadingColor));\n"
            css += "\(indent)--h5-color: \(headingColors.color(for: 5, fallback: defaultHeadingColor));\n"
            css += "\(indent)--h6-color: \(headingColors.color(for: 6, fallback: defaultHeadingColor));\n"
        } else {
            // All levels use the single heading color
            css += "\(indent)--h1-color: \(defaultHeadingColor);\n"
            css += "\(indent)--h2-color: \(defaultHeadingColor);\n"
            css += "\(indent)--h3-color: \(defaultHeadingColor);\n"
            css += "\(indent)--h4-color: \(defaultHeadingColor);\n"
            css += "\(indent)--h5-color: \(defaultHeadingColor);\n"
            css += "\(indent)--h6-color: \(defaultHeadingColor);\n"
        }

        css += "\(indent)--link-color: \(colors.links ?? "#0969da");\n"
        css += "\(indent)--code-bg: \(colors.codeBackground ?? "#f6f8fa");\n"
        css += "\(indent)--border-color: \(colors.border ?? "#d0d7de");\n"
        css += "\(indent)--blockquote-border: \(colors.blockquoteBorder ?? "#d0d7de");\n"
        css += "\(indent)--blockquote-text: \(colors.blockquoteText ?? "#59636e");\n"
        css += "\(indent)--table-border: \(colors.tableBorder ?? "#d0d7de");\n"
        css += "\(indent)--table-row-alt: \(colors.tableRowAlt ?? "#f6f8fa");\n"
        css += "\(indent)--hr-color: \(colors.hr ?? "#d8dee4");\n"
        css += "\(indent)--error-bg: \(colors.errorBackground ?? "#ffebe9");\n"
        css += "\(indent)--error-border: \(colors.errorBorder ?? "#ff8182");\n"
        css += "\(indent)--error-text: \(colors.errorText ?? "#cf222e");\n"
        return css
    }

    private func generateFontVars(_ font: ThemeFont, indent: String = "    ") -> String {
        var css = ""
        css += "\(indent)--font-family: \(font.family ?? "-apple-system, BlinkMacSystemFont, sans-serif");\n"
        css += "\(indent)--mono-family: \(font.monoFamily ?? "ui-monospace, SFMono-Regular, monospace");\n"
        css += "\(indent)--font-size: \(font.size ?? "16px");\n"
        return css
    }

    func generateHighlightJSLinks(for theme: ResolvedTheme) -> String {
        let baseURL = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles"

        if theme.hasLightMode && theme.hasDarkMode {
            // Adaptive theme: use media queries for both
            return """
            <link rel="stylesheet" href="\(baseURL)/\(theme.lightHighlightjs).min.css" media="(prefers-color-scheme: light)">
            <link rel="stylesheet" href="\(baseURL)/\(theme.darkHighlightjs).min.css" media="(prefers-color-scheme: dark)">
            """
        } else if theme.hasDarkMode {
            // Dark-only theme: always use dark highlight.js
            return """
            <link rel="stylesheet" href="\(baseURL)/\(theme.darkHighlightjs).min.css">
            """
        } else {
            // Light-only theme: always use light highlight.js
            return """
            <link rel="stylesheet" href="\(baseURL)/\(theme.lightHighlightjs).min.css">
            """
        }
    }
}
