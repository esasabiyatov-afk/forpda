//
//  QMSListParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import Models

public struct QMSUserParser {
    public static func parse(from string: String) throws -> QMSUser {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                let user = array.cast(2, [[Any]].self).first ?? []
                return QMSUser(
                    userId: user.cast(0, Int.self),
                    name: user.cast(1, String.self),
                    flag: user.cast(2, Int.self),
                    avatarUrl: URL(string: user.cast(3, String.self)),
                    lastSeenOnline: Date(timeIntervalSince1970: user.cast(4, Double.self)),
                    lastMessageDate: Date(timeIntervalSince1970: user.cast(5, Double.self)),
                    unreadCount: user.cast(6, Int.self),
                    chats: QMSListParser.parseChats(user.cast(7, [[Any]].self))
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
}

public struct QMSListParser {
    public static func parse(from string: String) throws -> QMSList {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return QMSList(users: parseUsers(array.cast(2, [[Any]].self)))
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseUsers(_ array: [[Any]]) -> [QMSUser] {
        return array.map { user in
            return QMSUser(
                userId: user.cast(0, Int.self),
                name: (user.cast(1, String.self)).convertCodes(),
                flag: user.cast(2, Int.self),
                avatarUrl: URL(string: user.cast(3, String.self)),
                lastSeenOnline: Date(timeIntervalSince1970: user.cast(4, Double.self)),
                lastMessageDate: Date(timeIntervalSince1970: user.cast(5, Double.self)),
                unreadCount: user.cast(6, Int.self),
                chats: parseChats(user.cast(7, [[Any]].self))
            )
        }
    }
    
    public static func parseChats(_ array: [[Any]]) -> [QMSChatInfo] {
        return array.map { chat in
            return QMSChatInfo(
                id: chat.cast(0, Int.self),
                creationDate: Date(timeIntervalSince1970: chat.cast(1, Double.self)),
                lastMessageDate: Date(timeIntervalSince1970: chat.cast(2, Double.self)),
                name: chat.cast(3, String.self),
                totalCount: chat.cast(4, Int.self),
                unreadCount: chat.cast(5, Int.self),
                lastMessageId: chat.cast(6, Int.self)
            )
        }
    }
}
