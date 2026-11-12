import CoreGraphics

enum StatusBarMetrics {
    static let avatar: CGFloat = 20
    static let padding: CGFloat = 4
    static let step: CGFloat = 15
    static let spreadStep: CGFloat = 27
    static let more: CGFloat = 20
    static let moreGap: CGFloat = 3

    static var moreSpace: CGFloat {
        more + moreGap
    }

    static func rightOffset(for slot: Int, count: Int, spread: Bool, expanded: Bool) -> CGFloat {
        let extra = expanded && !spread ? moreSpace : 0
        return padding + extra + avatar / 2 + CGFloat(count - slot) * (spread ? spreadStep : step)
    }

    static var moreRightOffset: CGFloat {
        padding + more / 2
    }

    static func width(for count: Int, spread: Bool) -> CGFloat {
        let extra = spread ? 0 : moreSpace
        return padding * 2 + extra + avatar + CGFloat(count) * (spread ? spreadStep : step)
    }

    static func slot(atRight distance: CGFloat, count: Int, expanded: Bool) -> Int? {
        for slot in stride(from: count, through: 0, by: -1) {
            if abs(distance - rightOffset(for: slot, count: count, spread: false, expanded: expanded)) <= avatar / 2 + 0.5 {
                return slot
            }
        }
        return nil
    }
}
