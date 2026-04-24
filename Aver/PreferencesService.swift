import AppKit

struct PreferencesService {

    private enum Key {
        static let windowFrame = "WindowFrame"
        static let recentSelectedApp = "RecentSelectedApp"
    }

    // MARK: - Window frame

    static func saveWindowFrame(_ frame: NSRect) {
        let dict: [String: Double] = [
            "x": frame.origin.x,
            "y": frame.origin.y,
            "w": frame.size.width,
            "h": frame.size.height
        ]
        UserDefaults.standard.set(dict, forKey: Key.windowFrame)
    }

    static func loadWindowFrame() -> NSRect? {
        guard let dict = UserDefaults.standard.dictionary(forKey: Key.windowFrame),
              let x = dict["x"] as? Double,
              let y = dict["y"] as? Double,
              let w = dict["w"] as? Double,
              let h = dict["h"] as? Double
        else { return nil }
        return NSRect(x: x, y: y, width: w, height: h)
    }

    // MARK: - App filter

    static func saveRecentSelectedApp(_ value: String) {
        UserDefaults.standard.set(value, forKey: Key.recentSelectedApp)
    }

    static func loadRecentSelectedApp() -> String {
        UserDefaults.standard.string(forKey: Key.recentSelectedApp) ?? ""
    }

}
