import SwiftUI

enum BackgroundOption {
    case whiteMarble, darkGlow, appleGradient
}

struct BackgroundView: View {
    var backgroundOption: BackgroundOption

    var body: some View {
        switch backgroundOption {
        case .whiteMarble:
            Image("white-marble")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        case .darkGlow:
            RadialGradient(gradient: Gradient(colors: [.black, Color.black.opacity(0.6)]), center: .center, startRadius: 5, endRadius: 500)
                .edgesIgnoringSafeArea(.all)
        case .appleGradient:
            LinearGradient(gradient: Gradient(colors: [Color.red, Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
