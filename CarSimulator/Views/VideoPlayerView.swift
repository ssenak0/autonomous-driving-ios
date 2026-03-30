import SwiftUI
import AVKit

struct VideoBackgroundView: UIViewRepresentable {
    // SwiftUI'ın Context yapısını açıkça belirtiyoruz
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

class LoopingPlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        guard let fileUrl = Bundle.main.url(forResource: "rover_4k", withExtension: "mp4") else {
            print("Video dosyası bulunamadı! Lütfen dosya adını kontrol edin.")
            return
        }
        
        // iOS 18 uyumlu yeni kullanım
        let asset = AVURLAsset(url: fileUrl)
        let item = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        
        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    required init?(coder: NSCoder) { fatalError() }
}
