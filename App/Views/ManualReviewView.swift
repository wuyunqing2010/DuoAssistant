import SwiftUI
import UIKit

struct ManualReviewView: View {
    @EnvironmentObject private var store: PlanStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var review = ManualReview()
    @State private var showResult = false
    @State private var checkedAt: Date?

    var body: some View {
        Form {
            Section {
                Notice(text: "请从官网页面逐项抄录。App 无法读取或验证该页面；没有看清的项目请留空，不要猜。核对结果只检查你填写的值。", symbol: "hand.raised")
            }
            Section("计划 · 数量固定 1 台") {
                DetailLine(label: "型号", value: store.plan.model)
                DetailLine(label: "颜色", value: store.plan.color)
                DetailLine(label: "容量", value: store.plan.storage)
                DetailLine(label: "预算", value: store.plan.budget.map(Money.display) ?? "尚未设置")
            }
            Section {
                TextField("页面型号", text: $review.model)
                TextField("页面颜色", text: $review.color)
                TextField("页面容量", text: $review.storage)
                TextField("页面数量（只能为 1）", text: $review.quantityText).keyboardType(.numberPad)
                TextField("最终总额（含全部费用）", text: $review.totalText).keyboardType(.decimalPad)
            } header: { Text("逐项填写官网所示内容") } footer: {
                Text("名称须与计划一致，不能用月供或估算价格代替总额。为避免误判，App 不猜测不同商品名称是否等价。")
            }
            Section("再确认一次") {
                Toggle("页面币种为人民币（CNY）", isOn: $review.currencyConfirmed)
                Toggle("填写总额包含页面全部费用", isOn: $review.allFeesIncluded)
                Toggle("一次性付款，无分期或额外订阅", isOn: $review.oneTimePaymentConfirmed)
            }
            Section {
                Button("检查我填写的值") { showResult = true; checkedAt = Date() }
                    .font(.headline)
                Button("清空本次核对", role: .destructive) { review = ManualReview(); showResult = false; checkedAt = nil }
            }
            if showResult {
                Section {
                    if result.isConsistent {
                        Label("填写值与计划一致", systemImage: "checkmark.circle")
                            .font(.headline).foregroundStyle(Theme.accent)
                        Text("尚未验证官网内容，也不代表可购买或已下单。回到浏览器后，请重新核对当前页面再自行决定是否提交。")
                    } else {
                        Label("信息未齐或存在不一致", systemImage: "exclamationmark.triangle")
                            .font(.headline).foregroundStyle(.orange)
                        ForEach(result.issues, id: \.self) { Text("• \($0)") }
                        Text("请停止核对流程，回官网确认，不要基于未知信息继续付款。")
                    }
                    if let checkedAt {
                        Text("本次检查：\(checkedAt.formatted(date: .omitted, time: .standard))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                Text("切换到浏览器或离开 App 时会隐藏核对结果并清除确认勾选，避免把上一次结果用于已变化的页面。核对内容不持久保存。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .navigationTitle("人工核对")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("收起键盘") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            }
        }
        .onChange(of: review) { _, _ in showResult = false; checkedAt = nil }
        .onChange(of: store.plan) { _, _ in review = ManualReview(); showResult = false; checkedAt = nil }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                showResult = false
                checkedAt = nil
                review.currencyConfirmed = false
                review.allFeesIncluded = false
                review.oneTimePaymentConfirmed = false
            }
        }
    }

    private var result: ReviewResult { ManualReviewPolicy.evaluate(plan: store.plan, review: review) }
}
