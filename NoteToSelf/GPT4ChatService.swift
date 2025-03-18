import Foundation
import OpenAI

final class GPT4ChatService {
    static let shared = GPT4ChatService()
    private let openAIClient: ResponsesAPI

    private init() {
        let apiKey = Configuration.openAIAPIKey
        self.openAIClient = ResponsesAPI(authToken: apiKey)
    }
    
    func sendMessage(systemPrompt: String, userMessage: String) async throws -> String {
        let request = Request(
            model: "gpt-4o",
            input: .text(userMessage),
            instructions: systemPrompt
        )
        let result = try await openAIClient.create(request)
        switch result {
        case .success(let response):
            return response.outputText ?? ""
        case .failure(let error):
            throw error
        }
    }
}