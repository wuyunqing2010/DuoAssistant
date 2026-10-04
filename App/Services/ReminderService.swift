import Foundation
import Combine
import UserNotifications

@MainActor
final class ReminderService: ObservableObject {
    @Published private(set) var statusText = "未设置提醒"
    @Published private(set) var isBusy = false
    @Published private(set) var nextFireDate: Date?
    @Published private(set) var permissionDenied = false
    private let center = UNUserNotificationCenter.current()
    private var generation = 0
    private let identifier = "purchaseAssistant.targetReminder.v1"

    func refresh() async {
        let settings = await center.notificationSettings()
        permissionDenied = settings.authorizationStatus == .denied
        let pending = await center.pendingNotificationRequests()
        if permissionDenied {
            nextFireDate = nil
            statusText = "通知权限已关闭；已设提醒可能无法显示"
        } else if let request = pending.first(where: { $0.identifier == identifier }),
                  let trigger = request.trigger as? UNCalendarNotificationTrigger,
                  let nextDate = trigger.nextTriggerDate(), nextDate > Date() {
            nextFireDate = nextDate
            statusText = "已设置：\(nextDate.formatted(date: .abbreviated, time: .shortened))（手机时区）"
        } else {
            nextFireDate = nil
            statusText = "未设置待触发提醒"
        }
    }

    func schedule(plan: PurchasePlan, lead: ReminderLead) async -> String {
        guard !isBusy else { return "正在处理，请稍候" }
        guard let fireDate = ReminderPolicy.fireDate(plan: plan, lead: lead, now: Date()) else {
            return "请先确认目标时间，并选择尚未过去的提醒时间"
        }
        isBusy = true
        generation += 1
        let operation = generation
        defer { isBusy = false }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard operation == generation else { return "本次设置已取消" }
            guard granted else {
                await refresh()
                return "没有通知权限。可在 iPhone 设置中开启，倒计时仍可使用。"
            }
            // Permission dialogs can remain open past the selected notification time.
            guard fireDate.timeIntervalSinceNow > 1 else {
                return "提醒时间已过去，请重新选择"
            }
            let content = UNMutableNotificationContent()
            content.title = "到你设置的准备时间了"
            content.body = "打开购机准备，核对计划后手动前往 Apple 官网。此提醒不代表官方开售。"
            content.sound = .default
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
            parts.calendar = calendar
            parts.timeZone = calendar.timeZone
            let request = UNNotificationRequest(identifier: identifier, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            // Same identifier replaces the earlier request without duplicate notifications.
            try await center.add(request)
            guard operation == generation else {
                center.removePendingNotificationRequests(withIdentifiers: [identifier])
                await refresh()
                return "本次设置已取消"
            }
            await refresh()
            return "本地提醒已设置。专注模式、通知设置和系统状态可能影响送达，请不要只依赖提醒。"
        } catch {
            await refresh()
            return "设置提醒失败：\(error.localizedDescription)"
        }
    }

    func cancel() async {
        generation += 1
        nextFireDate = nil
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        await refresh()
    }
}
