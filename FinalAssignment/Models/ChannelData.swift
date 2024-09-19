//
//  ChannelData.swift
//  LoginModel
//
//  Created by Deep Vora on 09/09/24.
//

import Foundation


//    let id: String
//    let name: String
//    let groupFolderName: String?
    
    
struct ChannelsResponse: Codable {
    let channels: [ChannelData]
}

struct ChannelData: Codable {
    let id: String
    let name: String
    let created: Double
    let creator: String
    let isArchived: Bool
    let isMember: Bool
    let groupEmail: String
    let groupFolderName: String
    let isActive: Bool
    let isAutoFollowed: Bool
    let isNotifications: Bool
    let lastSeen: String
    let latest: Double
    let unreadCount: Int
    let threadUnreadCount: Int
    let members: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case created
        case creator
        case isArchived = "is_archived"
        case isMember = "is_member"
        case groupEmail = "group_email"
        case groupFolderName = "group_folder_name"
        case isActive = "is_active"
        case isAutoFollowed = "is_auto_followed"
        case isNotifications = "is_notifications"
        case lastSeen = "last_seen"
        case latest
        case unreadCount = "unread_count"
        case threadUnreadCount = "thread_unread_count"
        case members
    }
}

   

