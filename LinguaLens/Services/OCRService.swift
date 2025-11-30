import Foundation
import Vision
import UIKit
import NaturalLanguage

class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    let fullText = recognizedStrings.joined(separator: "\n")
                    continuation.resume(returning: fullText)
                }
            }
            
            // Configure request for better accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-BR", "zh-Hans", "ja-JP", "ko-KR", "ar-SA", "ru-RU"]
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Detect language of text
    func detectLanguage(from text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let languageCode = recognizer.dominantLanguage?.rawValue else {
            return "Unknown"
        }
        
        return languageCodeToName(languageCode)
    }
    
    private func languageCodeToName(_ code: String) -> String {
        let mapping: [String: String] = [
            "en": "English",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean",
            "ar": "Arabic",
            "ru": "Russian"
        ]
        return mapping[code] ?? "Unknown"
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid"
        case .noTextFound:
            return "No text was found in the image"
        case .processingFailed:
            return "Failed to process the image"
        }
    }
}
