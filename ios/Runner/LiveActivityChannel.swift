import Flutter
import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// `logos/live_activity` — started by GlanceService when the next step is
/// waiting for midnight; ended when a step is open or the week is kept.
enum LiveActivityChannel {
    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "logos/live_activity", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            guard #available(iOS 16.2, *) else { result(nil); return }
            switch call.method {
            case "startOrUpdate":
                let args = call.arguments as? [String: Any] ?? [:]
                Task { await startOrUpdate(args); result(nil) }
            case "end":
                Task { await endAll(); result(nil) }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @available(iOS 16.2, *)
    private static func startOrUpdate(_ a: [String: Any]) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let unlockMs = (a["unlockAt"] as? NSNumber)?.doubleValue ?? 0
        guard unlockMs > 0 else { await endAll(); return }
        let unlockAt = Date(timeIntervalSince1970: unlockMs / 1000)

        let attributes = LogosActivityAttributes(
            reference: a["ref"] as? String ?? "",
            phrase: a["phrase"] as? String ?? "",
            week: (a["week"] as? NSNumber)?.intValue ?? 1)
        let state = LogosActivityAttributes.ContentState(
            title: a["headline"] as? String ?? "",
            subtitle: a["subline"] as? String ?? "",
            nextName: a["nextName"] as? String ?? "",
            nextDay: (a["nextDay"] as? NSNumber)?.intValue ?? 1,
            unlockAt: unlockAt,
            days: (a["days"] as? String ?? "").split(separator: ",").map(String.init))
        let content = ActivityContent(state: state, staleDate: unlockAt)

        let existing = Activity<LogosActivityAttributes>.activities
        if let current = existing.first, current.attributes.reference == attributes.reference, current.attributes.week == attributes.week {
            await current.update(content)
            for extra in existing.dropFirst() { await extra.end(nil, dismissalPolicy: .immediate) }
            return
        }
        await endAll()
        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            NSLog("[LiveActivity] request failed: \(error)")
        }
    }

    @available(iOS 16.2, *)
    private static func endAll() async {
        for activity in Activity<LogosActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
