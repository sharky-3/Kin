import SwiftUI

struct AvatarView: View {
    let person: Person
    let size: CGFloat
    var tracks = true
    var screenCenter: (() -> CGPoint?)?

    var body: some View {
        if let data = person.imageData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            FaceView(person: person, size: size, tracks: tracks, screenCenter: screenCenter)
        }
    }
}
