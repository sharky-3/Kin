import Foundation

typealias SFCallback = @convention(c) (OpaquePointer?, OpaquePointer?, CFString?, UInt32, Int32, UnsafeMutableRawPointer?) -> Void

nonisolated struct SFContext {
    var version: Int
    var info: UnsafeMutableRawPointer?
    var retain: OpaquePointer?
    var release: OpaquePointer?
    var copyDescription: OpaquePointer?
}

nonisolated struct SharingAPI: @unchecked Sendable {
    typealias Create = @convention(c) (CFAllocator?, CFString) -> OpaquePointer?
    typealias SetQueue = @convention(c) (OpaquePointer, OpaquePointer) -> Void
    typealias SetClient = @convention(c) (OpaquePointer, SFCallback?, UnsafeMutableRawPointer?) -> Void
    typealias Root = @convention(c) (OpaquePointer) -> OpaquePointer?
    typealias Open = @convention(c) (OpaquePointer, OpaquePointer, CFString?, UInt) -> Void
    typealias Children = @convention(c) (OpaquePointer, OpaquePointer) -> Unmanaged<CFArray>?
    typealias Name = @convention(c) (OpaquePointer) -> Unmanaged<CFString>?
    typealias Invalidate = @convention(c) (OpaquePointer) -> Void

    let kind: CFString
    let create: Create
    let setQueue: SetQueue
    let setClient: SetClient
    let root: Root
    let open: Open
    let children: Children
    let displayName: Name
    let computerName: Name?
    let invalidate: Invalidate

    static func load() -> SharingAPI? {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/Sharing.framework/Sharing", RTLD_NOW) else { return nil }
        func symbol<T>(_ name: String, as type: T.Type) -> T? {
            guard let pointer = dlsym(handle, name) else { return nil }
            return unsafeBitCast(pointer, to: type)
        }
        guard let kindPointer = dlsym(handle, "kSFBrowserKindAirDrop"),
              let create = symbol("SFBrowserCreate", as: Create.self),
              let setQueue = symbol("SFBrowserSetDispatchQueue", as: SetQueue.self),
              let setClient = symbol("SFBrowserSetClient", as: SetClient.self),
              let root = symbol("SFBrowserGetRootNode", as: Root.self),
              let open = symbol("SFBrowserOpenNode", as: Open.self),
              let children = symbol("SFBrowserCopyChildren", as: Children.self),
              let displayName = symbol("SFNodeCopyDisplayName", as: Name.self),
              let invalidate = symbol("SFBrowserInvalidate", as: Invalidate.self) else { return nil }
        let kind = kindPointer.assumingMemoryBound(to: CFString.self).pointee
        return SharingAPI(kind: kind, create: create, setQueue: setQueue, setClient: setClient, root: root, open: open, children: children, displayName: displayName, computerName: symbol("SFNodeCopyComputerName", as: Name.self), invalidate: invalidate)
    }
}
