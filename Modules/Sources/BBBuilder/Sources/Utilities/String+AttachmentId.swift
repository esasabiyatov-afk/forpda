//
//  String+AttachmentId.swift
//  ForPDA
//

import Foundation

extension String {
    /// Extracts attachment id from BB attribute like `"123:file.png"`, `=123:name` or `123`.
    /// Returns nil instead of crashing on malformed input.
    var bbAttachmentId: Int? {
        let idPart = firstIndex(of: ":").map { self[..<$0] } ?? self[...]
        let digits = idPart.filter(\.isNumber)
        return digits.isEmpty ? nil : Int(digits)
    }
}
