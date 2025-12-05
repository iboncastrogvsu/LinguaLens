import SwiftUI
import PhotosUI
import AVFoundation

struct CameraView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var selectedImage: PhotosPickerItem?
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var extractedText = ""
    @State private var showTranslation = false
    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showCameraNotAvailableAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.indigo.opacity(0.9),
                        Color.purple.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
                    
                    if isProcessing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Extracting text from image...")
                                .foregroundStyle(.white)
                                .font(.subheadline)
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 20) {
                        
                        Button {
                            checkCameraAvailability()
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
                        .disabled(isProcessing)
                        
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
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                }
                .padding(.top, 60)
            }
            .navigationDestination(isPresented: $showTranslation) {
                TranslationView(
                    extractedText: extractedText,
                    capturedImage: capturedImage
                )
            }
            .sheet(isPresented: $showCamera) {
                CameraCapture(capturedImage: $capturedImage)
            }
            .onChange(of: selectedImage) { _, newValue in
                Task {
                    if let newValue { await processSelectedImage(newValue) }
                }
            }
            .onChange(of: capturedImage) { _, newValue in
                if let img = newValue {
                    Task { await processImage(img) }
                }
            }
            .alert("Camera Not Available", isPresented: $showCameraNotAvailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Camera is not available on this device or camera access has been denied. Please check your device settings.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func checkCameraAvailability() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraNotAvailableAlert = true
            return
        }
        
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.showCamera = granted
                    self.showCameraNotAvailableAlert = !granted
                }
            }
        case .denied, .restricted:
            showCameraNotAvailableAlert = true
        default:
            showCameraNotAvailableAlert = true
        }
    }
    
    private func processSelectedImage(_ item: PhotosPickerItem) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                await MainActor.run {
                    errorMessage = "Failed to load image"
                    showError = true
                }
                return
            }
            
            // Directly process without cropping
            capturedImage = image
            
        } catch {
            await MainActor.run {
                errorMessage = "Error loading image: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let text = try await OCRService.shared.recognizeText(from: image)
            
            await MainActor.run {
                self.extractedText = text
                self.showTranslation = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error extracting text: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

struct CameraCapture: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.showsCameraControls = true
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapture
        
        init(_ parent: CameraCapture) { self.parent = parent }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = fixOrientation(img: image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func fixOrientation(img: UIImage) -> UIImage {
            if img.imageOrientation == .up { return img }
            UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
            img.draw(in: CGRect(origin: .zero, size: img.size))
            let normalized = UIGraphicsGetImageFromCurrentImageContext() ?? img
            UIGraphicsEndImageContext()
            return normalized
        }
    }
}
