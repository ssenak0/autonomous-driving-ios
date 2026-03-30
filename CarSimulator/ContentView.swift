import SwiftUI

struct ContentView: View {
    // Modelden gelecek verileri simüle ediyoruz
    @State private var detectedSign: String = "STOP" // Test için "SPEED_LIMIT" yapabilirsin
    @State private var currentSpeed: Int = 84
    @State private var speedLimit: Int = 50
    
    var body: some View {
        ZStack {
            VideoBackgroundView()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.3))
            
            VStack {
                // 2. ÜST PANEL: Hız ve Durum Göstergeleri
                HStack(alignment: .top) {
                    
                    // SOL TARAF: Tabela ve Uyarı Paneli
                    VStack(alignment: .leading, spacing: 20) {
                        SignDisplayView(signName: detectedSign)
                        
                        if currentSpeed > speedLimit {
                            WarningView(message: "HIZI DÜŞÜR!")
                        }
                    }
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    // SAĞ TARAF: Dijital Hız Göstergesi
                    VStack(alignment: .trailing) {
                        Text("\(currentSpeed)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(currentSpeed > speedLimit ? .red : .white)
                        
                        Text("km/h")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 30)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // 3. ALT PANEL: Tesla Otonom Sürüş Şeridi (Opsiyonel)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 100)
                    .padding()
                    .overlay(
                        Text("AUTOPILOT READY")
                            .foregroundColor(.blue)
                            .font(.caption.bold())
                    )
            }
        }
    }
}

// MARK: - Yardımcı Görünümler (Components)

struct SignDisplayView: View {
    let signName: String
    
    var body: some View {
        VStack {
            Image(systemName: getSymbol(for: signName))
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .padding(20)
                .background(
                    Circle()
                        .fill(signName == "STOP" ? Color.red : Color.blue)
                        .shadow(radius: 10)
                )
            
            Text(signName.replacingOccurrences(of: "_", with: " "))
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.top, 5)
        }
    }
    
    func getSymbol(for label: String) -> String {
        switch label {
        case "STOP": return "xmark.circle.fill" // Senin seçtiğin ikon!
        case "SPEED_LIMIT": return "nosign"
        case "NO_ENTRY": return "minus.circle.fill"
        case "PEDESTRIAN_CROSSING": return "figure.walk.circle"
        case "SCHOOL_AHEAD": return "figure.and.child.holdinghands"
        default: return "exclamationmark.triangle.fill"
        }
    }
}

struct WarningView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.caption.bold())
            .padding(8)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
