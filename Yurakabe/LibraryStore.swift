import AVFoundation
import Foundation

struct ImportedVideo: Codable, Sendable {
    let id: String
    let name: String
    let filename: String
    let duration: Double
    let fps: Double
    let resolution: CGSize
    let dateAdded: Date
}

enum ImportError: LocalizedError {
    case unsupported
    var errorDescription: String? {
        "Choose a playable H.264 or HEVC video with no rotation metadata. Export rotated phone videos in landscape orientation first."
    }
}

/// Publishes a complete folder with one rename, so the extension never sees half an import.
actor LibraryStore {
    let documents: URL
    init(documents: URL) { self.documents = documents }

    func importVideo(from source: URL) async throws -> ImportedVideo {
        let asset = AVURLAsset(url: source)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { throw ImportError.unsupported }
        let duration = try await asset.load(.duration).seconds
        let size = try await track.load(.naturalSize)
        let fps = try await track.load(.nominalFrameRate)
        let transform = try await track.load(.preferredTransform)
        let descriptions = try await track.load(.formatDescriptions)
        guard duration.isFinite, duration > 0, size.width > 0, size.height > 0,
              fps.isFinite, fps > 0, transform.isIdentity,
              let format = descriptions.first,
              [kCMVideoCodecType_H264, kCMVideoCodecType_HEVC].contains(CMFormatDescriptionGetMediaSubType(format))
        else { throw ImportError.unsupported }
        let manager = FileManager.default
        let videos = documents.appendingPathComponent("videos", isDirectory: true)
        try manager.createDirectory(at: videos, withIntermediateDirectories: true)
        let id = UUID().uuidString
        let staging = videos.appendingPathComponent(".import-" + id, isDirectory: true)
        try manager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? manager.removeItem(at: staging) }
        let filename = "video." + source.pathExtension.lowercased()
        let entry = ImportedVideo(id: id, name: source.deletingPathExtension().lastPathComponent,
                                  filename: filename, duration: duration, fps: Double(fps), resolution: size, dateAdded: Date())
        try manager.copyItem(at: source, to: staging.appendingPathComponent(filename))
        try JSONEncoder().encode(entry).write(to: staging.appendingPathComponent("metadata.json"), options: .atomic)
        try manager.moveItem(at: staging, to: videos.appendingPathComponent(id, isDirectory: true))
        return entry
    }
}
