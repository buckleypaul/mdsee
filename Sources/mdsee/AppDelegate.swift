import AppKit
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var fileWatcher: FileWatcher?
    private let fileURL: URL
    private let renderer = MarkdownRenderer()

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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

        window.title = fileURL.lastPathComponent
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

    deinit {
        fileWatcher?.stop()
        DistributedNotificationCenter.default.removeObserver(self)
    }
}
