import Foundation

class TranslationService {
    static let shared = TranslationService()
    
    private let apiKey = "<groq-api-key>"
    
    private init() {}
    
    func translate(text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        return try await translateWithGroq(text: text, from: sourceLanguage, to: targetLanguage)
    }
    
    // MARK: - Groq Implementation
    private func translateWithGroq(text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        Translate the following text from \(sourceLanguage) to \(targetLanguage). 
        Preserve the formatting, line breaks, and structure of the original text.
        Only provide the translation, without any explanations or additional text.
        
        Text to translate:
        \(text)
        """
        
        let payload: [String: Any] = [
            "model": "llama-3.1-8b-instant",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a professional translator. Translate text accurately while preserving formatting and context. Only output the translation without any preamble or explanation."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.3,
            "max_tokens": 4096,
            "top_p": 1,
            "stream": false
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from Groq
            if let errorResponse = try? JSONDecoder().decode(GroqErrorResponse.self, from: data) {
                throw TranslationError.apiError(statusCode: httpResponse.statusCode, message: errorResponse.error.message)
            }
            throw TranslationError.apiError(statusCode: httpResponse.statusCode, message: nil)
        }
        
        let result = try JSONDecoder().decode(GroqResponse.self, from: data)
        
        guard let translatedText = result.choices.first?.message.content else {
            throw TranslationError.noTranslation
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct GroqResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct GroqErrorResponse: Codable {
    let error: ErrorDetail
    
    struct ErrorDetail: Codable {
        let message: String
        let type: String
    }
}

enum TranslationError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String?)
    case noTranslation
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from translation service"
        case .apiError(let statusCode, let message):
            if let message = message {
                return "Translation API error (Status: \(statusCode)): \(message)"
            }
            return "Translation API error (Status: \(statusCode))"
        case .noTranslation:
            return "No translation was returned"
        case .networkError:
            return "Network error occurred"
        }
    }
}
