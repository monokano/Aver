import SwiftUI
import AppKit

/// SwiftUI List の内部 NSTableView に AppKit 固有の設定を適用するユーティリティ群。
///
/// 背景:
/// SwiftUI の List は macOS では内部的に NSTableView を使用するが、ストライプ表示／
/// 選択色の角丸／ダブルクリック処理／フォーカスリング抑制などの細かい挙動は
/// SwiftUI API だけでは調整できない。本ファイルは他の Xojo→Swift 移行アプリでも
/// 使い回せるように、List 背後の NSTableView に直接アクセスする橋渡しを提供する。

// MARK: - Coordinator

/// NSTableView の `doubleAction` を受ける Coordinator。
/// @StateObject で保持することで View の再生成に耐える。
@MainActor
final class TableCoordinator: NSObject, ObservableObject {
    /// ダブルクリックされた行インデックスを受け取るクロージャ
    var onDoubleClick: ((Int) -> Void)?
    private(set) var isConfigured = false

    @objc func doubleClicked(_ sender: Any?) {
        guard let tv = sender as? NSTableView else { return }
        let row = tv.clickedRow
        guard row >= 0 else { return }
        onDoubleClick?(row)
    }

    func markConfigured() { isConfigured = true }
}

// MARK: - Context Menu helpers

/// NSMenuItem 用クロージャホルダー。
/// target-action で closure を呼ぶための NSObject ラッパー。
final class BlockActionHandler: NSObject {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func run() { action() }
}

/// コンテキストメニュー項目の定義。
enum ContextMenuEntry {
    case item(title: String, action: () -> Void)
    case separator
}

/// 現在のマウス位置にコンテキストメニューをポップアップ表示する。
/// ダブルクリックメニューなど、ユーザージェスチャー外から呼び出す用途向け。
@MainActor
func popUpContextMenu(entries: [ContextMenuEntry]) {
    guard let window = NSApp.keyWindow,
          let view = window.contentView else { return }

    let menu = NSMenu()
    // クロージャホルダーを保持しないとメニュー表示中に解放される
    var handlers: [BlockActionHandler] = []

    for entry in entries {
        switch entry {
        case .separator:
            menu.addItem(.separator())
        case let .item(title, action):
            let handler = BlockActionHandler(action)
            handlers.append(handler)
            let menuItem = NSMenuItem(
                title: title,
                action: #selector(BlockActionHandler.run),
                keyEquivalent: ""
            )
            menuItem.target = handler
            menuItem.representedObject = handler
            menu.addItem(menuItem)
        }
    }

    let screenLoc = NSEvent.mouseLocation
    let windowLoc = window.convertPoint(fromScreen: screenLoc)
    guard let event = NSEvent.mouseEvent(
        with: .rightMouseDown,
        location: windowLoc,
        modifierFlags: [],
        timestamp: ProcessInfo.processInfo.systemUptime,
        windowNumber: window.windowNumber,
        context: nil,
        eventNumber: 0,
        clickCount: 1,
        pressure: 1.0
    ) else { return }

    NSMenu.popUpContextMenu(menu, with: event, for: view)
    _ = handlers // メニュー表示中にhandlersを生存させる
}

// MARK: - NSTableView configuration

/// SwiftUI List 配下の NSTableView を探し出して AppKit 設定を適用する。
///
/// List 初期化は非同期に行われるため、複数の遅延で再試行する。
/// - Parameters:
///   - coordinator: ダブルクリックを受け取る Coordinator
///   - alternatingRows: ストライプ背景を有効にする
///   - fullWidth: 選択色・ストライプを角なし端までフル幅で描画
///   - zeroInsets: NSScrollView の contentInsets をゼロに（上下余白を詰める）
///   - zeroIntercellSpacing: 行間スペースをゼロに
@MainActor
func configureListTableView(
    coordinator: TableCoordinator,
    alternatingRows: Bool = true,
    fullWidth: Bool = true,
    zeroInsets: Bool = true,
    zeroIntercellSpacing: Bool = true
) {
    for delay in [0.0, 0.1, 0.3, 0.6] {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let window = NSApp.windows.first(where: { !($0 is NSPanel) }),
                  let tableView = findTableView(in: window.contentView) else { return }

            if alternatingRows {
                tableView.usesAlternatingRowBackgroundColors = true
            }
            if fullWidth {
                tableView.style = .fullWidth
            }
            if zeroIntercellSpacing {
                tableView.intercellSpacing = NSSize(width: 0, height: 0)
            }
            tableView.focusRingType = .none

            if zeroInsets, let scrollView = tableView.enclosingScrollView {
                scrollView.automaticallyAdjustsContentInsets = false
                scrollView.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }

            if !coordinator.isConfigured {
                tableView.target = coordinator
                tableView.doubleAction = #selector(TableCoordinator.doubleClicked(_:))
                coordinator.markConfigured()
            }
        }
    }
}

/// ビュー階層を深さ優先で探索し、最初の NSTableView を返す。
private func findTableView(in view: NSView?) -> NSTableView? {
    guard let view else { return nil }
    if let tv = view as? NSTableView { return tv }
    for sub in view.subviews {
        if let found = findTableView(in: sub) { return found }
    }
    return nil
}
