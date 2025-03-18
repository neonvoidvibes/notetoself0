import OpenAI
import Foundation

extension Model: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let data = "\"\(value)\"".data(using: .utf8)!
        do {
            self = try JSONDecoder().decode(Model.self, from: data)
        } catch {
            fatalError("Failed to decode Model from string literal: \(error)")
        }
    }
}