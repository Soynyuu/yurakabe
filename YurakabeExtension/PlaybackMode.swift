import Foundation

enum PlaybackMode: String, Codable {
    case lockOnly, everywhere, still

    func showsVideo(presentationMode: String) -> Bool {
        switch self {
        case .lockOnly: presentationMode == "locked"
        case .everywhere: presentationMode == "locked" || presentationMode == "default" || presentationMode == "active"
        case .still: false
        }
    }
}
