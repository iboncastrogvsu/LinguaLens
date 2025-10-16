import SwiftUI

struct HomeView: View {
    let email: String

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.9),
                                                       Color.indigo.opacity(0.9)]),
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)

                Text("Hello, \(email.isEmpty ? "Explorer" : email)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Welcome to LinguaLens")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
    }
}
