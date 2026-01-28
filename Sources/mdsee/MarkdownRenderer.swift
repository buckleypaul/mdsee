import Foundation
import Markdown

class MarkdownRenderer {
    private let templateHTML: String

    init() {
        if let templateURL = Bundle.module.url(forResource: "template", withExtension: "html"),
           let template = try? String(contentsOf: templateURL, encoding: .utf8) {
            self.templateHTML = template
        } else {
            // Fallback minimal template
            self.templateHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"><title>Markdown</title></head>
            <body>{{CONTENT}}</body>
            </html>
            """
        }
    }

    func render(markdown: String) -> String {
        let document = Document(parsing: markdown)
        var htmlVisitor = HTMLVisitor()
        let htmlContent = htmlVisitor.visit(document)
        return templateHTML.replacingOccurrences(of: "{{CONTENT}}", with: htmlContent)
    }

    func renderError(_ message: String) -> String {
        let errorHTML = "<div class=\"error\">\(escapeHTML(message))</div>"
        return templateHTML.replacingOccurrences(of: "{{CONTENT}}", with: errorHTML)
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    mutating func visitDocument(_ document: Document) -> String {
        document.children.map { visit($0) }.joined()
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(paragraph.children.map { visit($0) }.joined())</p>\n"
    }

    mutating func visitText(_ text: Text) -> String {
        escapeHTML(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(emphasis.children.map { visit($0) }.joined())</em>"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(strong.children.map { visit($0) }.joined())</strong>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language ?? ""
        let langClass = language.isEmpty ? "" : " class=\"language-\(escapeHTML(language))\""
        return "<pre><code\(langClass)>\(escapeHTML(codeBlock.code))</code></pre>\n"
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = min(max(heading.level, 1), 6)
        let content = heading.children.map { visit($0) }.joined()
        return "<h\(level)>\(content)</h\(level)>\n"
    }

    mutating func visitLink(_ link: Link) -> String {
        let href = escapeHTML(link.destination ?? "")
        let content = link.children.map { visit($0) }.joined()
        return "<a href=\"\(href)\">\(content)</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let src = escapeHTML(image.source ?? "")
        let alt = escapeHTML(image.children.compactMap { ($0 as? Text)?.string }.joined())
        let title = image.title.map { " title=\"\(escapeHTML($0))\"" } ?? ""
        return "<img src=\"\(src)\" alt=\"\(alt)\"\(title)>"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        "<ul>\n\(unorderedList.children.map { visit($0) }.joined())</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let start = orderedList.startIndex
        let startAttr = start != 1 ? " start=\"\(start)\"" : ""
        return "<ol\(startAttr)>\n\(orderedList.children.map { visit($0) }.joined())</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let checkbox = listItem.checkbox.map { checkbox -> String in
            let checked = checkbox == .checked ? " checked" : ""
            return "<input type=\"checkbox\"\(checked) disabled> "
        } ?? ""

        // For task list items, unwrap paragraph content to keep text inline with checkbox
        if listItem.checkbox != nil {
            var content = ""
            for child in listItem.children {
                if let paragraph = child as? Paragraph {
                    // Render paragraph children inline without <p> wrapper
                    content += paragraph.children.map { visit($0) }.joined()
                } else {
                    content += visit(child)
                }
            }
            return "<li>\(checkbox)\(content)</li>\n"
        }

        let content = listItem.children.map { visit($0) }.joined()
        return "<li>\(checkbox)\(content)</li>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(blockQuote.children.map { visit($0) }.joined())</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        html.rawHTML
    }

    mutating func visitInlineHTML(_ html: InlineHTML) -> String {
        html.rawHTML
    }

    mutating func visitTable(_ table: Table) -> String {
        var result = "<table>\n"

        // Get column alignments
        let alignments = table.columnAlignments

        // Render header
        result += "<thead>\n<tr>\n"
        for (index, cell) in table.head.cells.enumerated() {
            let align = index < alignments.count ? alignmentAttribute(alignments[index]) : ""
            result += "<th\(align)>\(visit(cell))</th>\n"
        }
        result += "</tr>\n</thead>\n"

        // Render body rows
        let bodyRows = Array(table.body.rows)
        if !bodyRows.isEmpty {
            result += "<tbody>\n"
            for row in bodyRows {
                result += "<tr>\n"
                for (index, cell) in row.cells.enumerated() {
                    let align = index < alignments.count ? alignmentAttribute(alignments[index]) : ""
                    result += "<td\(align)>\(visit(cell))</td>\n"
                }
                result += "</tr>\n"
            }
            result += "</tbody>\n"
        }

        result += "</table>\n"
        return result
    }

    mutating func visitTableCell(_ cell: Table.Cell) -> String {
        cell.children.map { visit($0) }.joined()
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(strikethrough.children.map { visit($0) }.joined())</del>"
    }

    private func alignmentAttribute(_ alignment: Table.ColumnAlignment?) -> String {
        guard let alignment = alignment else { return "" }
        switch alignment {
        case .left: return " style=\"text-align: left\""
        case .center: return " style=\"text-align: center\""
        case .right: return " style=\"text-align: right\""
        }
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
