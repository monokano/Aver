import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var vm = ViewModel()
    @StateObject private var coordinator = TableCoordinator()
    @State private var isWindowKey = true

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            listView
            Divider()
            Color.clear.frame(height: 16)
        }
        .frame(minWidth: 300, minHeight: 300)
        .focusedSceneObject(vm)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in isWindowKey = true }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in isWindowKey = false }
        .onAppear {
            coordinator.onDoubleClick = { [vm] row in
                let apps = vm.displayedApps
                guard row >= 0, row < apps.count else { return }
                showContextMenu(for: apps[row])
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        Text(vm.labelText)
            .font(.system(size: 13))
            .lineLimit(nil)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .padding(.leading, 10)
    }

    // MARK: - List

    private var listView: some View {
        List(selection: $vm.selectedID) {
            ForEach(vm.displayedApps) { app in
                AppRowView(
                    app: app,
                    rowText: app.rowText(),
                    isSelected: vm.selectedID == app.id,
                    isWindowKey: isWindowKey
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowSeparator(.hidden)
                .tag(app.id)
                .contextMenu {
                    Button(String(localized: "Copy Selected Row")) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(app.rowText(), forType: .string)
                    }
                    Divider()
                    Button(String(localized: "Show in Finder")) {
                        NSWorkspace.shared.activateFileViewerSelecting([app.appURL])
                    }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .environment(\.defaultMinListRowHeight, 22)
        .onAppear { configureListTableView(coordinator: coordinator) }
    }

    // MARK: - Context Menu（ダブルクリック用）

    private func showContextMenu(for app: AdobeAppInfo) {
        popUpContextMenu(entries: [
            .item(title: String(localized: "Copy Selected Row")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(app.rowText(), forType: .string)
            },
            .separator,
            .item(title: String(localized: "Show in Finder")) {
                NSWorkspace.shared.activateFileViewerSelecting([app.appURL])
            }
        ])
    }
}
