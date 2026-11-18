//
//  Array+SafeCast.swift
//  ForPDA
//
//  Crash-safe replacement for `fields[i] as! T` in parsers.
//  If the server changes its response format (missing field, different type),
//  the parser returns an empty/zero value and logs it instead of crashing the app.
//

import Foundation
import OSLog

protocol ParsingDefaultValue {
    static var parsingDefault: Self { get }
}

extension Int: ParsingDefaultValue { static var parsingDefault: Int { 0 } }
extension Double: ParsingDefaultValue { static var parsingDefault: Double { 0 } }
extension Bool: ParsingDefaultValue { static var parsingDefault: Bool { false } }
extension String: ParsingDefaultValue { static var parsingDefault: String { "" } }
extension Array: ParsingDefaultValue { static var parsingDefault: [Element] { [] } }
extension Dictionary: ParsingDefaultValue { static var parsingDefault: [Key: Value] { [:] } }

private let safeCastLogger = Logger(subsystem: "com.subvert.forpda", category: "Parsing")

extension Array where Element == Any {

    /// Returns the element at `index` cast to `T`, or a default value if it's missing or has another type.
    func cast<T: ParsingDefaultValue>(
        _ index: Int,
        _ type: T.Type = T.self,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> T {
        guard indices.contains(index) else {
            safeCastLogger.error("Missing field [\(index)] (count \(self.count)) at \(file):\(line)")
            return T.parsingDefault
        }
        if let value = self[index] as? T {
            return value
        }
        // Numbers sometimes come as strings and vice versa
        let raw = self[index]
        if T.self == Int.self, let string = raw as? String, let int = Int(string) {
            return int as! T
        }
        if T.self == Double.self, let string = raw as? String, let double = Double(string) {
            return double as! T
        }
        if T.self == String.self, let number = raw as? NSNumber {
            return number.stringValue as! T
        }
        safeCastLogger.error("Field [\(index)] is \(String(describing: Swift.type(of: raw))), expected \(String(describing: T.self)) at \(file):\(line)")
        return T.parsingDefault
    }
}

extension Array where Element == [Any] {

    /// Returns the nested array at `index`, or an empty array if it's missing.
    func row(_ index: Int) -> [Any] {
        indices.contains(index) ? self[index] : []
    }
}

extension URL {

    /// Crash-safe replacement for `URL(string: x)!`.
    /// Tries to percent-encode malformed strings (spaces, Cyrillic, protocol-relative `//host/...`)
    /// and falls back to `about:blank` instead of crashing.
    static func parsed(_ string: String) -> URL {
        if let url = URL(string: string) { return url }
        var fixed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if fixed.hasPrefix("//") { fixed = "https:" + fixed }
        if let url = URL(string: fixed) { return url }
        if let encoded = fixed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded) {
            return url
        }
        safeCastLogger.error("Invalid URL string: \(string, privacy: .public)")
        return URL(string: "about:blank")!
    }
}
