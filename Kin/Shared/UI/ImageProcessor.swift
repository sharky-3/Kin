import AppKit
import UniformTypeIdentifiers

enum ImageProcessor {
    static func avatarData(from image: NSImage, side: CGFloat = 256) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let scale = max(side / size.width, side / size.height)
        let scaled = NSSize(width: size.width * scale, height: size.height * scale)
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(side), pixelsHigh: Int(side), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        rep.size = NSSize(width: side, height: side)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor(white: 0.92, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: side, height: side).fill()
        image.draw(in: NSRect(x: (side - scaled.width) / 2, y: (side - scaled.height) / 2, width: scaled.width, height: scaled.height), from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
    }

    static func chooseFile() -> Data? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return nil }
        return avatarData(from: image)
    }

    static func avatarData(from data: Data) -> Data? {
        guard let image = NSImage(data: data) else { return nil }
        return avatarData(from: image)
    }
}
