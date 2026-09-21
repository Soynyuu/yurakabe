import AVFoundation
import Foundation

@main struct ImportCheck {
    static func main() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }
        let source = root.appendingPathComponent("test.mov")
        let writer = try AVAssetWriter(outputURL: source, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 64, AVVideoHeightKey: 64])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB, kCVPixelBufferWidthKey as String: 64, kCVPixelBufferHeightKey as String: 64])
        writer.add(input)
        precondition(writer.startWriting())
        writer.startSession(atSourceTime: .zero)
        for frame in 0..<30 {
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
            var buffer: CVPixelBuffer?
            CVPixelBufferCreate(nil, 64, 64, kCVPixelFormatType_32ARGB, nil, &buffer)
            let pixels = buffer!
            CVPixelBufferLockBaseAddress(pixels, [])
            memset(CVPixelBufferGetBaseAddress(pixels), 80, CVPixelBufferGetDataSize(pixels))
            CVPixelBufferUnlockBaseAddress(pixels, [])
            precondition(adaptor.append(pixels, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        precondition(writer.status == .completed)
        let documents = root.appendingPathComponent("Documents")
        let store = LibraryStore(documents: documents)
        let first = try await store.importVideo(from: source)
        let second = try await store.importVideo(from: source)
        precondition(first.id != second.id)
        let folder = documents.appendingPathComponent("videos/" + first.id)
        let decoded = try JSONDecoder().decode(ImportedVideo.self, from: Data(contentsOf: folder.appendingPathComponent("metadata.json")))
        precondition(decoded.duration > 0.9 && decoded.duration < 1.1)
        let original = try Data(contentsOf: source)
        let copied = try Data(contentsOf: folder.appendingPathComponent(first.filename))
        precondition(original == copied)
        let bad = root.appendingPathComponent("bad.mov")
        try Data("not a movie".utf8).write(to: bad)
        do { _ = try await store.importVideo(from: bad); fatalError("Invalid video accepted") } catch {}
        let entries = try fm.contentsOfDirectory(atPath: documents.appendingPathComponent("videos").path)
        precondition(entries.count == 2 && !entries.contains(where: { $0.hasPrefix(".") }))
        print("PASS: synthetic H.264 import, metadata, full copy, duplicate isolation, invalid-file rollback")
    }
}
