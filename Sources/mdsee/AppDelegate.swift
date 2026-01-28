import AppKit
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var fileWatcher: FileWatcher?
    private let fileURL: URL
    private let renderer: MarkdownRenderer

    init(fileURL: URL, themeName: String? = nil) {
        self.fileURL = fileURL
        self.renderer = MarkdownRenderer(themeName: themeName)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Make app appear in Dock and Command+Tab switcher
        NSApp.setActivationPolicy(.regular)

        // Set custom app icon
        NSApp.applicationIconImage = createAppIcon()

        setupWindow()
        setupWebView()
        loadMarkdown()
        startFileWatcher()

        // Observe appearance changes for dark mode
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func setupWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 600)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "mdsee - \(fileURL.lastPathComponent)"
        window.center()
        window.setFrameAutosaveName("MarkdownViewer")
        window.minSize = NSSize(width: 400, height: 300)
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: window.contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]

        window.contentView = webView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func loadMarkdown() {
        do {
            let markdown = try String(contentsOf: fileURL, encoding: .utf8)
            let html = renderer.render(markdown: markdown)
            webView.loadHTMLString(html, baseURL: fileURL.deletingLastPathComponent())
        } catch {
            let errorHTML = renderer.renderError("Failed to read file: \(error.localizedDescription)")
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }

    private func startFileWatcher() {
        fileWatcher = FileWatcher(url: fileURL) { [weak self] in
            DispatchQueue.main.async {
                self?.loadMarkdown()
            }
        }
        fileWatcher?.start()
    }

    @objc private func appearanceChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.loadMarkdown()
        }
    }

    private func createAppIcon() -> NSImage {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size)

        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)
        let cornerRadius: CGFloat = 90

        // Background gradient (deep blue to purple)
        let backgroundPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 20, dy: 20), xRadius: cornerRadius, yRadius: cornerRadius)

        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            NSColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0)
        ])
        gradient?.draw(in: backgroundPath, angle: -45)

        // Document shape (white, slightly smaller)
        let docRect = bounds.insetBy(dx: 80, dy: 60)
        let docPath = NSBezierPath(roundedRect: docRect, xRadius: 20, yRadius: 20)
        NSColor.white.withAlphaComponent(0.95).setFill()
        docPath.fill()

        // Page fold triangle in top-right
        let foldSize: CGFloat = 60
        let foldPath = NSBezierPath()
        foldPath.move(to: NSPoint(x: docRect.maxX - foldSize, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY))
        foldPath.line(to: NSPoint(x: docRect.maxX, y: docRect.maxY - foldSize))
        foldPath.close()
        NSColor(white: 0.85, alpha: 1.0).setFill()
        foldPath.fill()

        // "MD" text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 160, weight: .bold),
            .foregroundColor: NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            .paragraphStyle: paragraphStyle
        ]

        let text = "MD"
        let textSize = text.size(withAttributes: textAttributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2 - 10,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: textAttributes)

        // Down arrow (markdown symbol) below text
        let arrowPath = NSBezierPath()
        let arrowCenterX = size.width / 2
        let arrowTop: CGFloat = 130
        let arrowWidth: CGFloat = 50
        let arrowHeight: CGFloat = 40

        arrowPath.move(to: NSPoint(x: arrowCenterX - arrowWidth, y: arrowTop))
        arrowPath.line(to: NSPoint(x: arrowCenterX, y: arrowTop - arrowHeight))
        arrowPath.line(to: NSPoint(x: arrowCenterX + arrowWidth, y: arrowTop))
        arrowPath.lineWidth = 12
        arrowPath.lineCapStyle = .round
        arrowPath.lineJoinStyle = .round
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0).setStroke()
        arrowPath.stroke()

        image.unlockFocus()

        return image
    }

    deinit {
        fileWatcher?.stop()
        DistributedNotificationCenter.default.removeObserver(self)
    }
}
