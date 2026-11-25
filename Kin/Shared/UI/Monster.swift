import Foundation

/// The little monsters people get as faces. A person's `hue` picks one, so saved
/// people, guests and contacts keep working without a new stored field.
enum Monster {
    static let names = [
        "bear-black", "bear-blue", "bear-mint", "bear-orange", "bear-pink", "bear-purple", "bear-red",
        "bunny-black", "bunny-2", "bunny-7", "bunny-8", "bunny-9", "bunny-10",
        "flower-red", "flower-blue", "flower-green", "flower-orange", "flower-pink", "flower-purple", "flower-yellow",
        "star-black", "star-blue", "star-mint", "star-orange", "star-pink", "star-purple", "star-teal",
    ].map { "monster-\($0)" }

    static func index(for hue: Double) -> Int {
        let value = hue.isFinite ? hue - hue.rounded(.down) : 0
        return min(names.count - 1, Int(value * Double(names.count)))
    }

    static func name(for hue: Double) -> String {
        names[index(for: hue)]
    }

    /// A hue that lands on a different monster than `current`.
    static func shuffledHue(from current: Double) -> Double {
        let now = index(for: current)
        var next = Int.random(in: 0..<names.count - 1)
        if next >= now { next += 1 }
        return (Double(next) + 0.5) / Double(names.count)
    }
}
