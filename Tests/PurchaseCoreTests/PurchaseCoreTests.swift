import XCTest
@testable import PurchaseCore

final class PurchaseCoreTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func plan(budget: String = "10000") -> PurchasePlan {
        PurchasePlan(model: "示例型号 A", color: "示例颜色", storage: "256GB",
                     budgetText: budget, targetDate: now.addingTimeInterval(3600),
                     timeZoneID: "Asia/Shanghai", dateConfirmed: true)
    }

    private func review(total: String = "9999") -> ManualReview {
        var value = ManualReview()
        value.model = "示例型号 A"
        value.color = "示例颜色"
        value.storage = "256GB"
        value.quantityText = "1"
        value.totalText = total
        value.currencyConfirmed = true
        value.allFeesIncluded = true
        value.oneTimePaymentConfirmed = true
        return value
    }

    func testMoneyAcceptsCentsAndTrimsOuterWhitespace() {
        XCTAssertEqual(Money.parse(" 123.45 "), Decimal(string: "123.45"))
        XCTAssertEqual(Money.parse("1"), Decimal(1))
        XCTAssertEqual(Money.parse("99999999.99"), Decimal(string: "99999999.99"))
    }

    func testMoneyRejectsUnsafeOrAmbiguousInput() {
        for invalid in ["", "0", "0.00", "-1", "NaN", "Infinity", "1e3", "¥9999", "1,000", "1.001", "100000000", ".5", "1.", "12 34", "１２３"] {
            XCTAssertNil(Money.parse(invalid), invalid)
        }
    }

    func testCountdownUsesAbsoluteDatesAndNeverGoesNegative() {
        let value = Countdown(target: now.addingTimeInterval(90061), now: now)
        XCTAssertEqual(value.days, 1)
        XCTAssertEqual(value.hours, 1)
        XCTAssertEqual(value.minutes, 1)
        XCTAssertEqual(value.seconds, 1)
        XCTAssertFalse(value.hasReachedTarget)
        let ended = Countdown(target: now.addingTimeInterval(-10), now: now)
        XCTAssertEqual(ended.seconds, 0)
        XCTAssertTrue(ended.hasReachedTarget)
    }

    func testCountdownRoundsFutureFractionUp() {
        let value = Countdown(target: now.addingTimeInterval(0.1), now: now)
        XCTAssertEqual(value.seconds, 1)
        XCTAssertFalse(value.hasReachedTarget)
    }

    func testBlankPlanCannotBeReady() {
        XCTAssertFalse(PurchasePlan().isConfigured)
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: PurchasePlan(), review: review()).isConsistent)
    }

    func testMatchingReviewAtBudgetIsConsistent() {
        let result = ManualReviewPolicy.evaluate(plan: plan(), review: review(total: "10000.00"))
        XCTAssertTrue(result.isConsistent)
        XCTAssertEqual(result.enteredTotal, Decimal(10000))
    }

    func testOneCentOverBudgetFailsClosed() {
        let result = ManualReviewPolicy.evaluate(plan: plan(), review: review(total: "10000.01"))
        XCTAssertFalse(result.isConsistent)
        XCTAssertTrue(result.issues.contains { $0.contains("超过预算") })
    }

    func testMissingValuesAndUnconfirmedFactsFailClosed() {
        var value = review()
        value.totalText = ""
        value.currencyConfirmed = false
        value.allFeesIncluded = false
        value.oneTimePaymentConfirmed = false
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
    }

    func testQuantityMustBeExplicitlyOne() {
        for quantity in ["", "0", "2", "01", "1.0", "一"] {
            var value = review()
            value.quantityText = quantity
            XCTAssertFalse(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
        }
    }

    func testConfigurationMismatchFailsClosed() {
        var value = review()
        value.storage = "512GB"
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
        value = review()
        value.color = "另一颜色"
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
        value = review()
        value.model = "另一型号"
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
    }

    func testOuterWhitespaceAndLetterCaseAreNormalized() {
        var value = review()
        value.model = "  示例型号 a  "
        value.storage = "256gb"
        XCTAssertTrue(ManualReviewPolicy.evaluate(plan: plan(), review: value).isConsistent)
    }

    func testReminderRequiresConfirmedFutureDate() {
        var value = plan()
        XCTAssertEqual(ReminderPolicy.fireDate(plan: value, lead: .fiveMinutes, now: now), now.addingTimeInterval(3300))
        value.dateConfirmed = false
        XCTAssertNil(ReminderPolicy.fireDate(plan: value, lead: .atTime, now: now))
        value.dateConfirmed = true
        value.targetDate = now.addingTimeInterval(200)
        XCTAssertNil(ReminderPolicy.fireDate(plan: value, lead: .fiveMinutes, now: now))
        XCTAssertNotNil(ReminderPolicy.fireDate(plan: value, lead: .atTime, now: now))
    }

    func testUnknownTimeZoneBlocksReviewAndReminder() {
        var value = plan()
        value.timeZoneID = "Invalid/Zone"
        XCTAssertNil(ReminderPolicy.fireDate(plan: value, lead: .atTime, now: now))
        XCTAssertFalse(ManualReviewPolicy.evaluate(plan: value, review: review()).isConsistent)
    }

    func testChangingDisplayTimeZoneKeepsAbsoluteInstant() {
        var value = plan()
        let original = value.targetDate
        value.timeZoneID = "America/Los_Angeles"
        XCTAssertEqual(value.targetDate, original)
        XCTAssertEqual(ReminderPolicy.fireDate(plan: value, lead: .atTime, now: now), original)
    }

    func testPlanCodableRoundTrip() throws {
        let original = plan()
        let data = try JSONEncoder().encode(original)
        XCTAssertEqual(try JSONDecoder().decode(PurchasePlan.self, from: data), original)
    }

    func testOnlyExactOfficialInitialDestinationsAreAllowed() throws {
        XCTAssertTrue(OfficialDestination.isAllowedInitialURL(OfficialDestination.iPhone))
        XCTAssertTrue(OfficialDestination.isAllowedInitialURL(OfficialDestination.store))
        for path in ["/iphone", "/iphone/", "/store", "/store/"] {
            let url = try XCTUnwrap(URL(string: "https://www.apple.com.cn" + path))
            XCTAssertTrue(OfficialDestination.isAllowedInitialURL(url), path)
        }
        for text in [
            "http://www.apple.com.cn/iphone/",
            "https://www.apple.com.cn.evil.example/iphone/",
            "https://www.apple.com.cn@evil.example/iphone/",
            "https://user:password@www.apple.com.cn/iphone/",
            "https://www.apple.com.cn/iphone/?next=evil",
            "https://www.apple.com.cn/iphone/?",
            "https://www.apple.com.cn:443/iphone/",
            "https://www.apple.com.cn:444/iphone/",
            "https://www.apple.com.cn/iphone-duo/",
            "https://www.apple.com.cn/iphone/#x",
            "https://www.apple.com.cn/iphone/#",
            "https://www.apple.com.cn/iphone//",
            "https://www.apple.com.cn//iphone/",
            "https://www.apple.com.cn/iphone/../store",
            "https://www.apple.com.cn/iphone%2F",
            "https://www.apple.com.cn/%69phone/",
            "https://www.apple.com.cn/storefront"
        ] {
            XCTAssertFalse(OfficialDestination.isAllowedInitialURL(try XCTUnwrap(URL(string: text))), text)
        }
    }

    func testOfflineReviewFixtures() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "manual-review", withExtension: "json"))
        let cases = try JSONDecoder().decode([ReviewFixture].self, from: Data(contentsOf: url))
        for fixture in cases {
            var entered = review(total: fixture.total)
            entered.quantityText = fixture.quantity
            entered.storage = fixture.storage
            entered.currencyConfirmed = fixture.currencyConfirmed
            entered.allFeesIncluded = fixture.feesConfirmed
            entered.oneTimePaymentConfirmed = fixture.oneTimeConfirmed
            let result = ManualReviewPolicy.evaluate(plan: plan(budget: fixture.budget), review: entered)
            XCTAssertEqual(result.isConsistent, fixture.expectedConsistent, fixture.name)
        }
    }
}

private struct ReviewFixture: Decodable {
    let name: String
    let budget: String
    let total: String
    let quantity: String
    let storage: String
    let currencyConfirmed: Bool
    let feesConfirmed: Bool
    let oneTimeConfirmed: Bool
    let expectedConsistent: Bool
}
