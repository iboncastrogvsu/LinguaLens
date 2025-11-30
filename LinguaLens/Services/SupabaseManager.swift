import Foundation
import Supabase
import Combine
import UIKit

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

struct Translation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let imageUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case originalText = "original_text"
        case translatedText = "translated_text"
        case sourceLanguage = "source_language"
        case targetLanguage = "target_language"
        case imageUrl = "image_url"
        case createdAt = "created_at"
    }
}

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var translations: [Translation] = []
    
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
            self.translations = []
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
    
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "SupabaseManager", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Failed to compress image"
            ])
        }
        
        // Create unique filename with user folder for organization
        let filename = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        
        print("Uploading image: \(filename)")
        print("Size: \(imageData.count) bytes")
        
        do {
            // Upload to Supabase Storage
            try await client.storage
                .from("translation-images")
                .upload(
                    filename,
                    data: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )
            
            // Get public URL
            let publicURL = try client.storage
                .from("translation-images")
                .getPublicURL(path: filename)
            
            print("Image uploaded successfully: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            print("Upload error: \(error)")
            throw NSError(domain: "SupabaseManager", code: 7, userInfo: [
                NSLocalizedDescriptionKey: "Failed to upload image: \(error.localizedDescription)"
            ])
        }
    }

    func saveTranslation(
        originalText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String,
        imageUrl: String?
    ) async throws -> Translation {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        print("Saving translation for user: \(userId)")
        
        let translation = Translation(
            id: UUID(),
            userId: userId,
            originalText: originalText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            imageUrl: imageUrl,
            createdAt: Date()
        )
        
        try await client
            .from("translations")
            .insert(translation)
            .execute()
        
        print("Translation saved successfully")
        
        // Refresh translations list
        await fetchTranslations()
        
        return translation
    }

    func fetchTranslations() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let fetchedTranslations: [Translation] = try await client
                .from("translations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.translations = fetchedTranslations
            }
            
            print("Fetched \(fetchedTranslations.count) translations")
        } catch {
            print("Error fetching translations: \(error.localizedDescription)")
        }
    }

    func deleteTranslation(id: UUID) async throws {
        print("🗑️ Deleting translation: \(id)")
        
        // First, get the translation to find the image URL
        let translations: [Translation] = try await client
            .from("translations")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        guard let translation = translations.first else {
            throw NSError(domain: "SupabaseManager", code: 8, userInfo: [
                NSLocalizedDescriptionKey: "Translation not found"
            ])
        }
        
        // Delete the image from storage if it exists
        if let imageUrl = translation.imageUrl {
            try await deleteImageFromStorage(imageUrl: imageUrl)
        }
        
        // Delete the translation record
        try await client
            .from("translations")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        print("Translation deleted from database")
        
        await fetchTranslations()
    }

    func deleteAllTranslations() async throws {
        guard let userId = currentUser?.id else { return }
        
        print("Deleting all translations for user: \(userId)")
        
        // First, get all translations to find image URLs
        let translations: [Translation] = try await client
            .from("translations")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        print("Found \(translations.count) translations to delete")
        
        // Delete all images from storage
        for translation in translations {
            if let imageUrl = translation.imageUrl {
                try? await deleteImageFromStorage(imageUrl: imageUrl)
            }
        }
        
        // Delete all translation records
        try await client
            .from("translations")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        print("All translations deleted")
        
        await fetchTranslations()
    }
    
    // Helper function to delete image from storage
    private func deleteImageFromStorage(imageUrl: String) async throws {
        guard let userId = currentUser?.id else {
            print("No current user - cannot determine storage path")
            return
        }
        
        print("Attempting to delete image: \(imageUrl)")
        
        // Extract just the UUID filename from URL
        // URL format: https://...supabase.co/storage/v1/object/public/translation-images/userId/uuid.jpg
        guard let lastComponent = imageUrl.components(separatedBy: "/").last else {
            print("Could not extract filename from URL")
            return
        }
        
        // Reconstruct the full path with user folder (matching upload format)
        let fullPath = "\(userId.uuidString)/\(lastComponent)"
        print("Full storage path: \(fullPath)")
        
        do {
            try await client.storage
                .from("translation-images")
                .remove(paths: [fullPath])
            
            print("Image deleted from storage: \(fullPath)")
        } catch {
            print("Failed to delete image from storage: \(error.localizedDescription)")
        
        }
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
