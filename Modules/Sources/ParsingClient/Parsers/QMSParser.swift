//
//  QMSParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import Models

public struct QMSChatParser {
    public static func parse(from string: String) throws -> QMSChat {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return QMSChat(
                    id: array.cast(2, Int.self),
                    creationDate: Date(timeIntervalSince1970: array.cast(3, Double.self)),
                    lastMessageDate: Date(timeIntervalSince1970: array.cast(4, Double.self)),
                    name: array.cast(5, String.self),
                    partnerId: array.cast(6, Int.self),
                    partnerName: array.cast(7, String.self),
                    flag: array.cast(8, Int.self),
                    avatarUrl: URL(string: array.cast(9, String.self)),
                    unknownId1: array.cast(10, Int.self),
                    totalCount: array.cast(11, Int.self),
                    unknownId2: array.cast(12, Int.self),
                    lastMessageId: array.cast(13, Int.self),
                    unreadCount: array.cast(14, Int.self),
                    messages: parseMessages(array.cast(15, [[Any]].self))
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseMessages(_ array: [[Any]]) -> [QMSMessage] {
        return array.map { message in
            return QMSMessage(
                id: message.cast(0, Int.self),
                senderId: message.cast(1, Int.self),
                date: Date(timeIntervalSince1970: message.cast(2, Double.self)),
                text: message.cast(3, String.self),
                attachments: (try? AttachmentParser.parseAttachment(message.cast(4, [[Any]].self))) ?? []
            )
        }
    }
}
