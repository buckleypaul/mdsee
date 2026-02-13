import Foundation

struct HeadingColors: Codable {
    var h1: String?
    var h2: String?
    var h3: String?
    var h4: String?
    var h5: String?
    var h6: String?
    var `default`: String?

    func color(for level: Int, fallback: String) -> String {
        let levelColor: String?
        switch level {
        case 1: levelColor = h1
        case 2: levelColor = h2
        case 3: levelColor = h3
        case 4: levelColor = h4
        case 5: levelColor = h5
        case 6: levelColor = h6
        default: levelColor = nil
        }
        return levelColor ?? `default` ?? fallback
    }

    func merged(with fallback: HeadingColors) -> HeadingColors {
        HeadingColors(
            h1: h1 ?? fallback.h1,
            h2: h2 ?? fallback.h2,
            h3: h3 ?? fallback.h3,
            h4: h4 ?? fallback.h4,
            h5: h5 ?? fallback.h5,
            h6: h6 ?? fallback.h6,
            default: `default` ?? fallback.`default`
        )
    }
}

struct ThemeColors: Codable {
    var background: String?
    var text: String?
    var headings: String?
    var headingColors: HeadingColors?
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

    init(
        background: String? = nil,
        text: String? = nil,
        headings: String? = nil,
        headingColors: HeadingColors? = nil,
        links: String? = nil,
        codeBackground: String? = nil,
        border: String? = nil,
        blockquoteBorder: String? = nil,
        blockquoteText: String? = nil,
        tableBorder: String? = nil,
        tableRowAlt: String? = nil,
        hr: String? = nil,
        errorBackground: String? = nil,
        errorBorder: String? = nil,
        errorText: String? = nil
    ) {
        self.background = background
        self.text = text
        self.headings = headings
        self.headingColors = headingColors
        self.links = links
        self.codeBackground = codeBackground
        self.border = border
        self.blockquoteBorder = blockquoteBorder
        self.blockquoteText = blockquoteText
        self.tableBorder = tableBorder
        self.tableRowAlt = tableRowAlt
        self.hr = hr
        self.errorBackground = errorBackground
        self.errorBorder = errorBorder
        self.errorText = errorText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        background = try container.decodeIfPresent(String.self, forKey: .background)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        links = try container.decodeIfPresent(String.self, forKey: .links)
        codeBackground = try container.decodeIfPresent(String.self, forKey: .codeBackground)
        border = try container.decodeIfPresent(String.self, forKey: .border)
        blockquoteBorder = try container.decodeIfPresent(String.self, forKey: .blockquoteBorder)
        blockquoteText = try container.decodeIfPresent(String.self, forKey: .blockquoteText)
        tableBorder = try container.decodeIfPresent(String.self, forKey: .tableBorder)
        tableRowAlt = try container.decodeIfPresent(String.self, forKey: .tableRowAlt)
        hr = try container.decodeIfPresent(String.self, forKey: .hr)
        errorBackground = try container.decodeIfPresent(String.self, forKey: .errorBackground)
        errorBorder = try container.decodeIfPresent(String.self, forKey: .errorBorder)
        errorText = try container.decodeIfPresent(String.self, forKey: .errorText)

        // Try to decode headings as HeadingColors first, fall back to String
        if let headingColorsValue = try? container.decode(HeadingColors.self, forKey: .headings) {
            headingColors = headingColorsValue
            headings = nil
        } else {
            headings = try container.decodeIfPresent(String.self, forKey: .headings)
            headingColors = nil
        }
    }

    func merged(with fallback: ThemeColors) -> ThemeColors {
        let mergedHeadingColors: HeadingColors?
        if let selfColors = headingColors, let fallbackColors = fallback.headingColors {
            mergedHeadingColors = selfColors.merged(with: fallbackColors)
        } else {
            mergedHeadingColors = headingColors ?? fallback.headingColors
        }

        return ThemeColors(
            background: background ?? fallback.background,
            text: text ?? fallback.text,
            headings: headings ?? fallback.headings,
            headingColors: mergedHeadingColors,
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
