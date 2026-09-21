import CoreGraphics
import Foundation
import os

/// Shared playback mode and solid background, reloaded on preference changes.
/// The color is data, so it can be changed without rebuilding the extension.
enum DesktopAppearance {
    private static let modeLock = OSAllocatedUnfairLock(initialState: readMode())
    static var mode: PlaybackMode { modeLock.withLock { $0 } }
    static var showsVideo: Bool { mode.showsVideo(presentationMode: WallpaperState.shared.presentationMode) }

    private static func readMode() -> PlaybackMode {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("playback-mode.json")
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(PlaybackMode.self, from: data) else { return .lockOnly }
        return value
    }

    static func reload() {
        let value = readMode()
        modeLock.withLock { $0 = value }
        colorLock.withLock { $0 = readColor() }
        extensionLog("[Yurakabe] mode=\(value.rawValue)")
    }

    private static let colorLock = OSAllocatedUnfairLock(initialState: readColor())
    static var color: CGColor { colorLock.withLock { $0 } }

    private static func readColor() -> CGColor {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("desktop-color.json")
        let values = (try? Data(contentsOf: url)).flatMap {
            try? JSONDecoder().decode([Double].self, from: $0)
        } ?? [35.0 / 255.0, 35.0 / 255.0, 35.0 / 255.0]
        let rgb = values.count == 3 ? values : [0, 0, 0]
        return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                       components: rgb.map { CGFloat(min(1, max(0, $0))) } + [1])!
    }

    static func snapshot(width: Int = 16, height: Int = 16) -> CGImage? {
        guard let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
