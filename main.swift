import Cocoa
import WebKit

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// The game itself. Anything on this host (and its subdomains) stays inside
/// the app window.
let gameURL = URL(string: "https://shadowfight2.com/play/")!
let gameHost = "shadowfight2.com"

/// Returns true if `host` is the game's own domain or a subdomain of it
/// (e.g. "cdn.shadowfight2.com"), so normal in-game navigation / assets /
/// ajax calls are never sent out to the browser.
func isGameHost(_ host: String?) -> Bool {
    guard let host = host?.lowercased() else { return false }
    return host == gameHost || host.hasSuffix("." + gameHost)
}

// ---------------------------------------------------------------------------
// AppDelegate
// ---------------------------------------------------------------------------

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var navHandler: NavigationHandler!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()

        let frame = NSRect(x: 0, y: 0, width: 1280, height: 800)
        webView = WKWebView(frame: frame, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.allowsBackForwardNavigationGestures = true

        navHandler = NavigationHandler()
        webView.navigationDelegate = navHandler
        webView.uiDelegate = navHandler

        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shadow Fight 2"
        window.center()
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)

        webView.load(URLRequest(url: gameURL))

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        buildMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// Minimal app menu so Cmd-Q, Cmd-W, copy/paste etc. work as expected.
    private func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Shadow Fight 2", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }
}

// ---------------------------------------------------------------------------
// NavigationHandler
//
// Keeps normal gameplay inside the WKWebView, but sends anything that looks
// like a login / OAuth flow (Google, Facebook, Apple, etc.) or any link to a
// different site out to the user's default browser instead.
// ---------------------------------------------------------------------------

final class NavigationHandler: NSObject, WKNavigationDelegate, WKUIDelegate {

    // Top-level navigations (address changes in the main frame, e.g. the
    // page itself redirecting to accounts.google.com for sign-in).
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? false

        if isGameHost(url.host) {
            decisionHandler(.allow)
            return
        }

        // Any main-frame navigation away from the game's own domain (login
        // providers, help pages, external links, etc.) opens in the
        // system's default browser instead of hijacking the app window.
        if isMainFrame {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // Non-main-frame (iframe) requests to third parties, e.g. an
        // embedded OAuth iframe, are allowed through — WebKit needs this
        // for some sign-in widgets to render at all. Only a real top-level
        // redirect is treated as "the user is trying to log in".
        decisionHandler(.allow)
    }

    // window.open(...) / target="_blank" popups (many "Sign in with
    // Google" buttons use this instead of a same-tab redirect).
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
