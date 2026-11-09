import SwiftUI

/// "Organic" design tokens (mirrors lib/core/design/organic.dart).
enum OC {
    static let bg = Color(hex: 0xF5EAD8)
    static let text = Color(hex: 0x201E1D)
    static let accent = Color(hex: 0xC67139)
    static let n100 = Color(hex: 0xF9F4ED)
    static let n500 = Color(hex: 0xA19786)
    static let n700 = Color(hex: 0x645C50)
    static let n900 = Color(hex: 0x2E2B25)
    static let a200 = Color(hex: 0xFFE1D0)
    static let a300 = Color(hex: 0xFFC6A5)
    static let a500 = Color(hex: 0xD67F48)
    static let a600 = Color(hex: 0xB2622D)
    static let a700 = Color(hex: 0x8C491A)
    static let s100 = Color(hex: 0xF0FAE1)
    static let s200 = Color(hex: 0xE1EECC)
    static let s500 = Color(hex: 0x8FA073)
    static let s700 = Color(hex: 0x56633F)
    static let s800 = Color(hex: 0x3D472B)
    static let s900 = Color(hex: 0x272E1B)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

enum OT {
    static func display(_ size: CGFloat) -> Font { .custom("Caprasimo-Regular", size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom("Figtree-Bold", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("Figtree-Regular", size: size) }
    static func kicker(_ size: CGFloat = 11) -> Font { .custom("Figtree-Bold", size: size) }
}

/// One of the four rhythm seeds: done (sage), today (terracotta), locked (dashed).
struct SeedDot: View {
    let state: String
    var size: CGFloat = 20
    var lockedColor: Color = OC.n500

    var body: some View {
        switch state {
        case "done": Circle().fill(OC.s500).frame(width: size, height: size)
        case "today": Circle().fill(OC.accent).frame(width: size, height: size)
        default:
            Circle()
                .strokeBorder(lockedColor, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: size, height: size)
        }
    }
}
