import CoreGraphics

/// Fit the entire encoded canvas inside the destination. Never round outwards:
/// enlarging either dimension would allow a crop on scaled Retina displays.
enum VideoFit {
    static func rect(video: CGSize, inside bounds: CGRect) -> CGRect {
        guard video.width > 0, video.height > 0, bounds.width > 0, bounds.height > 0 else { return .zero }
        let scale = min(bounds.width / video.width, bounds.height / video.height)
        let size = CGSize(width: video.width * scale, height: video.height * scale)
        return CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2,
                      width: size.width, height: size.height)
    }
}
