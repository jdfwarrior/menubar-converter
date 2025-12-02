import Foundation

struct Config: Codable {
    let path: String
    let interval: TimeInterval
    let exclude: [String]?

    static let defaultInterval: TimeInterval = 60

    static func load() -> Config? {
        let fm = FileManager.default
        let url = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MBConverter")
            .appendingPathComponent("config.json")

        guard fm.fileExists(atPath: url.path) else {
            Logger.shared.log("Config not found at \(url.path)")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let cfg = try JSONDecoder().decode(Config.self, from: data)
            return cfg
        } catch {
            Logger.shared.log("Failed to load config: \(error)")
            return nil
        }
    }
}
