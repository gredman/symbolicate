import Foundation

extension Int {
    var hexString: String {
        "0x" + String(self, radix: 16)
    }
}

extension Process {
    struct ProcessError: Error {}

    static func standardOutput(command: [String]) throws -> Data {
        // TODO: encode file paths etc.
        let command = command.joined(separator: " ")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let stdout = Pipe()
        process.standardOutput = stdout

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0, let output = try stdout.fileHandleForReading.readToEnd() else {
            throw ProcessError()
        }

        return output
    }
}

struct Symbolicator {
    let symbolsURL: URL
    let symbolsUUID: UUID

    init(symbolsURL: URL) throws {
        self.symbolsURL = symbolsURL

        let data = try Process.standardOutput(command: ["dwarfdump", "--uuid", "'" + symbolsURL.path + "'"])
        let uuidData = data.split(separator: Character(" ").asciiValue!)[1]
        let uuidString = String(data: uuidData, encoding: .utf8)!
        symbolsUUID = UUID(uuidString: uuidString)!
    }

    func symbolicate(report: AnalyticsReport) throws -> AnalyticsReport {
        var report = report
        let threads = try report.details.threads.map {
            try symbolicate(thread: $0, images: report.details.usedImages)
        }
        report.details.setThreads(threads)
        return report
    }

    private func symbolicate(thread: Thread, images: [Image]) throws -> Thread {
        var thread = thread
        let frames = try thread.frames.map {
            try symbolicate(frame: $0, images: images)
        }
        thread.setFrames(frames)
        return thread
    }

    private func symbolicate(frame: Frame, images: [Image]) throws -> Frame {
        var frame = frame

        let image = try images[frame.imageIndex]
        frame.image = image

        let address = try image.base + frame.imageOffset
        frame.address = address

        if try frame.symbol == nil, try symbolsUUID == image.uuid {
            let atos = try [
                "atos",
                "-arch",
                image.arch,
                "-o",
                "'" + symbolsURL.path + "'",
                "-l",
                image.base.hexString,
                address.hexString
            ]

            let output = try Process.standardOutput(command: atos)
            let symbol = String(data: output, encoding: .utf8)!
            frame.setSymbol(symbol)
        }
        return frame
    }
}