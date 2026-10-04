import SwiftUI

@main
struct PurchaseAssistantApp: App {
    @StateObject private var store = PlanStore()
    @StateObject private var reminders = ReminderService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(reminders)
                .tint(Theme.accent)
        }
    }
}
