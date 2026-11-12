import AppKit
import Collaboration

enum AccountPicture {
    static var image: NSImage? {
        CBUserIdentity(posixUID: getuid(), authority: CBIdentityAuthority.default())?.image
    }
}
