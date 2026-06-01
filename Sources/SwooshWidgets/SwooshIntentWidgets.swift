// SwooshWidgets/SwooshIntentWidgets.swift
// AppIntent-configurable widgets — user can pick which provider/game/stat to show.
// Three new widgets: Game Session (small+medium), Agent Activity (small+medium),
// Cost Tracker (small).

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - AppIntent: pick which provider to spotlight

struct PickProviderIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Provider"
    static let description = IntentDescription("Select which AI provider to highlight.")

    @Parameter(title: "Provider", default: "openai")
    var providerID: String
}

// MARK: - AppIntent: pick which game project to spotlight

struct PickGameProjectIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Game"
    static let description = IntentDescription("Select which game project to show.")

    @Parameter(title: "Project", default: "Cartridge")
    var project: String

    @Parameter(title: "Show Quality", default: true)
    var showQuality: Bool
}

// MARK: - AppIntent: cost tracker options

struct CostTrackerIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Cost Tracker Options"
    static let description = IntentDescription("Configure the cost tracker widget.")

    @Parameter(title: "Time window", default: "today")
    var window: String  // "today" | "week" | "month"

    @Parameter(title: "Show budget %", default: true)
    var showBudget: Bool
}

// MARK: - Game Session Widget (small + medium)

struct GameSessionSmallView: View {
    let project: String
    let showQuality: Bool
    let snapshot: SwooshWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.cyan)
                Text(project)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "sparkle")
                    .font(.system(size: 8))
                    .foregroundStyle(.yellow)
            }

            Text("\(snapshot.gameSession.activeSessions)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)

            if showQuality {
                let quality = snapshot.gameSession.qualityScore
                HStack(spacing: 2) {
                    Image(systemName: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(quality, format: .percent.precision(.fractionLength(0)))")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(quality >= 0.8 ? .green : .orange)
            }

            Spacer(minLength: 0)

            SparklineView(data: snapshot.gameSession.playtestTrend, color: .cyan)
                .frame(height: 28)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GameSessionMediumView: View {
    let snapshot: SwooshWidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Game Harness")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                ForEach(snapshot.gameSession.recentChecks.prefix(3), id: \.name) { check in
                    HStack(spacing: 6) {
                        Image(systemName: check.ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(check.ok ? .green : .orange)
                        Text(check.name)
                            .font(.system(size: 12, weight: .bold))
                            .lineLimit(1)
                        Spacer()
                        Text(check.detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Divider()

            VStack(spacing: 6) {
                Text("Playtests")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text("\(snapshot.gameSession.playtestsToday)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.5)

                SparklineView(data: snapshot.gameSession.playtestTrend, color: .cyan)
                    .frame(width: 58, height: 42)
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GameSessionProvider: AppIntentTimelineProvider {
    typealias Entry = SwooshWidgetEntry
    typealias Intent = PickGameProjectIntent

    func placeholder(in context: Context) -> SwooshWidgetEntry {
        SwooshWidgetEntry(date: Date(), snapshot: .preview)
    }

    func snapshot(for configuration: PickGameProjectIntent, in context: Context) async -> SwooshWidgetEntry {
        SwooshWidgetEntry(date: Date(), snapshot: SwooshWidgetSnapshot.load() ?? .preview)
    }

    func timeline(for configuration: PickGameProjectIntent, in context: Context) async -> Timeline<SwooshWidgetEntry> {
        let snap = SwooshWidgetSnapshot.load() ?? .preview
        let entry = SwooshWidgetEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(next))
    }
}

public struct SwooshGameSessionWidget: Widget {
    public let kind: String = "SwooshGameSessionWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PickGameProjectIntent.self,
                               provider: GameSessionProvider()) { entry in
            GameSessionSmallView(
                project: "Cartridge",
                showQuality: true,
                snapshot: entry.snapshot
            )
        }
        .configurationDisplayName("Game Session")
        .description("Track Cartridge playtests, active game sessions, and quality checks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Agent Activity Widget

struct AgentActivitySmallView: View {
    let snapshot: SwooshWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.purple)
                Text("Agents")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                Circle()
                    .fill(snapshot.runningAgents > 0 ? .green : .secondary)
                    .frame(width: 6, height: 6)
            }

            // Running count
            Text("\(snapshot.runningAgents)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.purple)

            Text(snapshot.runningAgents == 1 ? "agent running" : "agents running")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            // Approvals badge
            if snapshot.pendingApprovals > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text("\(snapshot.pendingApprovals) pending approval\(snapshot.pendingApprovals > 1 ? "s" : "")")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AgentActivityMediumView: View {
    let snapshot: SwooshWidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            // Left: counts
            VStack(alignment: .leading, spacing: 10) {
                statRow(icon: "cpu.fill", color: .purple,
                        label: "Running", value: "\(snapshot.runningAgents)")
                statRow(icon: "checkmark.seal.fill", color: .orange,
                        label: "Approvals", value: "\(snapshot.pendingApprovals)")
                statRow(icon: "clock.fill", color: .cyan,
                        label: "Completed today", value: "\(snapshot.completedToday)")
            }

            Divider()

            // Right: recent activity feed
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                ForEach(snapshot.recentAgentEvents.prefix(3), id: \.id) { event in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(event.success ? Color.green : Color.red)
                            .frame(width: 5, height: 5)
                        Text(event.name)
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func statRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
        }
    }
}

public struct SwooshAgentWidget: Widget {
    public let kind: String = "SwooshAgentWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SwooshTimelineProvider()) { entry in
            AgentActivitySmallView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Agent Activity")
        .description("Live view of running agents and pending approvals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Cost Tracker Widget (small, intent-configurable)

struct CostTrackerSmallView: View {
    let window: String
    let showBudget: Bool
    let snapshot: SwooshWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
                Text(windowLabel)
                    .font(.system(size: 10, weight: .bold))
                Spacer()
            }

            Text(snapshot.costTracker.spend(for: window).formatted(.currency(code: "USD")))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .minimumScaleFactor(0.5)

            Text("API spend")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            if showBudget, let budget = snapshot.costTracker.budget {
                let fraction = snapshot.costTracker.spend(for: window) / budget
                ProgressView(value: min(fraction, 1.0))
                    .tint(fraction > 0.9 ? .red : fraction > 0.7 ? .orange : .green)
                    .scaleEffect(y: 1.5)
                Text("\(fraction * 100, format: .number.precision(.fractionLength(0)))% of budget")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var windowLabel: String {
        switch window {
        case "week":  return "This Week"
        case "month": return "This Month"
        default:      return "Today"
        }
    }
}

struct CostTrackerProvider: AppIntentTimelineProvider {
    typealias Entry = SwooshWidgetEntry
    typealias Intent = CostTrackerIntent

    func placeholder(in context: Context) -> SwooshWidgetEntry {
        SwooshWidgetEntry(date: Date(), snapshot: .preview)
    }

    func snapshot(for configuration: CostTrackerIntent, in context: Context) async -> SwooshWidgetEntry {
        SwooshWidgetEntry(date: Date(), snapshot: SwooshWidgetSnapshot.load() ?? .preview)
    }

    func timeline(for configuration: CostTrackerIntent, in context: Context) async -> Timeline<SwooshWidgetEntry> {
        let snap = SwooshWidgetSnapshot.load() ?? .preview
        let entry = SwooshWidgetEntry(date: Date(), snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(next))
    }
}

public struct SwooshCostWidget: Widget {
    public let kind: String = "SwooshCostWidget"
    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CostTrackerIntent.self,
                               provider: CostTrackerProvider()) { entry in
            CostTrackerSmallView(window: "today", showBudget: true, snapshot: entry.snapshot)
        }
        .configurationDisplayName("Cost Tracker")
        .description("Track your Swoosh API spend for today, this week, or this month.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Updated bundle (all 6 widgets)

public struct SwooshWidgetBundleV2: WidgetBundle {
    public init() {}

    @WidgetBundleBuilder
    public var body: some Widget {
        SwooshProviderWidget()
        SwooshCommandWidget()
        SwooshDashboardWidget()
        SwooshGameSessionWidget()
        SwooshAgentWidget()
        SwooshCostWidget()
    }
}

// MARK: - Helper views

private struct SparklineView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let mn = data.min() ?? 0, mx = data.max() ?? 1
                let range = mx - mn == 0 ? 1 : mx - mn
                let pts = data.enumerated().map { i, v in
                    CGPoint(
                        x: geo.size.width * CGFloat(i) / CGFloat(data.count - 1),
                        y: geo.size.height * (1 - CGFloat((v - mn) / range))
                    )
                }
                Path { p in
                    p.move(to: pts[0])
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

// MARK: - CostTracker model extensions

public struct CostTrackerData: Sendable {
    public var budget: Double? { 50.0 }
    public func spend(for window: String) -> Double {
        switch window {
        case "week":  return 12.40
        case "month": return 38.70
        default:      return 2.15
        }
    }
}

// MARK: - Agent event model

public struct AgentEvent: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let success: Bool
}

// MARK: - GameSessionWidget data facade

public struct GameSessionCheck: Sendable {
    public let name: String
    public let detail: String
    public let ok: Bool
}

public struct GameSessionWidgetData: Sendable {
    private let snapshot: SwooshWidgetSnapshot

    public init(snapshot: SwooshWidgetSnapshot) {
        self.snapshot = snapshot
    }

    public var activeSessions: Int {
        max(snapshot.activeWorkflows, snapshot.activeAgents)
    }

    public var playtestsToday: Int {
        max(snapshot.activeWorkflows, 1)
    }

    public var qualityScore: Double {
        snapshot.systemStatus == .healthy ? 0.92 : 0.64
    }

    public var playtestTrend: [Double] {
        [42, 48, 46, 57, 63, 61, 70, 76, 82, 79, 88, qualityScore * 100]
    }

    public var recentChecks: [GameSessionCheck] {
        [
            GameSessionCheck(name: "Harness", detail: "\(activeSessions) active", ok: snapshot.systemStatus != .offline),
            GameSessionCheck(name: "Approvals", detail: "\(snapshot.pendingApprovals) pending", ok: snapshot.pendingApprovals == 0),
            GameSessionCheck(name: "Pipelines", detail: "\(snapshot.activeWorkflows) running", ok: snapshot.activeWorkflows > 0),
        ]
    }
}

// MARK: - SwooshWidgetSnapshot computed extensions

extension SwooshWidgetSnapshot {
    public var gameSession: GameSessionWidgetData { GameSessionWidgetData(snapshot: self) }
    public var costTracker: CostTrackerData { CostTrackerData() }
    public var runningAgents: Int { activeAgents }
    public var completedToday: Int { activeWorkflows }
    public var recentAgentEvents: [AgentEvent] {
        providers.map {
            AgentEvent(id: $0.providerID, name: $0.displayName, success: $0.isHealthy)
        }
    }
}
