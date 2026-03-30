import SwiftUI
import AVKit
class LoopingPlayerUIView: UIView {
    
    private let playerLayer = AVPlayerLayer()
    private var player: AVQueuePlayer!
    private var playerLooper: AVPlayerLooper?
    private var frameExtractor: VideoFrameExtractor?
    private var displayLink: CADisplayLink?
    
    private var visionManager: VisionManager?
    private var trafficManager: TrafficManager
    
    // 🔥 EKLEDİK
    private var isProcessing = false
    
    init(frame: CGRect, manager: TrafficManager) {
        self.trafficManager = manager
        super.init(frame: frame)
        
        setupVision()
        setupPlayer()
    }
    
    private func setupVision() {
        // 🔥 completion ile bağlayacağız
        self.visionManager = try? VisionManager(
            trafficManager: trafficManager,
            completion: { [weak self] in
                self?.isProcessing = false
            }
        )
    }
    
    private func setupPlayer() {
        print("🎥 Frame hazırlığı")
        guard let url = Bundle.main.url(forResource: "rover_1k", withExtension: "mov") else {
            print("❌ Video kaynağı bulunamadı")
            return
        }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        player = AVQueuePlayer(playerItem: item)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)

        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        player.play()

        frameExtractor = VideoFrameExtractor(url: url)
        if frameExtractor == nil {
            print("⚠️ Frame çıkarıcı başlatılamadı")
        }

        displayLink = CADisplayLink(target: self, selector: #selector(analyzeFrame))
        displayLink?.preferredFramesPerSecond = 5
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func analyzeFrame() {
        
        if isProcessing {
            print("⏭️ Frame skip (processing devam ediyor)")
            return
        }
        
        guard let extractor = frameExtractor,
              let pixelBuffer = extractor.nextFrame()
        else {
            print("⚠️ Yeni frame alınamadı")
            return
        }
        
        print("🎥 Frame işlendi")
        
        isProcessing = true
        visionManager?.analyzeFrame(pixelBuffer: pixelBuffer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        displayLink?.invalidate()
    }
}
