import Foundation
import AppKit
import UserNotifications

final class Converter {
    private var timer: DispatchSourceTimer?
    private var isConverting = false
    private let queue = DispatchQueue(label: "converter.queue")
    private var config: Config?
    private(set) var handBrakeURL: URL?

    func start() {
        reloadConfig()
        detectHandBrake()
        scheduleTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func reloadConfig() {
        config = Config.load()
        if config == nil {
            Logger.shared.log("No config found — using defaults and waiting for config")
        } else {
            Logger.shared.log("Loaded config: path=\(config!.path) interval=\(config!.interval)")
        }
    }

    private func scheduleTimer() {
        let interval = config?.interval ?? Config.defaultInterval
        timer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 1.0, repeating: interval)
        t.setEventHandler { [weak self] in
            self?.reloadConfig()
            self?.scanAndConvertOnce()
        }
        t.resume()
        timer = t
    }

    private func scanAndConvertOnce() {
        guard let cfg = config else { return }
        guard !isConverting else { return }
        // do not mark as converting here; mark only when a conversion actually starts
        // so we continue rescanning until we find work to do.

        let path = (cfg.path as NSString).expandingTildeInPath
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else {
            Logger.shared.log("Scan path does not exist: \(path)")
            return
        }

        let enumerator = fm.enumerator(atPath: path)
        while let item = enumerator?.nextObject() as? String {
            if item.lowercased().hasSuffix(".mkv") {
                let full = (path as NSString).appendingPathComponent(item)

                // check excludes from config
                if let excludes = cfg.exclude, excludes.count > 0 {
                    var excluded = false
                    for e in excludes {
                        let expanded = (e as NSString).expandingTildeInPath
                        // normalize by removing trailing slash from expanded
                        let normalized = expanded.hasSuffix("/") ? String(expanded.dropLast()) : expanded
                        if full.hasPrefix(normalized) {
                            Logger.shared.log("Skipping excluded path: \(full) matches exclude \(e)")
                            excluded = true
                            break
                        }
                    }
                    if excluded { continue }
                }

                Logger.shared.log("Found mkv: \(full)")
                isConverting = true
                convert(file: full)
                // Only start one conversion at a time
                break
            }
        }
    }

    private func convert(file: String) {
        guard let hb = handBrakeURL else {
            let msg = "HandBrakeCLI not found; skipping conversion for \(file). Set HAND_BRAKE_CLI_PATH or install HandBrakeCLI (brew install handbrake)."
            Logger.shared.log(msg)
            sendNotification(title: "MBConverter", body: "HandBrakeCLI not found — install with Homebrew: brew install handbrake")
            return
        }
        // announce conversion start
        NotificationCenter.default.post(name: .MBConverterStatusChange, object: nil, userInfo: ["state": "converting", "filename": (file as NSString).lastPathComponent])
        Logger.shared.log("Starting conversion: \(file)")

        let out = outputURL(for: file)
        let task = Process()
        task.executableURL = hb
        var args = ["-i", file, "-o", out.path]
        args += ["--preset=Apple 1080p60 Surround"]
        args += ["--optimize"]
        args += ["--audio-lang-list", "eng"]
        args += ["--all-subtitles"]
        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        var outputData = Data()
        pipe.fileHandleForReading.readabilityHandler = { fh in
            let d = fh.availableData
            if d.count > 0 {
                outputData.append(d)
            }
        }

        task.terminationHandler = { [weak self] proc in
            guard let self = self else { return }
            // read remaining output
            let remaining = pipe.fileHandleForReading.readDataToEndOfFile()
            if remaining.count > 0 {
                outputData.append(remaining)
            }
            pipe.fileHandleForReading.readabilityHandler = nil
            try? pipe.fileHandleForReading.close()

            if let outText = String(data: outputData, encoding: .utf8) {
                Logger.shared.log(outText)
            }

            if proc.terminationStatus == 0 {
                Logger.shared.log("Conversion succeeded: \(out.path)")
                try? FileManager.default.removeItem(atPath: file)
                self.sendNotification(title: "MBConverter", body: "Converted \((file as NSString).lastPathComponent)")
            } else {
                Logger.shared.log("Conversion failed for \(file), exit \(proc.terminationStatus)")
                self.sendNotification(title: "MBConverter", body: "Conversion failed for \((file as NSString).lastPathComponent)")
            }

            NotificationCenter.default.post(name: .MBConverterStatusChange, object: nil, userInfo: ["state": "idle"])

            // clear converting flag on our queue
            self.queue.async {
                self.isConverting = false
            }
        }

        do {
            try task.run()
        } catch {
            Logger.shared.log("Failed to start HandBrakeCLI: \(error)")
            // ensure we clear the converting flag if start fails
            self.queue.async {
                self.isConverting = false
            }
            NotificationCenter.default.post(name: .MBConverterStatusChange, object: nil, userInfo: ["state": "idle"])
            return
        }
    }

    private func detectHandBrake() {
        // Allow override via env var
        let env = ProcessInfo.processInfo.environment
        if let override = env["HAND_BRAKE_CLI_PATH"], !override.isEmpty {
            let url = URL(fileURLWithPath: (override as NSString).expandingTildeInPath)
            if FileManager.default.fileExists(atPath: url.path) {
                handBrakeURL = url
                Logger.shared.log("Using HandBrakeCLI from HAND_BRAKE_CLI_PATH=\(url.path)")
                return
            } else {
                Logger.shared.log("HAND_BRAKE_CLI_PATH set but file not found at \(override)")
            }
        }

        // Common locations
        let candidates = [
            "/opt/homebrew/bin/HandBrakeCLI",
            "/usr/local/bin/HandBrakeCLI",
            "/usr/bin/HandBrakeCLI"
        ]

        for p in candidates {
            if FileManager.default.fileExists(atPath: p) {
                handBrakeURL = URL(fileURLWithPath: p)
                Logger.shared.log("Found HandBrakeCLI at \(p)")
                return
            }
        }

        // Try PATH lookup
        if let path = findExecutableInPATH("HandBrakeCLI") {
            handBrakeURL = URL(fileURLWithPath: path)
            Logger.shared.log("Found HandBrakeCLI on PATH at \(path)")
            return
        }

        Logger.shared.log("HandBrakeCLI not found. Set HAND_BRAKE_CLI_PATH or install via Homebrew: 'brew install handbrake'")
    }

    private func findExecutableInPATH(_ name: String) -> String? {
        let env = ProcessInfo.processInfo.environment
        guard let pathEnv = env["PATH"] else { return nil }
        let paths = pathEnv.split(separator: ":").map { String($0) }
        for dir in paths {
            let candidate = (dir as NSString).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    private func outputURL(for inputPath: String) -> URL {
        let name = (inputPath as NSString).lastPathComponent
        let dir = (inputPath as NSString).deletingLastPathComponent
        let base = (name as NSString).deletingPathExtension

        var outputName = base + ".mp4"
        if base.contains(".") {
            let parts = base.split(separator: ".").map { String($0) }
            if let yearPart = parts.first(where: { $0.range(of: "^(19|20)\\d{2}$", options: .regularExpression) != nil }) {
                if let yearIndex = parts.firstIndex(of: yearPart) {
                    let title = parts[0..<yearIndex].joined(separator: " ")
                    outputName = "\(title) (\(yearPart)).mp4"
                }
            }
        }

        let safe = outputName.replacingOccurrences(of: "/", with: "-")
        return URL(fileURLWithPath: dir).appendingPathComponent(safe)
    }

    private func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(req)
    }
}
