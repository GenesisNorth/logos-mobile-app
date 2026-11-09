import ActivityKit
import SwiftUI
import WidgetKit

/// Design 2a (lock-screen banner) and 2b (Dynamic Island: minimal, compact, expanded).
@available(iOSApplicationExtension 16.2, *)
struct LogosLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LogosActivityAttributes.self) { context in
            LockBanner(context: context)
                .activityBackgroundTint(OC.n900)
                .activitySystemActionForegroundColor(OC.n100)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEK \(context.attributes.week) · \(context.attributes.reference)")
                            .font(OT.kicker(11)).tracking(1.2).foregroundStyle(OC.a300)
                        Text(context.attributes.phrase).font(OT.display(20)).foregroundStyle(.white).lineLimit(1)
                    }
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(to: context.state.unlockAt, stale: context.isStale)
                        .font(OT.display(18)).foregroundStyle(OC.a300).padding(.trailing, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        HStack(spacing: 6) {
                            ForEach(Array(context.state.days.enumerated()), id: \.offset) {
                                SeedDot(state: $0.element, size: 18, lockedColor: OC.n500)
                            }
                        }
                        Spacer()
                        Link(destination: URL(string: "logos://today")!) {
                            Text(context.isStale ? "Begin Day \(context.state.nextDay)" : "\(context.state.nextName) at midnight")
                                .font(OT.bold(13)).foregroundStyle(OC.n100)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(OC.accent))
                        }
                    }
                    .padding(.horizontal, 6).padding(.top, 4)
                }
            } compactLeading: {
                HStack(spacing: 6) {
                    Circle().fill(OC.accent).frame(width: 16, height: 16)
                    Text(context.state.nextName).font(OT.bold(13)).foregroundStyle(.white)
                }
            } compactTrailing: {
                Countdown(to: context.state.unlockAt, stale: context.isStale)
                    .font(OT.bold(13)).foregroundStyle(OC.a300).frame(maxWidth: 64)
            } minimal: {
                Circle().fill(OC.accent).frame(width: 14, height: 14)
            }
            .widgetURL(URL(string: "logos://today"))
            .keylineTint(OC.accent)
        }
    }
}

@available(iOSApplicationExtension 16.2, *)
private struct LockBanner: View {
    let context: ActivityViewContext<LogosActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(OC.accent).frame(width: 44, height: 44)
                Image(systemName: "moon.fill").font(.system(size: 18, weight: .semibold)).foregroundStyle(OC.n100)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(context.isStale ? "Day \(context.state.nextDay) is open" : context.state.title)
                    .font(OT.bold(15)).foregroundStyle(OC.n100).lineLimit(2)
                Text(context.state.subtitle).font(OT.body(13)).foregroundStyle(OC.n100.opacity(0.75)).lineLimit(1)
            }
            Spacer(minLength: 8)
            Countdown(to: context.state.unlockAt, stale: context.isStale)
                .font(OT.display(20)).foregroundStyle(OC.n100)
        }
        .padding(16)
    }
}

/// Live "2:14:05" countdown to the unlock, or "Now" once it has passed.
private struct Countdown: View {
    let to: Date
    let stale: Bool

    var body: some View {
        if stale || to <= .now {
            Text("Now")
        } else {
            Text(timerInterval: Date.now...to, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}
