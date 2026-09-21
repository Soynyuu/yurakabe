import CoreMedia

/// The presentation clock spans many loops; an asset reader only accepts clip-local time.
enum LoopPosition {
    static func withinClip(_ time: CMTime, duration: CMTime) -> CMTime {
        guard time.isNumeric, duration.isNumeric, time >= .zero, duration > .zero else { return .zero }
        return CMTime(seconds: time.seconds.truncatingRemainder(dividingBy: duration.seconds), preferredTimescale: 60000)
    }
}
