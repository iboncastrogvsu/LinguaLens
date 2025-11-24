import Foundation
import Supabase
import Combine

// User Profile model
struct UserProfile: Codable {
    let id: UUID
    let username: String
    let email: String
    let defaultLanguage: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case defaultLanguage = "default_language"
        case createdAt = "created_at"
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    
    private init() {
        guard let supabaseURL = URL(string: "https://idunpnsubrhpvoxiugfc.supabase.co") else {
            fatalError("Invalid Supabase URL. Please update with your project URL from https://supabase.com/dashboard/project/_/settings/api")
        }
        
        let supabaseKey = "sb_publishable_NLtSfFG0ZYlu_068q7qgAQ_8tm7tvlG"
        
        guard !supabaseKey.isEmpty else {
            fatalError("Invalid Supabase anon key. Please update with your anon key from https://supabase.com/dashboard/project/_/settings/api")
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        // Check if user is already logged in
        Task {
            await checkAuthStatus()
        }
    }
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        let existingUsers: [UserProfile] = try await client
            .from("profiles")
            .select()
            .eq("username", value: username)
            .execute()
            .value
        
        if !existingUsers.isEmpty {
            throw NSError(domain: "SupabaseManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Username is already taken"
            ])
        }
        
        // Sign up the user
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        let user = response.user
        
        // Create user profile
        let profile = UserProfile(
            id: user.id,
            username: username,
            email: email,
            defaultLanguage: "Spanish",
            createdAt: Date()
        )
        
        try await client
            .from("profiles")
            .insert(profile)
            .execute()
        
        await MainActor.run {
            self.currentUser = user
            self.userProfile = profile
            self.isAuthenticated = true
        }
        
        return user
    }
    
    func signIn(emailOrUsername: String, password: String) async throws -> User {
        var email = emailOrUsername
        
        // Check if input is a username instead of email
        if !emailOrUsername.contains("@") {
            // Look up email by username
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .eq("username", value: emailOrUsername)
                .execute()
                .value
            
            guard let profile = profiles.first else {
                throw NSError(domain: "SupabaseManager", code: 3, userInfo: [
                    NSLocalizedDescriptionKey: "Username not found"
                ])
            }
            
            email = profile.email
        }
        
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Fetch user profile
        await fetchUserProfile(userId: session.user.id)
        
        await MainActor.run {
            self.currentUser = session.user
            self.isAuthenticated = true
        }
        
        return session.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        
        await MainActor.run {
            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false
        }
    }
    
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            
            if session.isExpired {
                // Session expired, clear auth state
                await MainActor.run {
                    self.currentUser = nil
                    self.userProfile = nil
                    self.isAuthenticated = false
                }
                return
            }
            
            // Fetch user profile
            await fetchUserProfile(userId: session.user.id)
            
            await MainActor.run {
                self.currentUser = session.user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.userProfile = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func fetchUserProfile(userId: UUID) async {
        do {
            let profiles: [UserProfile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            await MainActor.run {
                self.userProfile = profiles.first
            }
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
        }
    }
    
    func updateDefaultLanguage(_ language: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await client
            .from("profiles")
            .update(["default_language": language])
            .eq("id", value: userId.uuidString)
            .execute()
        
        // Update local profile
        if let profile = userProfile {
            await MainActor.run {
                self.userProfile = UserProfile(
                    id: profile.id,
                    username: profile.username,
                    email: profile.email,
                    defaultLanguage: language,
                    createdAt: profile.createdAt
                )
            }
        }
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    var userEmail: String {
        userProfile?.email ?? currentUser?.email ?? ""
    }
    
    var userName: String {
        userProfile?.username ?? ""
    }
    
    var userId: String {
        currentUser?.id.uuidString ?? ""
    }
    
    var defaultLanguage: String {
        userProfile?.defaultLanguage ?? "English"
    }
}
