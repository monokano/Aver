import AppKit

struct AdobeAppInfo: Identifiable {
    let id = UUID()
    var appURL: URL
    var appSimpleName: String
    var nameDisplay: String
    var version: String
    var versionBuild: String
    var releaseLabel: String  // "Beta", "Prerelease", or ""
    var isRunning: Bool
    var icon: NSImage
    var versionDouble: Double

    func rowText() -> String {
        var buildSuffix = ""
        if !releaseLabel.isEmpty && !versionBuild.isEmpty {
            let isNumeric = versionBuild.allSatisfy(\.isNumber)
            buildSuffix = isNumeric ? " #\(versionBuild)" : ", \(versionBuild)"
        }

        let appName = nameDisplay
            .replacingOccurrences(of: ".app", with: "")
            .trimmingCharacters(in: .whitespaces)

        let labelPart = releaseLabel.isEmpty ? "" : " (\(releaseLabel))"
        return "\(appName)\(labelPart) (\(version)\(buildSuffix))"
    }
}
