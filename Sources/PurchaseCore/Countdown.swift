import Foundation

public struct Countdown: Equatable {
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int
    public let hasReachedTarget: Bool

    public init(target: Date, now: Date) {
        let raw = max(0, target.timeIntervalSince(now))
        let remaining = Int(min(ceil(raw), Double(Int.max / 2)))
        days = remaining / 86_400
        hours = (remaining % 86_400) / 3_600
        minutes = (remaining % 3_600) / 60
        seconds = remaining % 60
        hasReachedTarget = target <= now
    }
}

public enum ReminderLead: Int, CaseIterable, Codable, Identifiable {
    case atTime = 0
    case fiveMinutes = 300
    case fifteenMinutes = 900
    public var id: Int { rawValue }
    public var label: String {
        switch self {
        case .atTime: return "目标时间"
        case .fiveMinutes: return "提前 5 分钟"
        case .fifteenMinutes: return "提前 15 分钟"
        }
    }
}

public enum ReminderPolicy {
    public static func fireDate(plan: PurchasePlan, lead: ReminderLead, now: Date) -> Date? {
        guard plan.dateConfirmed, TimeZone(identifier: plan.timeZoneID) != nil else { return nil }
        let date = plan.targetDate.addingTimeInterval(-Double(lead.rawValue))
        // Never silently send an immediate notification for a past lead time.
        return date.timeIntervalSince(now) > 1 ? date : nil
    }
}
