//
//  ForumParser.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation
import Models

public struct ForumParser {
    public static func parse(from string: String) throws -> Forum {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return Forum(
                    id: array.cast(3, Int.self),
                    name: array.cast(4, String.self),
                    flag: ForumFlag(rawValue: array.cast(5, Int.self)),
                    globalAnnouncement: array.cast(6, String.self),
                    announcements: parseAnnouncementInfo(array.cast(7, [[Any]].self)),
                    subforums: parseForumInfo(array.cast(8, [[Any]].self)),
                    topicsCount: array.cast(9, Int.self),
                    topics: parseTopic(array.cast(10, [[Any]].self)),
                    navigation: parseNavigation(array.cast(2, [[Any]].self))
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseForumList(from string: String) throws -> [ForumInfo] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return parseForumInfo(array.cast(2, [[Any]].self))
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseForumStat(from string: String) throws -> ForumStat {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                if array.count == 2 {
                    throw ParsingError.failedToFindPost
                }
                
                return ForumStat(
                    id: array.cast(3, Int.self),
                    name: array.cast(4, String.self),
                    description: array.cast(5, String.self),
                    flag: ForumFlag(rawValue: array.cast(6, Int.self)),
                    globalAnnouncement: array.cast(7, String.self),
                    subforumsCount: array.cast(8, Int.self),
                    topicsCount: array.cast(9, Int.self),
                    postsCount: array.cast(10, Int.self),
                    moderators: parseForumStatModerators(array.cast(11, [[Any]].self))
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseForumEventLog(from string: String) throws -> [ForumEventLog] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return (array.cast(2, [[Any]].self)).map { event in
                    return ForumEventLog(
                        userId: event.cast(1, Int.self),
                        userName: (event.cast(2, String.self)).convertCodes(),
                        userGroup: (User.Group(rawValue: event.cast(3, Int.self)) ?? .beginning),
                        content: event.cast(4, String.self),
                        createdAt: Date(timeIntervalSince1970: TimeInterval(event.cast(0, Int.self)))
                    )
                }
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    internal static func parseForumStatModerators(_ array: [[Any]]) -> [ForumStat.ForumModerator] {
        return array.map { moderator in
            return ForumStat.ForumModerator(
                id: moderator.cast(0, Int.self),
                name: (moderator.cast(1, String.self)).convertCodes(),
                group: (User.Group(rawValue: moderator.cast(2, Int.self)) ?? .beginning)
            )
        }
    }
    
    public static func parseForumJump(from string: String) throws -> ForumJump {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                if array.count == 2 {
                    throw ParsingError.failedToFindPost
                }
                
                return ForumJump(
                    id: array.cast(2, Int.self),
                    offset: array.cast(3, Int.self),
                    postId: array.cast(4, Int.self),
                    postsFilter: (TopicPostsFilter(rawValue: array.cast(5, Int.self)) ?? .all)
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseAnnouncement(from string: String) throws -> Announcement {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return Announcement(
                    name: (array.cast(2, String.self)).convertCodes(),
                    content: array.cast(3, String.self)
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    internal static func parseNavigation(_ array: [[Any]]) -> [ForumInfo] {
        return array.map { navigation in
            return ForumInfo(
                id: navigation.cast(1, Int.self),
                name: navigation.cast(2, String.self),
                flag: ForumFlag(rawValue: navigation.cast(0, Int.self))
            )
        }
    }
    
    private static func parseAnnouncementInfo(_ array: [[Any]]) -> [AnnouncementInfo] {
        return array.map { announcement in
            return AnnouncementInfo(
                id: announcement.cast(0, Int.self),
                name: (announcement.cast(1, String.self)).convertCodes()
            )
        }
    }
    
    private static func parseForumInfo(_ array: [[Any]]) -> [ForumInfo] {
        return array.map { forum in
            let redirectUrl = forum.count > 3 ? URL(string: forum.cast(3, String.self)) : nil
            
            return ForumInfo(
                id: forum.cast(0, Int.self),
                name: (forum.cast(1, String.self)).convertCodes(),
                flag: ForumFlag(rawValue: forum.cast(2, Int.self)),
                redirectUrl: redirectUrl
            )
        }
    }
    
    private static func parseTopic(_ array: [[Any]]) -> [TopicInfo] {
        return array.map { topic in
            return parseTopic(topic)
        }
    }
        
    internal static func parseTopic(_ topic: [Any]) -> TopicInfo {
        return TopicInfo(
            id: topic.cast(0, Int.self),
            name: (topic.cast(1, String.self)).convertCodes(),
            description: (topic.cast(2, String.self)).convertCodes(),
            flag: ForumFlag(rawValue: topic.cast(3, Int.self)),
            postsCount: topic.cast(4, Int.self),
            lastPost: TopicInfo.LastPost(
                date: Date(timeIntervalSince1970: topic.cast(5, Double.self)),
                userId: topic.cast(6, Int.self),
                username: (topic.cast(7, String.self)).convertCodes()
            )
        )
    }
}
