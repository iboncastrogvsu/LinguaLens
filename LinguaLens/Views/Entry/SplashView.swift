import SwiftUI

struct SplashView: View {
    @Binding var animate: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(.white)
                .scaleEffect(animate ? 1.2 : 0.7)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .shadow(radius: 10)

            Text("LinguaLens")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
        }
        .animation(.spring(response: 1, dampingFraction: 0.7), value: animate)
    }
}
