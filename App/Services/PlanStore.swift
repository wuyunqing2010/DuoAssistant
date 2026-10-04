import Foundation
import SwiftUI

@MainActor
final class PlanStore: ObservableObject {
    @Published private(set) var plan: PurchasePlan
    @Published private(set) var persistenceWarning: String?
    private let defaults: UserDefaults
    private let key = "purchaseAssistant.plan.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key) {
            do {
                let decoded = try JSONDecoder().decode(PurchasePlan.self, from: data)
                if TimeZone(identifier: decoded.timeZoneID) != nil {
                    plan = decoded
                } else {
                    plan = PurchasePlan()
                    persistenceWarning = "已存计划的时区无效，请重新设置。旧记录没有被覆盖。"
                }
            } catch {
                plan = PurchasePlan()
                persistenceWarning = "暂时无法读取本机计划，请重新设置。旧记录没有被覆盖。"
            }
        } else {
            plan = PurchasePlan()
        }
    }

    @discardableResult
    func save(_ draft: PurchasePlan) -> Bool {
        do {
            let data = try JSONEncoder().encode(draft)
            defaults.set(data, forKey: key)
            plan = draft
            persistenceWarning = nil
            return true
        } catch {
            persistenceWarning = "保存失败，当前计划未更改，请重试。"
            return false
        }
    }
}
