import Foundation

struct ThemeColors: Codable {
    var background: String?
    var text: String?
    var headings: String?
    var links: String?
    var codeBackground: String?
    var border: String?
    var blockquoteBorder: String?
    var blockquoteText: String?
    var tableBorder: String?
    var tableRowAlt: String?
    var hr: String?
    var errorBackground: String?
    var errorBorder: String?
    var errorText: String?

    enum CodingKeys: String, CodingKey {
        case background
        case text
        case headings
        case links
        case codeBackground = "code-background"
        case border
        case blockquoteBorder = "blockquote-border"
        case blockquoteText = "blockquote-text"
        case tableBorder = "table-border"
        case tableRowAlt = "table-row-alt"
        case hr
        case errorBackground = "error-background"
        case errorBorder = "error-border"
        case errorText = "error-text"
    }

    func merged(with fallback: ThemeColors) -> ThemeColors {
        ThemeColors(
            background: background ?? fallback.background,
            text: text ?? fallback.text,
            headings: headings ?? fallback.headings,
            links: links ?? fallback.links,
            codeBackground: codeBackground ?? fallback.codeBackground,
            border: border ?? fallback.border,
            blockquoteBorder: blockquoteBorder ?? fallback.blockquoteBorder,
            blockquoteText: blockquoteText ?? fallback.blockquoteText,
            tableBorder: tableBorder ?? fallback.tableBorder,
            tableRowAlt: tableRowAlt ?? fallback.tableRowAlt,
            hr: hr ?? fallback.hr,
            errorBackground: errorBackground ?? fallback.errorBackground,
            errorBorder: errorBorder ?? fallback.errorBorder,
            errorText: errorText ?? fallback.errorText
        )
    }
}

struct ThemeFont: Codable {
    var family: String?
    var monoFamily: String?
    var size: String?

    enum CodingKeys: String, CodingKey {
        case family
        case monoFamily = "mono-family"
        case size
    }

    func merged(with fallback: ThemeFont) -> ThemeFont {
        ThemeFont(
            family: family ?? fallback.family,
            monoFamily: monoFamily ?? fallback.monoFamily,
            size: size ?? fallback.size
        )
    }
}

struct ThemeModeConfig: Codable {
    var colors: ThemeColors?
    var font: ThemeFont?
    var highlightjs: String?

    enum CodingKeys: String, CodingKey {
        case colors
        case font
        case highlightjs
    }
}

struct ThemeFile: Codable {
    var name: String
    var light: ThemeModeConfig?
    var dark: ThemeModeConfig?
    var colors: ThemeColors?
    var font: ThemeFont?
    var highlightjs: String?
    var mode: String?
}

struct ResolvedTheme {
    let name: String
    let lightColors: ThemeColors
    let darkColors: ThemeColors
    let lightFont: ThemeFont
    let darkFont: ThemeFont
    let lightHighlightjs: String
    let darkHighlightjs: String
    let hasLightMode: Bool
    let hasDarkMode: Bool
}

extension ThemeColors {
    static let defaultLight = ThemeColors(
        background: "#ffffff",
        text: "#24292f",
        headings: "#1f2328",
        links: "#0969da",
        codeBackground: "#f6f8fa",
        border: "#d0d7de",
        blockquoteBorder: "#d0d7de",
        blockquoteText: "#59636e",
        tableBorder: "#d0d7de",
        tableRowAlt: "#f6f8fa",
        hr: "#d8dee4",
        errorBackground: "#ffebe9",
        errorBorder: "#ff8182",
        errorText: "#cf222e"
    )

    static let defaultDark = ThemeColors(
        background: "#0d1117",
        text: "#e6edf3",
        headings: "#ffffff",
        links: "#58a6ff",
        codeBackground: "#161b22",
        border: "#30363d",
        blockquoteBorder: "#3b434b",
        blockquoteText: "#8b949e",
        tableBorder: "#30363d",
        tableRowAlt: "#161b22",
        hr: "#21262d",
        errorBackground: "#490202",
        errorBorder: "#f85149",
        errorText: "#f85149"
    )
}

extension ThemeFont {
    static let defaultFont = ThemeFont(
        family: "-apple-system, BlinkMacSystemFont, \"Segoe UI\", \"Noto Sans\", Helvetica, Arial, sans-serif",
        monoFamily: "ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace",
        size: "16px"
    )
}
