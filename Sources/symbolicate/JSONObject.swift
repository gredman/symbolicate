import Foundation

typealias JSONObject = [String: Any]

extension JSONObject {
    struct MissingPropertyError: Error {
        let key: String
    }

    struct PropertyTypeError: Error {
        let key: String
        let expectedType: Any.Type
        let actualType: Any.Type
    }

    struct PropertyFormatError: Error {
        let key: String
        let value: String
        let expectedType: Any.Type
    }

    func required<T>(_ key: String) throws -> T {
        guard let raw = self[key] else {
            throw MissingPropertyError(key: key)
        }
        guard let result = raw as? T else {
            throw PropertyTypeError(key: key, expectedType: T.self, actualType: type(of: raw))
        }
        return result
    }

    func optional<T>(_ key: String) throws -> T? {
        guard let raw = self[key] else { return nil }
        guard let result = raw as? T else {
            throw PropertyTypeError(key: key, expectedType: T.self, actualType: type(of: raw))
        }
        return result
    }

    func required(_ key: String) throws -> UUID {
        let uuidString: String = try required(key)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw PropertyFormatError(key: key, value: uuidString, expectedType: UUID.self)
        }
        return uuid
    }
}