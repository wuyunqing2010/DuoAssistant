import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PlanStore
    @EnvironmentObject private var reminders: ReminderService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("准备", systemImage: "square.grid.2x2") }
            NavigationStack { ManualReviewView() }
                .tabItem { Label("人工核对", systemImage: "checklist") }
            NavigationStack { GuideView() }
                .tabItem { Label("使用说明", systemImage: "questionmark.circle") }
        }
        .task { await reminders.refresh() }
        .task(id: reminders.nextFireDate) {
            // Observe the actual pending notification, not the reminder picker's lead time.
            // One local wake, no website/server polling.
            guard let date = reminders.nextFireDate else { return }
            let delay = max(0, date.timeIntervalSinceNow) + 2
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard !Task.isCancelled else { return }
            await reminders.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reminders.refresh() } }
        }
    }
}
