import Foundation
import Observation

@Observable
final class DropState {
    var isActive = false
    var targetIndex: Int?
    var location: CGPoint?
}
