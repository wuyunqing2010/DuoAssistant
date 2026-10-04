import SwiftUI
import UIKit

// Native semantic surfaces remain legible in both light and dark mode.
enum Theme {
    static let accent = Color(red: 0.16, green: 0.33, blue: 0.83)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let corner: CGFloat = 24
}

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner))
    }
}

struct DetailLine: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value.isEmpty ? "未填写" : value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct Notice: View {
    let text: String
    var symbol: String = "info.circle"
    var body: some View {
        Label {
            Text(text).font(.footnote).fixedSize(horizontal: false, vertical: true)
        } icon: { Image(systemName: symbol) }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
