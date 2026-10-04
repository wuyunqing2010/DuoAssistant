import SwiftUI

struct GuideView: View {
    var body: some View {
        List {
            Section("三步准备") {
                instruction("1", "记下你的选择", "根据官网填写型号、颜色、容量和含全部费用的预算。数量固定为 1 台。")
                instruction("2", "确认时间与提醒", "自行核实目标时间与时区。倒计时按手机当前时间计算，不与服务器校时；可设置一次本地提醒。")
                instruction("3", "前往官网手动完成", "在默认浏览器中选择商品并查看最终总额；需要时用人工核对页比对你填写的值。登录、验证码、最终提交和付款都由你完成。")
            }
            Section("你需要知道") {
                Label("不保证抢到或有货", systemImage: "shippingbox")
                Label("没有自动刷新、自动加购或自动下单", systemImage: "hand.tap")
                Label("不绕过验证码或排队，不操作多账户", systemImage: "person.crop.circle.badge.checkmark")
                Label("不会读取官网内容或拦截 Safari 付款", systemImage: "safari")
            }.font(.subheadline)
            Section("本机数据与隐私") {
                Text("购机计划保存在本机 App 的 UserDefaults。可能随 iOS 系统备份保存；无自建服务器、分析 SDK 或 App 自发网络请求。删除 App 会移除本机计划。")
                Text("不保存密码、Cookie、支付信息或收货地址。人工核对内容只保留在运行内存。浏览器中的数据与交易由浏览器和 Apple 网站处理。")
                Text("App 仅在你点击设置提醒后申请通知权限。没有相机、麦克风、位置或通讯录权限。")
            }.font(.footnote)
            Section("关于") {
                LabeledContent("版本", value: "1.0.0 · 全新源码")
                Text("独立开发的购机准备助手，与 Apple 无关联，也不代表任何产品已发布或正在销售。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("使用说明")
    }

    private func instruction(_ number: String, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.headline).foregroundStyle(Theme.accent)
                .frame(width: 30, height: 30)
                .background(Theme.accent.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 7)
    }
}
