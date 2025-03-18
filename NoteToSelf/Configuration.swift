import Foundation

struct Configuration {
    static var openAIAPIKey: String {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let apiKey = plist["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty else {
            fatalError("Missing OPENAI_API_KEY in Config.plist")
        }
        return apiKey
    }
}