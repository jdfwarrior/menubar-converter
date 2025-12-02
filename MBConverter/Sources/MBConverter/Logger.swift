import Foundation

final class Logger {
    static let shared = Logger()
    let logsDirectory: URL
    private let fileURL: URL
    private let queue = DispatchQueue(label: "logger.queue")
    private let maxSize: UInt64 = 5 * 1024 * 1024 // 5 MB
    private let maxFiles = 5

    private init() {
        let fm = FileManager.default
        let base = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("MBConverter")
        self.logsDirectory = base.appendingPathComponent("logs")
        try? fm.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        self.fileURL = logsDirectory.appendingPathComponent("mbconverter.log")
    }

    func log(_ message: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let line = "[\(ts)] \(message)\n"
        queue.async {
            if let data = line.data(using: .utf8) {
                if !FileManager.default.fileExists(atPath: self.fileURL.path) {
                    FileManager.default.createFile(atPath: self.fileURL.path, contents: data)
                } else if let fh = try? FileHandle(forWritingTo: self.fileURL) {
                    defer { try? fh.close() }
                    do {
                        try fh.seekToEnd()
                        try fh.write(contentsOf: data)
                    } catch {
                        // ignore write errors
                    }
                }
                self.rotateIfNeeded()
            }
        }
    }

    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? UInt64 else { return }
        if size < maxSize { return }

        for i in stride(from: maxFiles - 1, through: 1, by: -1) {
            let from = logsDirectory.appendingPathComponent("mbconverter.log.\(i)")
            let to = logsDirectory.appendingPathComponent("mbconverter.log.\(i+1)")
            if FileManager.default.fileExists(atPath: from.path) {
                try? FileManager.default.moveItem(at: from, to: to)
            }
        }
        let first = logsDirectory.appendingPathComponent("mbconverter.log.1")
        try? FileManager.default.moveItem(at: fileURL, to: first)
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
    }
}
