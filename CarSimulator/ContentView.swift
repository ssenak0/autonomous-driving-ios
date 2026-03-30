import SwiftUI

struct ContentView: View {
    // ViewModel'i başlatıyoruz
    @StateObject private var viewModel = TrafficManager()
    
    var body: some View {
        ZStack {
            
            VideoBackgroundView(manager: viewModel) // viewModel artık videoya bağlı!
                .ignoresSafeArea()
                // YEŞİL KUTUCUK (Bounding Box)
                GeometryReader { geo in
                    let box = viewModel.currentBoundingBox
                    
                    // Eğer kutucuk .zero değilse çiz
                    if box != .zero {
                        Rectangle()
                            .stroke(Color.green, lineWidth: 3)
                            .shadow(color: .green, radius: 5)
                            // Kutucuğun tam boyutunu ve pozisyonunu GeometryReader'a göre ayarlıyoruz
                            .frame(
                                width: box.size.width * geo.size.width,
                                height: box.size.height * geo.size.height
                            )
                            // position, objenin merkezini (center) baz alır.
                            .position(
                                x: box.origin.x * geo.size.width + (box.size.width * geo.size.width / 2),
                                y: box.origin.y * geo.size.height + (box.size.height * geo.size.height / 2)
                            )
                            .animation(.easeInOut(duration: 0.2), value: box)
                    }
                }
            
            // Tesla Dashboard Katmanı
            VStack {
                HStack(alignment: .top) {
                    // Sol: Tabela Göstergesi
                    VStack(alignment: .leading) {
                        SignDisplayView(signName: viewModel.currentSign)
                        
                        if viewModel.isWarningActive {
                            Text("HIZI DÜŞÜR!")
                                .font(.caption.bold())
                                .padding(8)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.leading, 30)
                    
                    Spacer()
                    
                    // Sağ: Hız Göstergesi
                    VStack(alignment: .trailing) {
                        Text("\(viewModel.currentSpeed)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(viewModel.isWarningActive ? .red : .white)
                        Text("km/h").foregroundColor(.gray)
                    }
                    .padding(.trailing, 30)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Alt: Otonom Durum Çubuğu
                Text("AUTOPILOT READY")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding()
            }
        }
    }
}
// MARK: - Yardımcı Tasarım Parçaları

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
        switch label.uppercased() {
        case "SPEED_LIMIT": return "nosign"
        case "STOP": return "xmark.circle.fill"
        case "GIVE_WAY": return "triangle.fill"
        case "NO_ENTRY": return "minus.circle.fill"
        case "PEDESTRIAN_CROSSING": return "figure.walk.circle"
        case "TRAFFIC_SIGNAL": return "trafficlight.fill"
        case "MEN_AT_WORK": return "hammer.fill"
        case "SCHOOL_AHEAD": return "figure.and.child.holdinghands"
        case "NO_PARKING": return "p.circle.fill"
        case "OVERTAKING_PROHIBITED": return "car.2.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
}
