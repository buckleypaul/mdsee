import AppKit
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var fileWatcher: FileWatcher?
    private let fileURL: URL
    private let renderer: MarkdownRenderer
    private var findBar: NSView?
    private var findTextField: NSTextField?
    private var findResultsLabel: NSTextField?
    private var currentFindResults: Int = 0
    private var currentFindIndex: Int = 0

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

        setupMenu()
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

    private func setupMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About mdsee", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit mdsee", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Print...", action: #selector(printDocument), keyEquivalent: "p")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(copyText), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(selectAllText), keyEquivalent: "a")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Find...", action: #selector(showFindBar), keyEquivalent: "f")
        editMenu.addItem(withTitle: "Find Next", action: #selector(findNext), keyEquivalent: "g")
        editMenu.addItem(withTitle: "Find Previous", action: #selector(findPrevious), keyEquivalent: "G")
        editMenu.addItem(withTitle: "Use Selection for Find", action: #selector(useSelectionForFind), keyEquivalent: "e")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Reload", action: #selector(reloadMarkdown), keyEquivalent: "r")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func reloadMarkdown() {
        loadMarkdown()
    }

    @objc private func printDocument() {
        webView.evaluateJavaScript("window.print()", completionHandler: nil)
    }

    @objc private func copyText() {
        let js = "window.getSelection().toString();"
        webView.evaluateJavaScript(js) { result, error in
            if let selectedText = result as? String, !selectedText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(selectedText, forType: .string)
            }
        }
    }

    @objc private func selectAllText() {
        let js = """
        (function() {
            var range = document.createRange();
            range.selectNodeContents(document.body);
            var selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    @objc private func showFindBar() {
        if findBar == nil {
            createFindBar()
        }
        findBar?.isHidden = false
        window.makeFirstResponder(findTextField)
        findTextField?.selectText(nil)
    }

    @objc private func hideFindBar() {
        findBar?.isHidden = true
        clearHighlights()
        window.makeFirstResponder(webView)
    }

    private func createFindBar() {
        let barHeight: CGFloat = 32
        let contentView = window.contentView!

        // Container view
        let bar = NSView(frame: NSRect(x: 0, y: contentView.bounds.height - barHeight, width: contentView.bounds.width, height: barHeight))
        bar.autoresizingMask = [.width, .minYMargin]
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Close button
        let closeButton = NSButton(frame: NSRect(x: 4, y: 4, width: 24, height: 24))
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")
        closeButton.target = self
        closeButton.action = #selector(hideFindBar)
        bar.addSubview(closeButton)

        // Search field
        let textField = NSTextField(frame: NSRect(x: 32, y: 4, width: 200, height: 24))
        textField.placeholderString = "Search..."
        textField.bezelStyle = .roundedBezel
        textField.target = self
        textField.action = #selector(findTextChanged(_:))
        textField.delegate = self
        bar.addSubview(textField)
        findTextField = textField

        // Results label
        let resultsLabel = NSTextField(labelWithString: "")
        resultsLabel.frame = NSRect(x: 238, y: 6, width: 80, height: 20)
        resultsLabel.font = NSFont.systemFont(ofSize: 11)
        resultsLabel.textColor = .secondaryLabelColor
        bar.addSubview(resultsLabel)
        findResultsLabel = resultsLabel

        // Previous button
        let prevButton = NSButton(frame: NSRect(x: 318, y: 4, width: 28, height: 24))
        prevButton.bezelStyle = .inline
        prevButton.isBordered = false
        prevButton.image = NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Previous")
        prevButton.target = self
        prevButton.action = #selector(findPrevious)
        bar.addSubview(prevButton)

        // Next button
        let nextButton = NSButton(frame: NSRect(x: 346, y: 4, width: 28, height: 24))
        nextButton.bezelStyle = .inline
        nextButton.isBordered = false
        nextButton.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Next")
        nextButton.target = self
        nextButton.action = #selector(findNext)
        bar.addSubview(nextButton)

        // Separator line at bottom
        let separator = NSBox(frame: NSRect(x: 0, y: 0, width: bar.bounds.width, height: 1))
        separator.boxType = .separator
        separator.autoresizingMask = [.width]
        bar.addSubview(separator)

        contentView.addSubview(bar)
        findBar = bar

        // Adjust webView frame
        webView.frame = NSRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - barHeight)
        webView.autoresizingMask = [.width, .height]
    }

    @objc private func findTextChanged(_ sender: NSTextField) {
        let searchText = sender.stringValue
        if searchText.isEmpty {
            clearHighlights()
            findResultsLabel?.stringValue = ""
            currentFindResults = 0
            currentFindIndex = 0
        } else {
            performFind(searchText)
        }
    }

    private func performFind(_ text: String) {
        // Escape special characters for JavaScript string and regex
        var escapedText = ""
        for char in text {
            switch char {
            case "\\": escapedText += "\\\\"
            case "'": escapedText += "\\'"
            case "\"": escapedText += "\\\""
            case "\n": escapedText += "\\n"
            case "\r": escapedText += "\\r"
            case "\t": escapedText += "\\t"
            // Regex special characters
            case "[", "]", "(", ")", "{", "}", ".", "*", "+", "?", "^", "$", "|":
                escapedText += "\\\\\(char)"
            default:
                escapedText += String(char)
            }
        }

        let js = """
        (function() {
            // Remove existing highlights by replacing with original text
            var highlights = document.querySelectorAll('.mdsee-highlight');
            highlights.forEach(function(el) {
                var text = document.createTextNode(el.textContent);
                el.parentNode.replaceChild(text, el);
            });
            // Normalize text nodes
            document.body.normalize();

            var searchText = '\(escapedText)';
            if (!searchText) return JSON.stringify({count: 0, current: 0});

            var count = 0;
            var regex = new RegExp(searchText, 'gi');

            function highlightTextNodes(element) {
                var childNodes = Array.from(element.childNodes);
                for (var i = 0; i < childNodes.length; i++) {
                    var node = childNodes[i];
                    if (node.nodeType === 3) { // Text node
                        var text = node.textContent;
                        var match = regex.exec(text);
                        if (match) {
                            regex.lastIndex = 0; // Reset regex
                            var parts = text.split(regex);
                            var matches = text.match(regex);
                            if (matches && parts.length > 1) {
                                var fragment = document.createDocumentFragment();
                                for (var j = 0; j < parts.length; j++) {
                                    if (parts[j]) {
                                        fragment.appendChild(document.createTextNode(parts[j]));
                                    }
                                    if (j < matches.length) {
                                        var span = document.createElement('span');
                                        span.className = 'mdsee-highlight';
                                        span.style.backgroundColor = '#ffff00';
                                        span.style.color = '#000000';
                                        span.style.borderRadius = '2px';
                                        span.textContent = matches[j];
                                        fragment.appendChild(span);
                                        count++;
                                    }
                                }
                                node.parentNode.replaceChild(fragment, node);
                            }
                        }
                    } else if (node.nodeType === 1 && node.nodeName !== 'SCRIPT' && node.nodeName !== 'STYLE') {
                        highlightTextNodes(node);
                    }
                }
            }

            highlightTextNodes(document.body);

            // Mark first match as current
            var allHighlights = document.querySelectorAll('.mdsee-highlight');
            if (allHighlights.length > 0) {
                allHighlights[0].style.backgroundColor = '#ff9500';
                allHighlights[0].classList.add('mdsee-current');
                allHighlights[0].scrollIntoView({behavior: 'smooth', block: 'center'});
            }

            return JSON.stringify({count: allHighlights.length, current: allHighlights.length > 0 ? 1 : 0});
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("Find error: \(error)")
                return
            }
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Int] {
                self?.currentFindResults = json["count"] ?? 0
                self?.currentFindIndex = json["current"] ?? 0
                self?.updateFindResultsLabel()
            }
        }
    }

    @objc private func findNext() {
        guard currentFindResults > 0 else { return }
        navigateFind(forward: true)
    }

    @objc private func findPrevious() {
        guard currentFindResults > 0 else { return }
        navigateFind(forward: false)
    }

    private func navigateFind(forward: Bool) {
        let js = """
        (function() {
            var highlights = document.querySelectorAll('.mdsee-highlight');
            if (highlights.length === 0) return JSON.stringify({count: 0, current: 0});

            var currentIndex = -1;
            for (var i = 0; i < highlights.length; i++) {
                if (highlights[i].classList.contains('mdsee-current')) {
                    currentIndex = i;
                    highlights[i].style.backgroundColor = '#ffff00';
                    highlights[i].classList.remove('mdsee-current');
                    break;
                }
            }

            var newIndex;
            if (\(forward)) {
                newIndex = (currentIndex + 1) >= highlights.length ? 0 : currentIndex + 1;
            } else {
                newIndex = (currentIndex - 1) < 0 ? highlights.length - 1 : currentIndex - 1;
            }

            highlights[newIndex].style.backgroundColor = '#ff9500';
            highlights[newIndex].classList.add('mdsee-current');
            highlights[newIndex].scrollIntoView({behavior: 'smooth', block: 'center'});

            return JSON.stringify({count: highlights.length, current: newIndex + 1});
        })();
        """

        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("Navigate error: \(error)")
                return
            }
            if let jsonString = result as? String,
               let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Int] {
                self?.currentFindResults = json["count"] ?? 0
                self?.currentFindIndex = json["current"] ?? 0
                self?.updateFindResultsLabel()
            }
        }
    }

    @objc private func useSelectionForFind() {
        let js = "window.getSelection().toString();"
        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let selectedText = result as? String, !selectedText.isEmpty {
                self?.showFindBar()
                self?.findTextField?.stringValue = selectedText
                self?.performFind(selectedText)
            }
        }
    }

    private func clearHighlights() {
        let js = """
        (function() {
            var highlights = document.querySelectorAll('.mdsee-highlight');
            highlights.forEach(function(el) {
                var text = document.createTextNode(el.textContent);
                el.parentNode.replaceChild(text, el);
            });
            document.body.normalize();
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func updateFindResultsLabel() {
        if currentFindResults == 0 {
            findResultsLabel?.stringValue = "No results"
        } else {
            findResultsLabel?.stringValue = "\(currentFindIndex) of \(currentFindResults)"
        }
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

extension AppDelegate: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let searchText = textField.stringValue
        if searchText.isEmpty {
            clearHighlights()
            findResultsLabel?.stringValue = ""
            currentFindResults = 0
            currentFindIndex = 0
        } else {
            performFind(searchText)
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape key - close find bar
            hideFindBar()
            return true
        } else if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter key - find next
            findNext()
            return true
        }
        return false
    }
}
