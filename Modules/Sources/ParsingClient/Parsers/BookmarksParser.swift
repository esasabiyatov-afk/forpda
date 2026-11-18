//
//  BookmarksParser.swift
//  ForPDA
//
//  Created by Xialtal on 30.11.24.
//

import Foundation
import Models

public struct BookmarksParser {
    public static func parse(from string: String) throws -> [Bookmark] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }

                return (array.cast(4, [[Any]].self)).map { bookmark in
                    return Bookmark(
                        id: bookmark.cast(0, Int.self),
                        parentId: bookmark.cast(4, Int.self),
                        name: bookmark.cast(6, String.self),
                        number: bookmark.cast(5, Int.self),
                        format: bookmarkFormat(bookmark),
                        updatedAt: Date(timeIntervalSince1970: bookmark.cast(1, Double.self)),
                        deleted: (bookmark.cast(2, Int.self)) == 0 ? false : true
                    )
                }
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func bookmarkFormat(_ array: [Any]) -> Bookmark.Format {
        return if (array.cast(3, Int.self)) == 1 { .folder } else {
            .url(url: URL.parsed(array.cast(7, String.self)))
        }
    }
}
