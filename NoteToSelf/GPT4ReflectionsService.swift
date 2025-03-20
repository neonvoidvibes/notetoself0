import Foundation
import OpenAI

final class GPT4ReflectionsService {
    static let shared = GPT4ReflectionsService()
    private let openAIClient: ResponsesAPI

    private init() {
        let apiKey = Configuration.openAIAPIKey
        self.openAIClient = ResponsesAPI(authToken: apiKey)
    }
    
    private func createModel(from id: String) -> Model {
        guard let data = "\"\(id)\"".data(using: .utf8),
              let model = try? JSONDecoder().decode(Model.self, from: data) else {
            fatalError("Failed to create Model from id \(id)")
        }
        return model
    }
    
    func sendMessage(systemPrompt: String, userMessage: String) async throws -> String {
        let model = createModel(from: "gpt-4o")
        let request = Request(
            model: model,
            input: .text(userMessage),
            instructions: systemPrompt
        )
        let result = try await openAIClient.create(request)
        switch result {
        case .success(let response):
            return response.outputText
        case .failure(let error):
            throw error
        }
    }
}