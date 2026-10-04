import SwiftUI

struct OfficialBrowserCard: View {
    @Environment(\.openURL) private var openURL
    @State private var openFailed = false

    var body: some View {
        Card {
            Label("前往官方页面", systemImage: "safari").font(.headline)
            Text("在系统默认浏览器中打开 Apple 中国官网，由你选择配置、登录并完成交易。")
                .font(.subheadline).foregroundStyle(.secondary)
            Text("www.apple.com.cn").font(.caption.monospaced()).foregroundStyle(.secondary)
            Button { open(OfficialDestination.iPhone) } label: {
                Label("打开 iPhone 官网", systemImage: "arrow.up.right")
                    .frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).controlSize(.large)
            Button("官网入口打不开？打开 Apple 商店首页") { open(OfficialDestination.store) }
                .font(.footnote)
            Notice(text: "App 不读取浏览器页面，也不能拦截或限制付款。最终提交和支付由你手动操作。请在浏览器中检查网址、商品、总额和条款。", symbol: "hand.raised")
        }
        .alert("未能打开浏览器", isPresented: $openFailed) {
            Button("好", role: .cancel) {}
        } message: {
            Text("请打开 Safari 或你的默认浏览器，手动访问 www.apple.com.cn。")
        }
    }

    private func open(_ url: URL) {
        guard OfficialDestination.isAllowedInitialURL(url) else { openFailed = true; return }
        openURL(url) { accepted in openFailed = !accepted }
    }
}
