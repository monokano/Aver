import AppKit

struct AdobeAppScanner {

    static func scanAll() -> [AdobeAppInfo] {
        let appDir = URL(fileURLWithPath: "/Applications")
        guard let folders = try? FileManager.default.contentsOfDirectory(
            at: appDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        let runningApps = NSWorkspace.shared.runningApplications
        var allApps: [AdobeAppInfo] = []

        for folder in folders {
            guard folder.lastPathComponent.hasPrefix("Adobe "),
                  (try? folder.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            else { continue }

            guard let bundles = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for bundle in bundles {
                let name = bundle.lastPathComponent
                guard name.hasPrefix("Adobe "), name.hasSuffix(".app"),
                      (try? bundle.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                else { continue }

                guard let info = makeAppInfo(bundle: bundle, folder: folder, runningApps: runningApps)
                else { continue }

                allApps.append(info)
            }
        }

        return sorted(allApps)
    }

    // MARK: - Private

    private static func makeAppInfo(
        bundle: URL,
        folder: URL,
        runningApps: [NSRunningApplication]
    ) -> AdobeAppInfo? {
        let plistURL = bundle.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        guard var versionStr = plist["CFBundleShortVersionString"] as? String,
              !versionStr.isEmpty
        else { return nil }

        // Parse version: normalize to X.Y.Z, extract build if 4 parts
        var parts = versionStr.components(separatedBy: ".")
        if parts.count == 2 { parts.append("0") }

        var buildStr = ""
        if parts.count >= 4 { buildStr = parts.removeLast() }
        if parts.count > 3 { parts = Array(parts.prefix(3)) }

        if buildStr.isEmpty {
            buildStr = plist["Adobe Product Build"] as? String ?? ""
        }
        versionStr = parts.joined(separator: ".")

        let folderName = folder.lastPathComponent
        let releaseLabel: String
        if folderName.contains("Beta") {
            releaseLabel = "Beta"
        } else if folderName.contains("Prerelease") {
            releaseLabel = "Prerelease"
        } else {
            releaseLabel = ""
        }

        // Display name: use .app filename, strip "Adobe ", Beta/Prerelease labels
        let raw = bundle.lastPathComponent
        let nameLocal = raw.hasSuffix(".app") ? String(raw.dropLast(4)) : raw

        var nameDisplay = nameLocal
            .replacingOccurrences(of: "Adobe ", with: "")
            .replacingOccurrences(of: " (Beta)", with: "")
            .replacingOccurrences(of: " (Prerelease)", with: "")
            .replacingOccurrences(of: " Beta", with: "")
            .replacingOccurrences(of: " Prerelease", with: "")
            .replacingOccurrences(of: ".app", with: "")
            .trimmingCharacters(in: .whitespaces)

        let appSimpleName = nameDisplay.components(separatedBy: " ").first ?? nameDisplay

        if appSimpleName == "Illustrator", let major = Int(parts[0]) {
            nameDisplay = applyIllustratorYearName(name: nameDisplay, major: major)
        }

        let isRunning = runningApps.contains { app in
            app.bundleURL?.standardized == bundle.standardized
        }

        let icon = NSWorkspace.shared.icon(forFile: bundle.path)

        return AdobeAppInfo(
            appURL: bundle,
            appSimpleName: appSimpleName,
            nameDisplay: nameDisplay,
            version: versionStr,
            versionBuild: buildStr,
            releaseLabel: releaseLabel,
            isRunning: isRunning,
            icon: icon,
            versionDouble: makeVersionDouble(versionStr)
        )
    }

    /// Illustrator のメジャーバージョンから年号表記を付加する
    /// - 18〜23 → "CC 2014" 〜 "CC 2019"
    /// - 24〜   → "2020" 〜（CC なし）
    /// - それ以下は変更しない
    private static func applyIllustratorYearName(name: String, major: Int) -> String {
        guard major >= 18 else { return name }
        let year = major + 1996
        guard !name.contains("\(year)") else { return name }
        let suffix = (18...23).contains(major) ? "CC \(year)" : "\(year)"
        return name.replacingOccurrences(of: "Illustrator", with: "Illustrator \(suffix)")
    }

    private static func makeVersionDouble(_ ver: String) -> Double {
        var d: Double = 0
        let parts = ver.components(separatedBy: ".")
        for (i, part) in parts.enumerated() {
            let v = Double(part) ?? 0
            switch i {
            case 0: d += 1_000_000_000 * v
            case 1: d += 1_000_000 * v
            case 2: d += 1_000 * v
            default: break
            }
        }
        return d
    }

    private static func sorted(_ apps: [AdobeAppInfo]) -> [AdobeAppInfo] {
        let grouped = Dictionary(grouping: apps, by: { $0.appSimpleName })
        var result: [AdobeAppInfo] = []
        for key in grouped.keys.sorted() {
            let sorted = (grouped[key] ?? []).sorted { $0.versionDouble < $1.versionDouble }
            result.append(contentsOf: sorted)
        }
        return result
    }
}
