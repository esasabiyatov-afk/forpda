//
//  ProfileParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation
import Models

public struct ProfileParser {
    
    /// 0. 69383 - request id
    /// 1. 0 - response status ok
    /// 2. 3640948 - user id
    /// 3. 4spader - nickname
    /// 4. https://4pda.to/static/forum/uploads/48/3640948-28843594.jpg - image url
    /// 5. 3 - group id (beginning)
    /// 6. "" - status
    /// 7. "" - signature
    /// 8. "" - text about me
    /// 9. 1379589700 - registration date
    /// 10. 1722630734 - last seen date (0 if hidden)
    /// 11. "" - date of birth
    /// 12. 0 - gender (0/1/2, unknown/male/female)
    /// 13. 10800 - user time
    /// 14. "Нет" - user city
    /// 15. [] - devices on devdb
    /// 16. 800 - karma amount
    /// 17. 0 - posts amount
    /// 18. 5 - comments amount
    /// 19. 1 - reputation amount
    /// 20. 0 - topics amount
    /// 21. 10 - replies amount
    /// 22. 0 - qms messages
    /// 23. [] - curated topics
    /// 24. [] - warning log
    /// 25. something@gmail.com - email
    /// 26. "" - registrationIP
    /// 27. "" - sessionIP
    /// 28. -1 - warning level (-1 => 0%)
    /// 29. 0 - user premod (1 - always | 0 - before ...)
    /// 30. 0 - user readonly (if != 0 => before ...)
    /// 31. 0 - ban reason (1 - last chanse | 2 - permanent | 3 - security block)
    /// 32. [] - rewards list
    /// 33. "" - previous nicknames
    
    public static func parseUser(from string: String) throws -> User {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                guard let readOnlyUntil = array[safe: 30] as? Int,
                      let premoderationRaw = array[safe: 29] as? Int else {
                    throw ParsingError.failedToCastFields
                }
                let readOnlyDate: Date? = readOnlyUntil != 0 ? Date(timeIntervalSince1970: TimeInterval(readOnlyUntil)) : nil
                let premoderation: User.Premoderation? = switch premoderationRaw {
                case 0: nil
                case 1: .always
                default: .until(Date(timeIntervalSince1970: TimeInterval(premoderationRaw)))
                }
                
                return User(
                    id: array.cast(2, Int.self),
                    nickname: try (array.cast(3, String.self)).convertHtmlCodes(),
                    imageUrl: URL(string: array.cast(4, String.self)),
                    group: (User.Group(rawValue: array.cast(5, Int.self)) ?? .beginning),
                    status: (array[safe: 6] as? String).flatMap { $0.isEmpty ? nil : $0 }?.convertCodes(),
                    signature: (array[safe: 7] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    aboutMe: (array[safe: 8] as? String).flatMap { $0.isEmpty ? nil : $0 }?.convertCodes(),
                    registrationDate: Date(timeIntervalSince1970: array.cast(9, Double.self)),
                    lastSeenDate: Date(timeIntervalSince1970: array.cast(10, Double.self)),
                    birthdate: (array[safe: 11] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    gender: User.Gender(rawValue: array.cast(12, Int.self)),
                    userTime: (array.cast(13, Int.self)),
                    city: (array[safe: 14] as? String).flatMap { ($0.isEmpty || $0 == "Нет") ? nil : $0.convertCodes() },
                    devDBdevices: parseUserDevDBDevices(array.cast(15, [[Any]].self)),
                    karma: ((array.cast(16, Double.self)) / 100).round(to: 2),
                    posts: array.cast(17, Int.self),
                    comments: array.cast(18, Int.self),
                    reputation: array.cast(19, Int.self),
                    topics: array.cast(20, Int.self),
                    replies: array.cast(21, Int.self),
                    qmsMessages: (array.cast(22, Int.self)),
                    curatedTopics: parseCuratedTopics(array.cast(23, [[Any]].self)),
                    warningLogs: parseWarningLogs(array.cast(24, [[Any]].self)),
                    email: (array[safe: 25] as? String).flatMap { $0.isEmpty ? nil : $0 },
                    registrationIP: array.cast(26, String.self),
                    sessionIP: array.cast(27, String.self),
                    warningLevel: array.cast(28, Int.self),
                    premoderation: premoderation,
                    readOnlyUntil: readOnlyDate,
                    banReason: User.BanReason(rawValue: array.cast(31, Int.self)),
                    achievements: parseUserAchievements(array.cast(32, [[Any]].self)),
                    previousNicknames: array.cast(33, String.self)
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseAvatarUrl(from string: String) throws -> UserAvatarResponseType {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                let status = array.cast(1, Int.self)
                
                if status == 0 {
                    let stringUrl = if array.count > 2 { array.cast(2, String.self) } else { "" }
                    return .success(URL(string: stringUrl))
                } else {
                    return .error
                }
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseUserDevDBDevices(_ array: [[Any]]) -> [User.Device] {
        return array.map { device in
            return User.Device(
                id: device.cast(0, String.self),
                name: device.cast(1, String.self),
                main: (device.cast(2, Int.self) == 1) ? true : false
            )
        }
    }
    
    private static func parseUserAchievements(_ array: [[Any]]) -> [User.Achievement] {
        return array.map { achievement in
            return User.Achievement(
                name: achievement.cast(1, String.self),
                description: achievement.cast(2, String.self),
                count: achievement.cast(3, Int.self),
                imageUrl: URL.parsed(achievement.cast(0, String.self)),
                forumUrl: URL.parsed(achievement.cast(5, String.self)),
                presentationDate: Date(
                    timeIntervalSince1970: achievement.cast(4, Double.self)
                )
            )
        }
    }
    
    private static func parseCuratedTopics(_ array: [[Any]]) -> [User.CuratedTopic] {
        return array.map { topic in
            return User.CuratedTopic(id: topic.cast(0, Int.self), name: topic.cast(1, String.self))
        }
    }
    
    private static func parseWarningLogs(_ array: [[Any]]) -> [User.WarningLog] {
        return array.map { warning in
            return User.WarningLog(
                timestamp: warning.cast(0, Int.self),
                level: .init(rawValue: warning.cast(1, Int.self)) ?? .unknown,
                authorId: warning.cast(2, Int.self),
                authorName: warning.cast(3, String.self),
                reason: warning.cast(4, String.self),
                postId: warning.cast(5, Int.self),
                canBeCanceled: ((warning.cast(6, Int.self)) != 0)
            )
        }
    }
}

private extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
