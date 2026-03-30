import AVFoundation

final class VideoFrameExtractor {
    private let asset: AVAsset
    private var reader: AVAssetReader?
    private var trackOutput: AVAssetReaderTrackOutput?
    private let lock = NSLock()
    private let pixelBufferAttributes: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        kCVPixelBufferMetalCompatibilityKey as String: true
    ]

    init?(url: URL) {
        asset = AVAsset(url: url)

        guard prepareReader() else {
            return nil
        }
    }

    private func prepareReader() -> Bool {
        reader?.cancelReading()
        reader = nil
        trackOutput = nil

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            print("⚠️ Video parçası bulunamadı")
            return false
        }

        do {
            let newReader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: pixelBufferAttributes)
            output.alwaysCopiesSampleData = false

            guard newReader.canAdd(output) else {
                print("⚠️ Reader bu output'u ekleyemiyor")
                return false
            }

            newReader.add(output)

            guard newReader.startReading() else {
                print("⚠️ Reader başlatılamadı: \(newReader.error?.localizedDescription ?? "bilinmeyen")")
                return false
            }

            reader = newReader
            trackOutput = output
            return true

        } catch {
            print("⚠️ Reader oluşturulamadı: \(error.localizedDescription)")
            return false
        }
    }

    func nextFrame() -> CVPixelBuffer? {
        lock.lock()
        defer { lock.unlock() }

        for _ in 0..<2 {
            guard let output = trackOutput else {
                guard prepareReader() else { return nil }
                continue
            }

            if let sample = output.copyNextSampleBuffer(),
               let buffer = CMSampleBufferGetImageBuffer(sample) {
                return buffer
            }

            if reader?.status == .completed || reader?.status == .failed {
                guard prepareReader() else { return nil }
                continue
            }

            break
        }

        return nil
    }
}
