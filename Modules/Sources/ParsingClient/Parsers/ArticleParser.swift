//
//  ArticleParser.swift
//
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Models
import OSLog

public struct ArticleParser {
    
    /**
    0. 68111 - atomic
    1. 0 - ???
    2. 429778 - id
    3. 1720354500 - timestamp
    4. 0 - ???
    5. [] - ???
    6. 80 - flag ?
    7. 11029883 - author id
    8. "Оксана Рубко" - author name
    9. 0 - comments amount
    10. "https..." - image url
    11. "title" - title
    12. "description" - description
    13. [attachment] - attachments
    14. [tag] - tags
    15. [comment] - comments
    16. [] - ???
    */
    public static func parse(from string: String) throws -> Article {
        if let data = string.data(using: .utf8) {
            do {
                guard let fields = try JSONSerialization.jsonObject(with: data) as? [Any] else {
                    throw ParsingError.failedToCastDataToAny
                }
                
                let pollFields = fields.count > 16 ? fields.cast(16, [[Any]].self) : []
                
                return Article(
                    id: fields.cast(2, Int.self),
                    date: Date(timeIntervalSince1970: fields.cast(3, Double.self)),
                    flag: fields.cast(6, Int.self),
                    authorId: fields.cast(7, Int.self),
                    authorName: try (fields.cast(8, String.self)).convertHtmlCodes(),
                    commentsAmount: fields.cast(9, Int.self),
                    imageUrl: URL.parsed(fields.cast(10, String.self)),
                    title: try (fields.cast(11, String.self)).convertHtmlCodes(),
                    description: try (fields.cast(12, String.self)).convertHtmlCodes(),
                    attachments: try AttachmentParser.parseArticleAttachment(from: fields.cast(13, [[Any]].self)),
                    tags: extractTags(from: fields.cast(14, [[Any]].self)),
                    comments: try extractComments(from: fields.cast(15, [[Any]].self)),
                    poll: extractPoll(from: pollFields)
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    // MARK: - Helpers
    
    /**
    0. 24540 - id
    1. "!!технологии" - name
    */
    private static func extractTags(from array: [[Any]]) -> [Tag] {
        return array.map { fields in
            return Tag(
                id: fields.cast(0, Int.self),
                name: fields.cast(1, String.self)
            )
        }
    }
    
    /**
    0. 9425129 - id
    1. 1720355277 - date
    2. 0 - normal/deleted/edited/hidden
    3. 11393353 - author id
    4. "name" - author name
    5. 9425113 - parent id
    6. "text" - text
    7. 0 - likes amount
    8. "https..." - (optional) avatar url
    */
    private static func extractComments(from array: [[Any]]) throws -> [Comment] {
        var comments: [Comment] = try array.compactMap { fields in
            // Fix for some "[0]" aka empty comments
            if fields.count < 9 {
                // TODO: Add oslog
                print("[WARNING] Found empty comment, skipping iteration...")
                return nil
            }
            return Comment(
                id: fields.cast(0, Int.self),
                date: Date(timeIntervalSince1970: fields.cast(1, Double.self)),
                flag: fields.cast(2, Int.self),
                authorId: fields.cast(3, Int.self),
                authorName: try (fields.cast(4, String.self)).convertHtmlCodes(),
                parentId: fields.cast(5, Int.self),
                childIds: [],
                text: try (fields.cast(6, String.self)).convertHtmlCodes(),
                likesAmount: fields.cast(7, Int.self),
                avatarUrl: URL(string: fields.cast(8, String.self))
            )
        }
        
        for (index, comment) in comments.enumerated() {
            comments[index].childIds = comments.filter { $0.parentId == comment.id }.map { $0.id }
        }
        
        let intermediateComments = comments.map { IntermediateComment.from($0) }
        let nested = nestComments(intermediateComments)
        let flattened = flattenComments(nested)
        
        var result: [Comment] = []
        for (intermediate, level) in flattened {
            if var comment = comments.first(where: { $0.id == intermediate.id}) {
                comment.nestLevel = level
                result.append(comment)
            }
        }
        
        return result
    }
    
    private static func extractPoll(from array: [[Any]]) -> ArticlePoll? {
        guard !array.isEmpty else { return nil }
        return ArticlePoll(
            id: array.row(0).cast(0, Int.self),
            title: array.row(0).cast(1, String.self),
            flag: array.row(0).cast(2, Int.self),
            totalVotes: array.row(0).cast(3, Int.self),
            options: (array.row(0).cast(4, [[Any]].self)).map {
                ArticlePoll.Option(
                    id: $0.cast(0, Int.self),
                    text: $0.cast(1, String.self),
                    votes: $0.cast(2, Int.self)
                )
            }
        )
    }
    
    struct IntermediateComment {
        let id: Int
        let parentId: Int
        let childIds: [Int]
        var children: [IntermediateComment]
        
        static func from(_ comment: Comment) -> IntermediateComment {
            return IntermediateComment(
                id: comment.id,
                parentId: comment.parentId,
                childIds: comment.childIds,
                children: []
            )
        }
    }
    
    private static func nestComments(_ comments: [IntermediateComment]) -> [IntermediateComment] {
        // Create a dictionary to quickly access comments by ID
        var commentMap = [Int: IntermediateComment]()
        for comment in comments {
            commentMap[comment.id] = comment
        }
        
        // Helper function to build children recursively
        func buildChildren(for comment: inout IntermediateComment) {
            // For each childId, retrieve the child from the map, build its children, and append it
            for childId in comment.childIds {
                if var childComment = commentMap[childId] {
                    buildChildren(for: &childComment) // Recursively build the child's children
                    comment.children.append(childComment) // Append the built child
                }
            }
        }
        
        // Step 2: Build the tree structure, starting from the root comments
        var result: [IntermediateComment] = []
        
        for comment in comments {
            if comment.parentId == 0 {
                // This is a root comment, so we build its children recursively
                guard var rootComment = commentMap[comment.id] else { continue }
                buildChildren(for: &rootComment)
                result.append(rootComment) // Append the fully built root comment
            }
        }
        
        return result
    }

    private static func flattenComments(_ comments: [IntermediateComment], level: Int = 0) -> [(comment: IntermediateComment, level: Int)] {
        var result: [(IntermediateComment, Int)] = []
        
        for comment in comments {
            result.append((comment, level)) // Add the current comment with its nesting level
            result.append(contentsOf: flattenComments(comment.children, level: level + 1)) // Recursively flatten and add the children with incremented level
        }
        
        return result
    }
}
