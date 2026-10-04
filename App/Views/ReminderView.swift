import SwiftUI
import UIKit
import Combine

struct ReminderView: View {
    @EnvironmentObject private var store: PlanStore
    @EnvironmentObject private var reminders: ReminderService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var lead = ReminderLead.fiveMinutes
    @State private var message: String?
    @State private var currentDate = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("提醒时机", selection: $lead) {
                        ForEach(ReminderLead.allCases) { Text($0.label).tag($0) }
                    }
                    Text(reminders.statusText).font(.subheadline)
                    Button("设置 / 替换提醒") {
                        Task { message = await reminders.schedule(plan: store.plan, lead: lead) }
                    }.disabled(reminders.isBusy || !canSchedule)
                    if !canSchedule {
                        Text("所选提醒时间已过去，或目标时间尚未确认。请编辑计划或改选提醒时机。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Button("取消本 App 的提醒", role: .destructive) {
                        Task { await reminders.cancel(); message = "已取消本 App 的提醒" }
                    }.disabled(reminders.isBusy)
                }
                if reminders.permissionDenied {
                    Section {
                        Button("打开 iPhone 通知设置") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    }
                }
                Section {
                    Text("首次设置会请求通知权限。提醒只在本机安排，不需服务器；不会自动打开页面或下单。系统可能延迟或静音通知，前台也可能不显示横幅。")
                    Text("提醒内容不含你的配置和预算。修改计划后需要重新设置提醒。")
                }.font(.footnote).foregroundStyle(.secondary)
                if let message { Section { Text(message) } }
            }
            .navigationTitle("本地提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() }.disabled(reminders.isBusy) } }
            .interactiveDismissDisabled(reminders.isBusy)
            .task { await reminders.refresh() }
            .onReceive(ticker) { currentDate = $0 }
            .onChange(of: canSchedule) { _, _ in Task { await reminders.refresh() } }
        }
    }

    private var canSchedule: Bool {
        ReminderPolicy.fireDate(plan: store.plan, lead: lead, now: currentDate) != nil
    }
}
