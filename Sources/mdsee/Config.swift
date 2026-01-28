import Foundation
import Yams

struct AppConfig: Codable {
    var theme: String?

    static func load() -> AppConfig {
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/mdsee/config.yaml")

        guard FileManager.default.fileExists(atPath: configPath.path),
              let contents = try? String(contentsOf: configPath, encoding: .utf8),
              let config = try? YAMLDecoder().decode(AppConfig.self, from: contents) else {
            return AppConfig()
        }

        return config
    }
}
