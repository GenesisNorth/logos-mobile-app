import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Live Activity for "the next step opens at midnight" (design 2a banner, 2b island).
/// Compiled into both the Runner app and the LogosWidgets extension.
@available(iOS 16.1, *)
public struct LogosActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String      // "Stillness opens at midnight"
        public var subtitle: String   // "Day 3 · Week 1 · John 15:5"
        public var nextName: String   // "Stillness"
        public var nextDay: Int
        public var unlockAt: Date
        public var days: [String]     // done | today | locked ×4
    }

    public var reference: String      // "JOHN 15:5"
    public var phrase: String         // "Abide in me."
    public var week: Int
}
#endif
