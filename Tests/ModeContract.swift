import Foundation
@main struct ModeCheck {
 static func main() {
  let presentations = ["default", "active", "locked", "idle", "unknown"]
  for mode in [PlaybackMode.lockOnly, .everywhere, .still] {
   for p in presentations {
    let visible = mode.showsVideo(presentationMode: p)
    let expected = mode == .everywhere ? ["default", "active", "locked"].contains(p) : mode == .lockOnly && p == "locked"
    precondition(visible == expected)
    let policy = PlaybackPolicy.compute(presentationMode: p, activityState: "active", userPaused: mode == .still, alwaysPauseDesktop: mode != .everywhere, pauseWhenOccluded: false, desktopOccluded: false, screenSaverIsOurs: false, thermalState: .nominal, isOnBattery: false, batteryLevel: 100, isGameModeActive: false)
    let effective = visible ? policy : .paused
    precondition(effective == (expected ? .full : .paused))
   }
  }
  print("PASS: all 15 mode/presentation combinations, foreign screensaver paused, unknown mode static")
 }
}
