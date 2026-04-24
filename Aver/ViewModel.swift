import AppKit
import Combine

@MainActor
final class ViewModel: ObservableObject {
    @Published var apps: [AdobeAppInfo] = []
    @Published var selectedID: UUID? = nil
    @Published var macOSInfo: String = ""
    @Published var filterAppName: String = ""

    let changeLogController = ChangeLogWindowController()

    private var cancellables = Set<AnyCancellable>()

    var selectedApp: AdobeAppInfo? {
        displayedApps.first { $0.id == selectedID }
    }

    var displayedApps: [AdobeAppInfo] {
        if filterAppName.isEmpty { return apps }
        let filtered = apps.filter { $0.nameDisplay.contains(filterAppName) }
        return filtered.isEmpty ? apps : filtered
    }

    var labelText: String {
        var text = macOSInfo
        if let selected = selectedApp {
            text += "\n" + selected.rowText()
        }
        return text
    }

    var uniqueAppNames: [String] {
        Array(Set(apps.map { $0.appSimpleName })).sorted()
    }

    init() {
        filterAppName = PreferencesService.loadRecentSelectedApp()
        macOSInfo = SystemInfoService.getInfo()
        apps = AdobeAppScanner.scanAll()

        $filterAppName
            .dropFirst()
            .sink { PreferencesService.saveRecentSelectedApp($0) }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func refresh() {
        macOSInfo = SystemInfoService.getInfo()
        apps = AdobeAppScanner.scanAll()
        selectedID = nil
    }

    func copyLabel(shiftHeld: Bool = false) {
        let text: String
        if shiftHeld {
            var lines = [macOSInfo, ""]
            lines += displayedApps.map { $0.rowText() }
            text = lines.joined(separator: "\n")
        } else {
            text = labelText
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func copySelectedRow() {
        guard let app = selectedApp else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(app.rowText(), forType: .string)
    }

    func showInFinder() {
        guard let app = selectedApp else { return }
        NSWorkspace.shared.activateFileViewerSelecting([app.appURL])
    }

    func showChangeLog() {
        changeLogController.show()
    }

    func setFilter(_ name: String) {
        filterAppName = name
        selectedID = nil
    }
}
