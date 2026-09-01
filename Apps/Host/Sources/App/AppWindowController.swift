import AppKit
import SwiftUI

/// Owns SwiftUI windows only while they are visible so their view graphs can be reclaimed.
@MainActor
final class AppWindowController: NSObject, NSWindowDelegate {
    private enum WindowKind: String {
        case settings = "FinderActions.Settings"
        case onboarding = "FinderActions.Onboarding"
    }

    private let appState: AppState
    private var settingsController: NSWindowController?
    private var onboardingController: NSWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func showSettings() {
        if let window = settingsController?.window {
            present(window)
            return
        }

        let rootView = SettingsRootView().environment(appState)
        let controller = makeWindowController(
            kind: .settings,
            title: NSLocalizedString("FinderActions Settings", comment: "Settings window title"),
            contentSize: NSSize(width: 940, height: 600),
            resizable: true,
            rootView: rootView
        )
        settingsController = controller
        present(controller.window)
    }

    func showOnboarding() {
        if let window = onboardingController?.window {
            present(window)
            return
        }

        let rootView = OnboardingView { [weak self] in
            self?.onboardingController?.close()
        }
        .environment(appState)
        let controller = makeWindowController(
            kind: .onboarding,
            title: NSLocalizedString("Set Up FinderActions", comment: "Onboarding window title"),
            contentSize: NSSize(width: 540, height: 500),
            resizable: false,
            rootView: rootView
        )
        onboardingController = controller
        present(controller.window)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let identifier = window.identifier?.rawValue,
              let kind = WindowKind(rawValue: identifier) else {
            return
        }

        // Break the window -> hosting controller -> SwiftUI graph chain immediately.
        window.contentViewController = nil
        switch kind {
        case .settings:
            settingsController = nil
        case .onboarding:
            onboardingController = nil
        }
    }

    private func makeWindowController<Content: View>(
        kind: WindowKind,
        title: String,
        contentSize: NSSize,
        resizable: Bool,
        rootView: Content
    ) -> NSWindowController {
        var styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
        if resizable {
            styleMask.insert(.resizable)
        }

        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: styleMask,
            backing: .buffered,
            defer: true
        )
        window.identifier = NSUserInterfaceItemIdentifier(kind.rawValue)
        window.title = title
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.setContentSize(contentSize)
        window.center()

        if kind == .settings {
            window.setFrameAutosaveName(kind.rawValue)
        }

        let controller = NSWindowController(window: window)
        // NSWindowController installs itself as the delegate during initialization.
        // Set our delegate afterwards so close events tear down the hosting graph.
        window.delegate = self
        return controller
    }

    private func present(_ window: NSWindow?) {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
