import CoreGraphics

enum StatusBarMetrics {
    static let avatar: CGFloat = 20
    static let padding: CGFloat = 4
    static let step: CGFloat = 15
    static let spreadStep: CGFloat = 27

    /// While dropping, avatars stay stacked and only the targeted one gets a gap on each side.
    static func rightOffset(for slot: Int, count: Int, spread: Bool, target: Int? = nil) -> CGFloat {
        var distance = padding + avatar / 2
        guard slot < count else { return distance }
        for left in slot..<count {
            let gapped = spread && (target == left || target == left + 1)
            distance += gapped ? spreadStep : step
        }
        return distance
    }

    static func width(for count: Int, spread: Bool) -> CGFloat {
        // Room for the two gaps around a drop target, so the item doesn't resize while you drag across people.
        let extra = spread ? CGFloat(min(count, 2)) * (spreadStep - step) : 0
        return padding * 2 + extra + avatar + CGFloat(count) * step
    }

    static func slot(atRight distance: CGFloat, count: Int) -> Int? {
        for slot in stride(from: count, through: 0, by: -1) {
            if abs(distance - rightOffset(for: slot, count: count, spread: false)) <= avatar / 2 + 0.5 {
                return slot
            }
        }
        return nil
    }
}
