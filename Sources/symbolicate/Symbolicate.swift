import ArgumentParser
import Foundation

@main
struct Symbolicate: ParsableCommand {
    @Option(name: .customLong("report"), help: "Path to the ips crash report file.")
    var reportFile: String

    @Option(name: .customLong("symbols"), parsing: .upToNextOption, help: "Path to dSYM symbols file.")
    var symbolFiles: [String]

    @Option(name: .customLong("output"), help: "Path to output file")
    var outputFile: String?

    mutating func run() throws {
        let reportFileURL = URL(fileURLWithPath: reportFile)
        let symbolFileURLs = symbolFiles.map(URL.init(fileURLWithPath:))

        var report = try AnalyticsReport(url: reportFileURL)
        for url in symbolFileURLs {
            let symbolicator = try Symbolicator(symbolsURL: url)
            report = try symbolicator.symbolicate(report: report)
        }

        let outputHandle: FileHandle
        if let outputFile = outputFile {
            FileManager.default.createFile(atPath: outputFile, contents: nil, attributes: [:])
            let url = URL(fileURLWithPath: outputFile)
            outputHandle = try FileHandle(forWritingTo: url)
        } else {
            outputHandle = .standardOutput
        }

        try report.write(to: outputHandle)
    }
}