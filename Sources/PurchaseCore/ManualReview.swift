import Foundation

/// User transcribed values. This type contains no scraped or verified website data.
public struct ManualReview: Equatable {
    public var model = ""
    public var color = ""
    public var storage = ""
    public var quantityText = ""
    public var totalText = ""
    public var currencyConfirmed = false
    public var allFeesIncluded = false
    public var oneTimePaymentConfirmed = false

    public init() {}
}

public struct ReviewResult: Equatable {
    public let issues: [String]
    public let enteredTotal: Decimal?
    public var isConsistent: Bool { issues.isEmpty }
}

public enum ManualReviewPolicy {
    private static func normalized(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").lowercased()
    }

    public static func evaluate(plan: PurchasePlan, review: ManualReview) -> ReviewResult {
        var issues = plan.validationIssues()
        for (name, expected, actual) in [("型号", plan.model, review.model),
                                         ("颜色", plan.color, review.color),
                                         ("容量", plan.storage, review.storage)] {
            if normalized(actual).isEmpty {
                issues.append("尚未填写页面上的\(name)")
            } else if normalized(actual) != normalized(expected) {
                issues.append("页面\(name)与计划不一致，请回官网核对")
            }
        }
        if review.quantityText.trimmingCharacters(in: .whitespacesAndNewlines) != "1" {
            issues.append("页面数量必须明确为 1 台")
        }
        let total = Money.parse(review.totalText)
        if total == nil { issues.append("尚未填写有效的最终总额") }
        if let total, let budget = plan.budget, total > budget {
            issues.append("填写总额超过预算，请停止并重新核对")
        }
        if !review.currencyConfirmed { issues.append("尚未确认官网币种为人民币（CNY）") }
        if !review.allFeesIncluded { issues.append("尚未确认总额包含页面全部费用") }
        if !review.oneTimePaymentConfirmed { issues.append("尚未确认这是一次性付款，无分期或额外订阅") }
        return ReviewResult(issues: issues, enteredTotal: total)
    }
}
