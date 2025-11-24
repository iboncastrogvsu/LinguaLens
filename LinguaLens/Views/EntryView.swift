import SwiftUI

struct EntryView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var showLogin = false
    @State private var animate = false
    @State private var isCheckingAuth = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.9),
                                                           Color.purple.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if isCheckingAuth {
                    SplashView(animate: $animate)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.8)) {
                                animate = true
                            }
                        }
                } else if supabase.isAuthenticated {
                    HomeView(email: supabase.userEmail)
                        .transition(.opacity)
                } else {
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
            .task {
                await supabase.checkAuthStatus()
                await MainActor.run {
                    isCheckingAuth = false
                }
            }
        }
    }
}
