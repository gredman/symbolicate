import Foundation

extension UInt8 {
    static let newline = Character("\n").asciiValue!
}

struct Frame {
    var json: JSONObject

    var address: Int?
    var image: Image?

    init(json: JSONObject) {
        self.json = json
    }

    var imageOffset: Int {
        get throws {
            try json.required("imageOffset")
        }
    }

    var imageIndex: Int {
        get throws {
            try json.required("imageIndex")
        }
    }

    var symbol: String? {
        get throws {
            try json.optional("symbol")
        }
    }

    var symbolLocation: Int? {
        get throws {
            try json.optional("symbolLocation")
        }
    }

    mutating func setSymbol(_ symbol: String) {
        json["symbol"] = symbol
    }
}

struct Thread {
    var json: JSONObject

    var frames: [Frame] {
        get throws {
            let array: [JSONObject] = try json.required("frames")
            return array.map(Frame.init(json:))
        }
    }

    mutating func setFrames(_ frames: [Frame]) {
        json["frames"] = frames.map(\.json)
    }
}

struct Image {
    let json: JSONObject

    var arch: String {
        get throws {
            try json.required("arch")
        }
    }

    var base: Int {
        get throws {
            try json.required("base")
        }
    }

    var uuid: UUID {
        get throws {
            try json.required("uuid")
        }
    }

    var path: String {
        get throws {
            try json.required("path")
        }
    }

    var name: String {
        get throws {
            try json.required("name")
        }
    }
}

struct AnalyticsReport {
    struct Metadata {
        let json: JSONObject
    }

    struct Details {
        var json: JSONObject

        var threads: [Thread] {
            get throws {
                let array: [JSONObject] = try json.required("threads")
                return array.map(Thread.init(json:))
            }
        }

        var usedImages: [Image] {
            get throws {
                let array: [JSONObject] = try json.required("usedImages")
                return array.map(Image.init(json:))
            }
        }

        mutating func setThreads(_ threads: [Thread]) {
            json["threads"] = threads.map(\.json)
        }
    }

    let metadata: Metadata
    var details: Details

    init(url: URL) throws {
        let data = try Data(contentsOf: url)

        let preamble = data.prefix(while: { $0 != .newline })
        let metadataJSON = try JSONSerialization.jsonObject(with: preamble, options: []) as! JSONObject

        let remainder = data.drop(while: { $0 != .newline })
        let detailsJSON = try JSONSerialization.jsonObject(with: remainder, options: []) as! JSONObject

        metadata = Metadata(json: metadataJSON)
        details = Details(json: detailsJSON)
    }

    func write(to fileHandle: FileHandle) throws {
        let preamble = try JSONSerialization.data(withJSONObject: metadata.json, options: [])
        let remainder = try JSONSerialization.data(withJSONObject: details.json, options: [])

        try fileHandle.write(contentsOf: preamble)
        try fileHandle.write(contentsOf: Data([.newline]))
        try fileHandle.write(contentsOf: remainder)
    }
}