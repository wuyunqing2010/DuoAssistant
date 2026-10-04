import SwiftUI
import UIKit

struct PlanEditorView: View {
    @EnvironmentObject private var store: PlanStore
    @EnvironmentObject private var reminders: ReminderService
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PurchasePlan
    @State private var isSaving = false
    @State private var saveError: String?
    private let zones = ["Asia/Shanghai", "Asia/Hong_Kong", "Asia/Tokyo", "Europe/London", "America/Los_Angeles", "Etc/UTC"]

    init(plan: PurchasePlan) { _draft = State(initialValue: plan) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("型号（按官网填写）", text: $draft.model)
                    TextField("颜色（按官网填写）", text: $draft.color)
                    TextField("容量，例如 256GB", text: $draft.storage)
                    LabeledContent("数量", value: "1 台")
                } header: { Text("想买的配置") } footer: {
                    Text("不预设未经证实的型号、颜色或容量。输入只是你的计划，App 不检查库存。")
                }
                Section {
                    TextField("预算上限，例如 8999.00", text: $draft.budgetText)
                        .keyboardType(.decimalPad)
                    LabeledContent("币种", value: "人民币 CNY")
                } header: { Text("含全部费用的预算") } footer: {
                    Text("只接受数字和小数点，最多两位小数；不支持分期或订阅金额比较。")
                }
                Section {
                    Picker("显示和编辑时区", selection: $draft.timeZoneID) {
                        ForEach(availableZones, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("目标时间", selection: $draft.targetDate,
                               displayedComponents: [.date, .hourAndMinute])
                        .environment(\.timeZone, draft.timeZone)
                    Toggle("我已确认这个目标时间", isOn: $draft.dateConfirmed)
                } header: { Text("我设置的时间") } footer: {
                    Text("更换时区保持同一时刻，显示的钟点随之变化。日期或时区改动后需重新确认。保存任何计划改动都会取消旧提醒，之后请重新设置。")
                }
                if let saveError { Section { Text(saveError).foregroundStyle(.red) } }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle("编辑计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { Task { await save() } }.disabled(isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("收起键盘") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
            .onChange(of: draft.targetDate) { _, _ in draft.dateConfirmed = false }
            .onChange(of: draft.timeZoneID) { _, _ in draft.dateConfirmed = false }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private var availableZones: [String] {
        zones.contains(draft.timeZoneID) ? zones : zones + [draft.timeZoneID]
    }

    @MainActor private func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        // Partial wish lists may be saved; the review policy fails closed until complete.
        let changed = draft != store.plan
        guard store.save(draft) else {
            saveError = store.persistenceWarning
            return
        }
        if changed { await reminders.cancel() }
        dismiss()
    }
}
