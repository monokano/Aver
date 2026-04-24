import SwiftUI
import AppKit

struct AppRowView: View {
    let app: AdobeAppInfo
    let rowText: String
    var isSelected: Bool = false
    var isWindowKey: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            // 起動中インジケーター（選択中+キーウィンドウなら白）
            Circle()
                .fill(app.isRunning
                    ? (isSelected && isWindowKey ? Color.white : Color.blue)
                    : Color.clear)
                .frame(width: 7, height: 7)
                .padding(.leading, 2)
                .padding(.trailing, 6)

            // アプリアイコン
            Image(nsImage: app.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
                .padding(.trailing, 4)

            // アプリ名 + バージョン
            Text(rowText)
                .font(.system(size: 13))
                .lineLimit(1)

            Spacer()
        }
        .frame(height: 22)
        .contentShape(Rectangle())
    }
}
