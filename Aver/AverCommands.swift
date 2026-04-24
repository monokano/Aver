import SwiftUI

struct AverCommands: Commands {
    @FocusedObject private var vm: ViewModel?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandGroup(replacing: .undoRedo) {}

        // Edit メニュー: 選択行をコピー
        CommandGroup(after: .pasteboard) {
            Divider()
            Button(String(localized: "Copy Selected Row")) {
                vm?.copySelectedRow()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(vm?.selectedApp == nil)
        }

        // File メニュー: Finderで表示
        CommandGroup(after: .saveItem) {
            Button(String(localized: "Show in Finder")) {
                vm?.showInFinder()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(vm?.selectedApp == nil)
        }

        // 表示メニュー: 更新 + フィルタ
        CommandGroup(before: .sidebar) {
            Button(String(localized: "Refresh")) {
                vm?.refresh()
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Menu(String(localized: "Filter")) {
                Picker(selection: Binding(
                    get: { vm?.filterAppName ?? "" },
                    set: { vm?.setFilter($0) }
                ), label: EmptyView()) {
                    Text(String(localized: "All")).tag("")
                    ForEach(vm?.uniqueAppNames ?? [], id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Divider()
        }

        // Help メニュー: 変更履歴
        CommandGroup(replacing: .help) {
            Button(String(localized: "Change Log")) {
                vm?.showChangeLog()
            }
        }
    }
}
