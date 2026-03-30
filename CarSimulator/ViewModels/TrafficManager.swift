import Foundation
import Combine
import SwiftUI

class TrafficManager: ObservableObject {
    
    @Published var currentSign: String = "SCANNING..."
    @Published var confidenceScore: Double = 0.0
    @Published var currentBoundingBox: CGRect = .zero
    @Published var currentSpeed: Int = 84
    @Published var speedLimit: Int = 50
    @Published var isWarningActive: Bool = false
    
    private var resetTimer: Timer?
    
    init() {
        $currentSpeed
            .combineLatest($speedLimit)
            .map { $0 > $1 }
            .assign(to: &$isWarningActive)
    }
    func updateDetection(label: String, confidence: Double, box: CGRect) {
        
        print("""
        🎯 UI UPDATE:
           Label: \(label)
           Confidence: \(confidence)
           Box: \(box)
        """)
        
        DispatchQueue.main.async {
            
            self.currentSign = label
            self.confidenceScore = confidence
            
            self.currentBoundingBox = self.currentBoundingBox == .zero
                ? box
                : self.interpolate(from: self.currentBoundingBox, to: box)
            
            self.resetTimer?.invalidate()
            
            self.resetTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                print("🧹 Detection resetlendi")
                self.currentBoundingBox = .zero
                self.currentSign = "SCANNING..."
            }
        }
    }
    
    private func interpolate(from: CGRect, to: CGRect) -> CGRect {
        let factor: CGFloat = 0.2
        
        return CGRect(
            x: from.origin.x + (to.origin.x - from.origin.x) * factor,
            y: from.origin.y + (to.origin.y - from.origin.y) * factor,
            width: from.size.width + (to.size.width - from.size.width) * factor,
            height: from.size.height + (to.size.height - from.size.height) * factor
        )
    }
}
