import Foundation

/// A local wish list, never a representation of Apple's current catalog.
public struct PurchasePlan: Codable, Equatable {
    public var model: String
    public var color: String
    public var storage: String
    public var budgetText: String
    public var targetDate: Date
    public var timeZoneID: String
    public var dateConfirmed: Bool

    public static let quantity = 1
    public static let currency = "CNY"

    public init(model: String = "", color: String = "", storage: String = "",
                budgetText: String = "", targetDate: Date = Date().addingTimeInterval(86_400),
                timeZoneID: String = "Asia/Shanghai", dateConfirmed: Bool = false) {
        self.model = model
        self.color = color
        self.storage = storage
        self.budgetText = budgetText
        self.targetDate = targetDate
        self.timeZoneID = timeZoneID
        self.dateConfirmed = dateConfirmed
    }

    public var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }
    public var budget: Decimal? { Money.parse(budgetText) }
    public var hasProductSelection: Bool {
        [model, color, storage].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    public var isConfigured: Bool { hasProductSelection && budget != nil }
    public var summary: String { [model, color, storage].joined(separator: " · ") }

    public func validationIssues() -> [String] {
        var issues: [String] = []
        if !hasProductSelection { issues.append("请填齐型号、颜色和容量") }
        if budget == nil { issues.append("预算需为大于 0、最多两位小数的人民币金额") }
        if TimeZone(identifier: timeZoneID) == nil { issues.append("时区无效，请重新选择") }
        return issues
    }
}

public enum Money {
    /// Strict CNY entry: no grouping, exponents, currency symbols, NaN, or silent rounding.
    public static func parse(_ input: String) -> Decimal? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.range(of: #"^[0-9]{1,8}(\.[0-9]{1,2})?$"#,
                          options: .regularExpression) != nil,
              let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
              amount > 0, amount <= Decimal(string: "99999999.99")! else { return nil }
        return amount
    }

    public static func display(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .currency
        formatter.currencyCode = PurchasePlan.currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "金额无法显示"
    }
}
