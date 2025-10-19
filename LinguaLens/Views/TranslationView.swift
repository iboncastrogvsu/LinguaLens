import SwiftUI

struct TranslationView: View {
    let extractedText: String
    @State private var targetLanguage = "Spanish"
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var showLanguagePicker = false
    @Environment(\.dismiss) var dismiss
    
    let languages = ["Spanish", "French", "German", "Italian", "Portuguese", "Chinese", "Japanese", "Korean", "Arabic", "Russian"]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.9),
                                                       Color.indigo.opacity(0.9)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Original Text Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Original Text")
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
                    
                    // Language Selector
                    Button {
                        showLanguagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Translate to: \(targetLanguage)")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
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
                    .disabled(isTranslating)
                    
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
        .confirmationDialog("Select Language", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            ForEach(languages, id: \.self) { language in
                Button(language) {
                    targetLanguage = language
                }
            }
        }
    }
    
    private func translateText() {
        isTranslating = true
        
        // Simulate translation API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                translatedText = "This is a simulated translation of the text to \(targetLanguage). In production, this would call a real translation API."
                isTranslating = false
            }
        }
    }
}
