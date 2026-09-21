import CoreMedia
@main struct LoopCheck {
    static func main() {
        let duration = CMTime(seconds: 5, preferredTimescale: 600)
        for (clock, expected) in [(0.0, 0.0), (4.9, 4.9), (5, 0), (12.25, 2.25), (5002.5, 2.5)] {
            let result = LoopPosition.withinClip(CMTime(seconds: clock, preferredTimescale: 600), duration: duration)
            precondition(abs(result.seconds - expected) < 0.0001)
        }
        precondition(LoopPosition.withinClip(.invalid, duration: duration) == .zero)
        precondition(LoopPosition.withinClip(duration, duration: .zero) == .zero)
        print("PASS: pause/resume positions after many loops and invalid clocks")
    }
}
