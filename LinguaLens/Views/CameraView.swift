import SwiftUI
import PhotosUI

struct CameraView: View {
    @State private var selectedImage: PhotosPickerItem?
    @State private var showCamera = false
    @State private var capturedText = ""
    @State private var showTranslation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.9),
                                                           Color.purple.opacity(0.9)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("Capture Text")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Take a photo or upload an image to extract and translate text")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Camera Button
                        Button {
                            showCamera = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Take Photo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.indigo)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        
                        // Photo Library Button
                        PhotosPicker(selection: $selectedImage, matching: .images) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Choose from Library")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.25))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                }
                .padding(.top, 60)
            }
            .navigationDestination(isPresented: $showTranslation) {
                TranslationView(extractedText: capturedText)
            }
            .sheet(isPresented: $showCamera) {
                CameraCapture(capturedText: $capturedText, showTranslation: $showTranslation)
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if newValue != nil {
                    // Simulate OCR text extraction
                    capturedText = "Sample extracted text from image"
                    showTranslation = true
                }
            }
        }
    }
}

// Placeholder for Camera Capture View
struct CameraCapture: View {
    @Environment(\.dismiss) var dismiss
    @Binding var capturedText: String
    @Binding var showTranslation: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                Button {
                    // Simulate capture and OCR
                    capturedText = "Sample captured text"
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTranslation = true
                    }
                } label: {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 40)
            }
            
            Text("Camera Preview")
                .foregroundColor(.white.opacity(0.5))
                .font(.title)
        }
    }
}
