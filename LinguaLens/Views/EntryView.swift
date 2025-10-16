import SwiftUI

struct EntryView: View {
    @State private var showLogin = false
    @State private var animate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.9),
                                                           Color.purple.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if showLogin {
                    LoginView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    SplashView(animate: $animate)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.8)) {
                                animate = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    showLogin = true
                                }
                            }
                        }
                }
            }
        }
    }
}
