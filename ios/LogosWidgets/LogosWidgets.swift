import SwiftUI
import WidgetKit

private let appGroup = "group.com.logosinme.logosMobileApp"

/// Snapshot written by the Flutter app (lib/core/services/glance_service.dart).
struct GlanceEntry: TimelineEntry {
    let date: Date
    let reference: String
    let phrase: String
    let days: [String]
    let doneCount: Int
    let streak: Int
    let status: String     // today | resting | complete
    let headline: String
    let nextName: String
    let nextDay: Int

    static let placeholder = GlanceEntry(
        date: .now, reference: "JOHN 15:5", phrase: "Abide in me.",
        days: ["done", "today", "locked", "locked"], doneCount: 1, streak: 7,
        status: "today", headline: "Day 2 · Today", nextName: "Roots", nextDay: 2)

    var statusLine: String {
        switch status {
        case "today": return headline
        case "complete": return "Week kept"
        default: return "\(nextName) · at midnight"
        }
    }
}

struct GlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> GlanceEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (GlanceEntry) -> Void) { completion(read(at: .now)) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlanceEntry>) -> Void) {
        let now = read(at: .now)
        var entries = [now]
        // When the next step unlocks at midnight, the widget flips to "today" on its own.
        let d = UserDefaults(suiteName: appGroup)
        let unlockMs = d?.double(forKey: "unlockAt") ?? 0
        if now.status == "resting", unlockMs > 0 {
            let at = Date(timeIntervalSince1970: unlockMs / 1000)
            if at > .now {
                var days = now.days
                if now.nextDay >= 1, now.nextDay <= days.count { days[now.nextDay - 1] = "today" }
                entries.append(GlanceEntry(
                    date: at, reference: now.reference, phrase: now.phrase, days: days,
                    doneCount: now.doneCount, streak: now.streak, status: "today",
                    headline: "Day \(now.nextDay) · Today", nextName: now.nextName, nextDay: now.nextDay))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func read(at date: Date) -> GlanceEntry {
        guard let d = UserDefaults(suiteName: appGroup), d.string(forKey: "ref") != nil else { return .placeholder }
        return GlanceEntry(
            date: date,
            reference: d.string(forKey: "ref") ?? "",
            phrase: d.string(forKey: "phrase") ?? "",
            days: (d.string(forKey: "days") ?? "").split(separator: ",").map(String.init),
            doneCount: d.integer(forKey: "doneCount"),
            streak: d.integer(forKey: "streak"),
            status: d.string(forKey: "status") ?? "today",
            headline: d.string(forKey: "headline") ?? "",
            nextName: d.string(forKey: "nextName") ?? "",
            nextDay: d.integer(forKey: "nextDay"))
    }
}

// MARK: - Verse (terracotta)

struct VerseWidgetView: View {
    let entry: GlanceEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.reference).font(OT.kicker()).tracking(1.5).foregroundStyle(OC.a200)
            Spacer(minLength: 6)
            Text(entry.phrase).font(OT.display(21)).foregroundStyle(OC.n100).lineLimit(3).minimumScaleFactor(0.7)
            Spacer(minLength: 6)
            Text(entry.statusLine).font(OT.bold(12)).foregroundStyle(OC.n100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .widgetBackground {
            ZStack(alignment: .topTrailing) {
                OC.a700
                Circle().fill(OC.a600).frame(width: 130, height: 130).offset(x: 55, y: -60)
                Circle().fill(OC.a500).frame(width: 18, height: 18).offset(x: -18, y: 30)
            }
        }
        .widgetURL(URL(string: "logos://today"))
    }
}

struct LogosVerseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LogosVerseWidget", provider: GlanceProvider()) { VerseWidgetView(entry: $0) }
            .configurationDisplayName("This week’s verse")
            .description("The verse you are dwelling in, and today’s step.")
            .supportedFamilies([.systemSmall])
            .contentMarginsDisabledIfAvailable()
    }
}

// MARK: - This week (cream)

struct WeekWidgetView: View {
    let entry: GlanceEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THIS WEEK").font(OT.kicker()).tracking(1.5).foregroundStyle(OC.a600)
            Spacer(minLength: 6)
            HStack(spacing: 6) { ForEach(Array(entry.days.enumerated()), id: \.offset) { SeedDot(state: $0.element) } }
            if entry.status == "resting" {
                Text(entry.headline).font(OT.body(11)).foregroundStyle(OC.n700).lineLimit(1).padding(.top, 8)
            }
            Spacer(minLength: 6)
            Text("\(entry.streak)-day streak").font(OT.bold(12)).foregroundStyle(OC.text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .widgetBackground { OC.n100 }
        .widgetURL(URL(string: "logos://today"))
    }
}

struct LogosWeekWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LogosWeekWidget", provider: GlanceProvider()) { WeekWidgetView(entry: $0) }
            .configurationDisplayName("This week")
            .description("Your four-day rhythm and streak.")
            .supportedFamilies([.systemSmall])
            .contentMarginsDisabledIfAvailable()
    }
}

// MARK: - Lock screen (design 2a): verse card + streak ring

@available(iOSApplicationExtension 16.0, *)
struct LockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GlanceEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(entry.doneCount), in: 0...4) {
                Text("Rhythm")
            } currentValueLabel: {
                Text("\(entry.doneCount)/4").font(OT.display(15))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetBackground { Color.clear }
        default:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.reference).font(OT.kicker(11)).tracking(1.2).widgetAccentable()
                Text(entry.phrase).font(OT.display(17)).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetBackground { Color.clear }
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct LogosLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LogosLockWidget", provider: GlanceProvider()) { LockWidgetView(entry: $0) }
            .configurationDisplayName("Verse & rhythm")
            .description("This week’s verse, or your rhythm ring, on the Lock Screen.")
            .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Helpers (iOS 16 / 17 compatibility)

extension View {
    @ViewBuilder
    func widgetBackground<B: View>(@ViewBuilder _ background: () -> B) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background() }
        } else {
            self.background(background())
        }
    }
}

extension WidgetConfiguration {
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return self.contentMarginsDisabled()
        }
        return self
    }
}
