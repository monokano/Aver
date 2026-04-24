import AppKit
import SwiftUI

class ChangeLogWindowController: NSObject {
    private var window: NSWindow?

    func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let hosting = NSHostingView(rootView: ChangeLogView())

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = String(localized: "Change Log")
        win.contentView = hosting
        win.minSize = NSSize(width: 200, height: 200)
        win.isReleasedWhenClosed = false

        positionTopLeft(win)

        window = win
        win.makeKeyAndOrderFront(nil)
    }

    private func positionTopLeft(_ win: NSWindow) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let gap: CGFloat = 18
        let visible = screen.visibleFrame
        let x = visible.minX + gap
        let y = visible.maxY - win.frame.height - gap
        win.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
