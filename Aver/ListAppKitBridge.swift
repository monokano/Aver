import SwiftUI
import AppKit

// MARK: - TableCoordinator

/// NSTableView のダブルクリックを受け取る Coordinator。
/// @StateObject で保持することで View の再生成に耐える。
@MainActor
final class TableCoordinator: NSObject, ObservableObject {
    var onDoubleClick: ((Int) -> Void)?
    private(set) var isConfigured = false

    @objc func doubleClicked(_ sender: Any?) {
        guard let tv = sender as? NSTableView, tv.clickedRow >= 0 else { return }
        onDoubleClick?(tv.clickedRow)
    }

    func markConfigured() { isConfigured = true }
}

// MARK: - TableViewConfiguration

/// NSTableView に適用する外観設定。
struct TableViewConfiguration {
    var alternatingRows: Bool       = true
    var fullWidth: Bool             = true
    var zeroInsets: Bool            = true
    var zeroIntercellSpacing: Bool  = true
}

// MARK: - View Modifier

extension View {
    /// SwiftUI List 配下の NSTableView に AppKit 設定を適用する View Modifier。
    ///
    /// 使用例:
    ///   List { ... }
    ///       .configureTableView(coordinator: coordinator)
    func configureTableView(
        _ config: TableViewConfiguration = .init(),
        coordinator: TableCoordinator? = nil
    ) -> some View {
        background(_TableViewAccessor(config: config, coordinator: coordinator))
    }
}

// MARK: - NSViewRepresentable

private struct _TableViewAccessor: NSViewRepresentable {
    let config: TableViewConfiguration
    let coordinator: TableCoordinator?

    func makeNSView(context: Context) -> _AccessorView {
        _AccessorView(config: config, coordinator: coordinator)
    }
    func updateNSView(_ nsView: _AccessorView, context: Context) {}
}

private final class _AccessorView: NSView {
    private let config: TableViewConfiguration
    private weak var coordinator: TableCoordinator?
    private var applied = false

    init(config: TableViewConfiguration, coordinator: TableCoordinator?) {
        self.config = config
        self.coordinator = coordinator
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    /// ウインドウに追加されたタイミングで NSTableView を探して設定を適用する。
    /// viewDidMoveToWindow は SwiftUI の初期化完了後に呼ばれるため、
    /// 遅延リトライ不要で確実に NSTableView を取得できる。
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard !applied, window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.applied,
                  let tv = self.nearestTableView() else { return }
            self.applied = true
            self.apply(to: tv)
        }
    }

    private func apply(to tv: NSTableView) {
        if config.alternatingRows      { tv.usesAlternatingRowBackgroundColors = true }
        if config.fullWidth            { tv.style = .fullWidth }
        if config.zeroIntercellSpacing { tv.intercellSpacing = .zero }
        tv.focusRingType = .none

        if config.zeroInsets, let sv = tv.enclosingScrollView {
            sv.automaticallyAdjustsContentInsets = false
            sv.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }

        if let coord = coordinator, !coord.isConfigured {
            tv.target = coord
            tv.doubleAction = #selector(TableCoordinator.doubleClicked(_:))
            coord.markConfigured()
        }
    }

    /// 祖先ビューを上方向にたどりながら NSTableView を探す。
    private func nearestTableView() -> NSTableView? {
        var ancestor: NSView? = superview
        while let v = ancestor {
            if let found = firstTableView(in: v) { return found }
            ancestor = v.superview
        }
        return nil
    }

    private func firstTableView(in view: NSView) -> NSTableView? {
        if let tv = view as? NSTableView { return tv }
        if let sv = view as? NSScrollView, let tv = sv.documentView as? NSTableView { return tv }
        for sub in view.subviews where sub !== self {
            if let found = firstTableView(in: sub) { return found }
        }
        return nil
    }
}

// MARK: - Context Menu

/// コンテキストメニュー項目の定義。
enum ContextMenuEntry {
    case item(title: String, action: () -> Void)
    case separator
}

/// 現在のマウス位置にコンテキストメニューをポップアップ表示する。
/// ダブルクリックなど、SwiftUI の contextMenu 外から呼び出す用途向け。
@MainActor
func popUpContextMenu(entries: [ContextMenuEntry]) {
    guard let window = NSApp.keyWindow,
          let contentView = window.contentView else { return }

    let menu = NSMenu()
    for entry in entries {
        switch entry {
        case .separator:
            menu.addItem(.separator())
        case let .item(title, action):
            let handler = BlockActionHandler(action)
            let item = NSMenuItem(
                title: title,
                action: #selector(BlockActionHandler.run),
                keyEquivalent: ""
            )
            item.target = handler
            item.representedObject = handler  // メニュー存続中は item が handler を保持
            menu.addItem(item)
        }
    }

    let loc = window.convertPoint(fromScreen: NSEvent.mouseLocation)
    guard let event = NSEvent.mouseEvent(
        with: .rightMouseDown, location: loc, modifierFlags: [],
        timestamp: ProcessInfo.processInfo.systemUptime,
        windowNumber: window.windowNumber, context: nil,
        eventNumber: 0, clickCount: 1, pressure: 1.0
    ) else { return }

    NSMenu.popUpContextMenu(menu, with: event, for: contentView)
}

// MARK: - BlockActionHandler

/// NSMenuItem の target-action でクロージャを呼ぶための NSObject ラッパー。
final class BlockActionHandler: NSObject {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func run() { action() }
}
