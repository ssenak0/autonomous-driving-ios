import SwiftUI
import AVKit
import Vision
struct VideoBackgroundView: UIViewRepresentable {
    
    @ObservedObject var manager: TrafficManager
    
    func makeUIView(context: Context) -> UIView {
        return LoopingPlayerUIView(frame: .zero, manager: manager)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
