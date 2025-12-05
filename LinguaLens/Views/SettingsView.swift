import SwiftUI

struct SettingsView: View {
    let email: String
    @StateObject private var supabase = SupabaseManager.shared
    @State private var defaultLanguage = "English"
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    @State private var isSavingLanguage = false
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic", "Russian"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.9),
                                                           Color.indigo.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white)
                                .shadow(radius: 10)
                            
                            Text(supabase.userName.isEmpty ? "User Profile" : "@\(supabase.userName)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 20)
                        .onAppear {
                            defaultLanguage = supabase.defaultLanguage
                        }
                        
                        // Settings Sections
                        VStack(spacing: 16) {
                            // General Section
                            SettingsSection(title: "General") {
                                SettingsLanguagePicker(
                                    icon: "globe",
                                    title: "Default Language",
                                    selectedLanguage: $defaultLanguage,
                                    languages: languages,
                                    isSaving: $isSavingLanguage,
                                    onSave: {
                                        saveLanguage()
                                    }
                                )
                            }
                            
                            // Account Section
                            SettingsSection(title: "Account") {
                                SettingsButton(
                                    icon: "arrow.right.square.fill",
                                    title: isLoggingOut ? "Logging out..." : "Logout",
                                    destructive: true,
                                    action: {
                                        showLogoutAlert = true
                                    }
                                )
                            }
                        }
                        
                        // App Version
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .disabled(isLoggingOut)
        }
    }
    
    private func saveLanguage() {
        isSavingLanguage = true
        
        Task {
            do {
                try await supabase.updateDefaultLanguage(defaultLanguage)
                await MainActor.run {
                    isSavingLanguage = false
                }
            } catch {
                await MainActor.run {
                    isSavingLanguage = false
                    print("Error saving language: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleLogout() {
        isLoggingOut = true
        
        Task {
            do {
                try await supabase.signOut()
                await MainActor.run {
                    isLoggingOut = false
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    print("Logout error: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    var destructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(destructive ? .red.opacity(0.8) : .white.opacity(0.9))
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(destructive ? .red.opacity(0.9) : .white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.0))
        }
        .buttonStyle(.plain)
    }
}

struct SettingsLanguagePicker: View {
    let icon: String
    let title: String
    @Binding var selectedLanguage: String
    let languages: [String]
    @Binding var isSaving: Bool
    let onSave: () -> Void
    @State private var showPicker = false
    
    var body: some View {
        Button(action: { showPicker = true }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Text(selectedLanguage)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding()
            .background(Color.white.opacity(0.0))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .confirmationDialog("Select Default Language", isPresented: $showPicker, titleVisibility: .visible) {
            ForEach(languages, id: \.self) { language in
                Button(language) {
                    selectedLanguage = language
                    onSave()
                }
            }
        }
    }
}
