import SwiftUI

struct HomeView: View {
    let email: String
    @StateObject private var supabase = SupabaseManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            if !supabase.isAuthenticated {
                EntryView()
                    .transition(.opacity)
            } else {
                TabView(selection: $selectedTab) {
                    CameraView()
                        .tabItem {
                            Label("Scan", systemImage: "camera.fill")
                        }
                        .tag(0)
                    
                    HistoryView(email: email)
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }
                        .tag(1)
                    
                    SettingsView(email: email)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(2)
                }
                .tint(.white)
            }
        }
    }
}
