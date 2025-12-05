import SwiftUI

struct TranslationView: View {
    let extractedText: String
    let capturedImage: UIImage?
    
    @StateObject private var supabase = SupabaseManager.shared
    @State private var sourceLanguage = ""
    @State private var targetLanguage = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var isSaving = false
    @State private var showLanguagePicker = false
    @State private var showSourceLanguagePicker = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccessMessage = false
    @Environment(\.dismiss) var dismiss
    
    let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic", "Russian"]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.9),
                                                       Color.indigo.opacity(0.9)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Captured Image Preview
                    if let image = capturedImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Captured Image")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Original Text Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Extracted Text")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = extractedText
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        
                        Text(extractedText)
                            .font(.body)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Language Selectors
                    HStack(spacing: 12) {
                        // Source Language
                        Button {
                            showSourceLanguagePicker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("From")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(sourceLanguage.isEmpty ? "Detect" : sourceLanguage)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.white.opacity(0.8))
                        
                        // Target Language
                        Button {
                            showLanguagePicker = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("To")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(targetLanguage)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Translate Button
                    Button {
                        translateText()
                    } label: {
                        HStack {
                            if isTranslating {
                                ProgressView()
                                    .tint(.indigo)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            Text(isTranslating ? "Translating..." : "Translate")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.indigo)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isTranslating || targetLanguage.isEmpty)
                    
                    // Translation Result
                    if !translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Translation")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = translatedText
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            
                            Text(translatedText)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                            
                            // Save Button
                            Button {
                                saveTranslation()
                            } label: {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    } else if showSuccessMessage {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Saved!")
                                    } else {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Save Translation")
                                    }
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(showSuccessMessage ? Color.green.opacity(0.8) : Color.indigo.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .disabled(isSaving || showSuccessMessage)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Translate")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .confirmationDialog("Select Target Language", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            ForEach(languages, id: \.self) { language in
                Button(language) {
                    targetLanguage = language
                }
            }
        }
        .confirmationDialog("Select Source Language", isPresented: $showSourceLanguagePicker, titleVisibility: .visible) {
            Button("Auto-detect") {
                sourceLanguage = ""
            }
            ForEach(languages, id: \.self) { language in
                Button(language) {
                    sourceLanguage = language
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Auto-detect source language
            if sourceLanguage.isEmpty {
                sourceLanguage = OCRService.shared.detectLanguage(from: extractedText)
            }
            // Set target language from user's default
            if targetLanguage.isEmpty {
                targetLanguage = supabase.defaultLanguage
            }
        }
    }
    
    private func translateText() {
        isTranslating = true
        showSuccessMessage = false
        
        let finalSourceLanguage = sourceLanguage.isEmpty ? "Auto-detect" : sourceLanguage
        
        Task {
            do {
                let translation = try await TranslationService.shared.translate(
                    text: extractedText,
                    from: finalSourceLanguage,
                    to: targetLanguage
                )
                
                await MainActor.run {
                    withAnimation {
                        translatedText = translation
                        isTranslating = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTranslating = false
                    errorMessage = "Translation failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func saveTranslation() {
        isSaving = true
        
        Task {
            do {
                // Upload image if available
                var imageUrl: String? = nil
                if let image = capturedImage {
                    imageUrl = try await supabase.uploadImage(image)
                }
                
                // Save translation to database
                _ = try await supabase.saveTranslation(
                    originalText: extractedText,
                    translatedText: translatedText,
                    sourceLanguage: sourceLanguage.isEmpty ? "Auto-detect" : sourceLanguage,
                    targetLanguage: targetLanguage,
                    imageUrl: imageUrl
                )
                
                await MainActor.run {
                    isSaving = false
                    showSuccessMessage = true
                    
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
