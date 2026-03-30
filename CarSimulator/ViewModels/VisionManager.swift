import Foundation
import Darwin
import Vision
import CoreML

class VisionManager {
    
    private var trafficManager: TrafficManager
    private var visionRequest: VNCoreMLRequest?
    private var completion: (() -> Void)?
    private let detectionConfidenceThreshold: Double = 0.06
    private let classLabels = [
        "SPEED_LIMIT","STOP","GIVE_WAY","NO_ENTRY",
        "PEDESTRIAN_CROSSING","TRAFFIC_SIGNAL","ROUNDABOUT",
        "MEN_AT_WORK","SCHOOL_AHEAD","NO_PARKING",
        "COMPULSARY_KEEP_LEFT","COMPULSARY_KEEP_RIGHT",
        "OVERTAKING_PROHIBITED"
    ]

    private let visionQueue = DispatchQueue(label: "vision.queue")
    
    init(trafficManager: TrafficManager, completion: @escaping () -> Void) throws {
        self.trafficManager = trafficManager
        self.completion = completion
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly
        
        do {
            let coreMLModel = try best(configuration: config).model
            let visionModel = try VNCoreMLModel(for: coreMLModel)
            
            self.visionRequest = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                
                if let error = error {
                    print("❌ Vision request error: \(error.localizedDescription)")
                    return
                }
                
                self?.process(request: request)
            }
            
            self.visionRequest?.imageCropAndScaleOption = .scaleFit
            
            print("✅ Model başarıyla yüklendi")
            
        } catch {
            print("❌ Model load error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func analyzeFrame(pixelBuffer: CVPixelBuffer) {
        guard let request = visionRequest else {
            print("❌ Vision request yok")
            return
        }
        
        print("📸 Frame geldi → Vision başlıyor")
        
        visionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ Vision perform error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.completion?()
            }
        }
    }
    
    private func process(request: VNRequest) {
        print("🧠 Model output geldi")
        
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let multiArray = results.first?.featureValue.multiArrayValue else {
            print("❌ MultiArray parse edilemedi")
            return
        }
        
        let numClasses = classLabels.count
        let numPredictions = multiArray.shape[2].intValue

        print("📊 Prediction count: \(numPredictions)")

        struct Prediction {
            let rect: CGRect
            let label: String
            let confidence: Double
        }

        var bestPrediction: Prediction?

        let imageDimension: Double = 640.0

        for predictionIndex in 0..<numPredictions {
            let centerX = multiArray[[0, 0, predictionIndex] as [NSNumber]].doubleValue
            let centerY = multiArray[[0, 1, predictionIndex] as [NSNumber]].doubleValue
            let rawWidth = multiArray[[0, 2, predictionIndex] as [NSNumber]].doubleValue
            let rawHeight = multiArray[[0, 3, predictionIndex] as [NSNumber]].doubleValue

            guard rawWidth > 0, rawHeight > 0 else { continue }

            var logits = [Double](repeating: 0, count: numClasses)
            for classIndex in 0..<numClasses {
                logits[classIndex] = multiArray[[0, 4 + classIndex, predictionIndex] as [NSNumber]].doubleValue
            }

            guard let maxLogit = logits.max() else { continue }

            var expSum = 0.0
            var expValues = [Double](repeating: 0, count: numClasses)
            for classIndex in 0..<numClasses {
                let expValue = Darwin.exp(logits[classIndex] - maxLogit)
                expValues[classIndex] = expValue
                expSum += expValue
            }

            guard expSum.isFinite, expSum > 0 else { continue }

            var topClassIndex = 0
            var topProbability = 0.0
            for classIndex in 0..<numClasses {
                let probability = expValues[classIndex] / expSum
                if probability > topProbability {
                    topClassIndex = classIndex
                    topProbability = probability
                }
            }

            guard topProbability > detectionConfidenceThreshold else { continue }

            let normalizedCenterX = centerX / imageDimension
            let normalizedCenterY = centerY / imageDimension
            let normalizedWidth = rawWidth / imageDimension
            let normalizedHeight = rawHeight / imageDimension

            let width = max(0, min(1, normalizedWidth))
            let height = max(0, min(1, normalizedHeight))
            let x = max(0, min(1, normalizedCenterX - width / 2))
            let y = max(0, min(1, normalizedCenterY - height / 2))

            let rect = CGRect(x: x, y: y, width: width, height: height)
            let label = classLabels[topClassIndex]
            let prediction = Prediction(rect: rect, label: label, confidence: topProbability)

            if let currentBest = bestPrediction {
                if prediction.confidence > currentBest.confidence {
                    bestPrediction = prediction
                }
            } else {
                bestPrediction = prediction
            }
        }

        guard let finalPrediction = bestPrediction else {
            print("⚠️ Confidence düşük → discard")
            return
        }

        print("🏆 Best confidence: \(finalPrediction.confidence)")
        print("📦 Box raw → x:\(finalPrediction.rect.origin.x), y:\(finalPrediction.rect.origin.y), w:\(finalPrediction.rect.width), h:\(finalPrediction.rect.height)")

        DispatchQueue.main.async {
            print("🏷️ FINAL LABEL: \(finalPrediction.label)")
            print("✅ UI UPDATE GÖNDERİLDİ")
            self.trafficManager.updateDetection(
                label: finalPrediction.label,
                confidence: finalPrediction.confidence,
                box: finalPrediction.rect
            )
        }
    }
}
