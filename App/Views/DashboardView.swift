import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: PlanStore
    @EnvironmentObject private var reminders: ReminderService
    @State private var showingEditor = false
    @State private var showingReminder = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                if let warning = store.persistenceWarning {
                    Notice(text: warning, symbol: "exclamationmark.triangle")
                }
                planCard
                timeCard
                OfficialBrowserCard()
                Notice(text: "这是一款独立的本地准备工具，与 Apple 无关联。商品、库存、时间与价格均以官网为准。")
                    .padding(.horizontal, 4)
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("购机准备")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑", systemImage: "slider.horizontal.3") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            PlanEditorView(plan: store.plan)
        }
        .sheet(isPresented: $showingReminder) { ReminderView() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("MY PURCHASE PLAN", systemImage: "iphone")
                .font(.caption.weight(.semibold)).tracking(1.6)
                .foregroundStyle(.white.opacity(0.75))
            Text("先准备好，\n再从容选择。")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("记住配置和预算，在你确认的时间前往官网。")
                .font(.subheadline).foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(LinearGradient(colors: [Color(red: 0.10, green: 0.17, blue: 0.32),
                                            Color(red: 0.19, green: 0.34, blue: 0.66)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28))
    }

    private var planCard: some View {
        Card {
            HStack {
                Label("我的计划", systemImage: "square.and.pencil").font(.headline)
                Spacer()
                Text("1 台").font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.10), in: Capsule())
            }
            DetailLine(label: "型号", value: store.plan.model)
            DetailLine(label: "颜色", value: store.plan.color)
            DetailLine(label: "容量", value: store.plan.storage)
            Divider()
            DetailLine(label: "预算上限 · 人民币", value: store.plan.budget.map(Money.display) ?? "未填写")
            if !store.plan.isConfigured {
                Button("设置我的购机计划") { showingEditor = true }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            Notice(text: "配置由你填写，不代表官网有该选项；预算不会限制 Safari 中的交易。")
        }
    }

    private var timeCard: some View {
        Card {
            Label("我设置的目标时间", systemImage: "clock").font(.headline)
            if store.plan.dateConfirmed {
                Text(targetLabel).font(.subheadline.weight(.medium))
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    countdown(now: context.date)
                }
                Text("时区：\(store.plan.timeZoneID)")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("还没有确认目标时间").font(.title3.weight(.semibold))
                Text("请根据官网信息设置。初始日期只是占位，不是开售日期。")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("设置时间") { showingEditor = true }.buttonStyle(.bordered)
            }
            Divider()
            Text(reminders.statusText).font(.footnote).foregroundStyle(.secondary)
            Button { showingReminder = true } label: {
                Label("管理本地提醒", systemImage: "bell")
            }.disabled(!store.plan.dateConfirmed)
        }
    }

    private var targetLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = store.plan.timeZone
        formatter.dateFormat = "yyyy 年 M 月 d 日 HH:mm"
        return formatter.string(from: store.plan.targetDate)
    }

    @ViewBuilder private func countdown(now: Date) -> some View {
        let value = Countdown(target: store.plan.targetDate, now: now)
        if value.hasReachedTarget {
            Text("已到你设置的时间")
                .font(.title2.weight(.semibold)).foregroundStyle(Theme.accent)
            Text("是否开售或有货，请手动查看官网。")
                .font(.footnote).foregroundStyle(.secondary)
        } else {
            HStack(spacing: 8) {
                timeUnit(value.days, "天")
                timeUnit(value.hours, "时")
                timeUnit(value.minutes, "分")
                timeUnit(value.seconds, "秒")
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("距离目标时间还有 \(value.days) 天 \(value.hours) 小时 \(value.minutes) 分钟 \(value.seconds) 秒")
        }
    }

    private func timeUnit(_ value: Int, _ unit: String) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%02d", value)).font(.title2.monospacedDigit().bold())
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(unit).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
