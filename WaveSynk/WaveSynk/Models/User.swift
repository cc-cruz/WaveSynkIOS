import Foundation
import SwiftData

@Model
final class User: Codable {
    var id: Int
    var username: String
    var email: String
    var phone: String?
    var notificationsEnabled: Bool
    var createdAt: Date
    var lastLoginAt: Date
    var favoriteSpotIds: [Int]
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var alerts: [Alert]?
    
    init(id: Int,
         username: String,
         email: String,
         phone: String? = nil,
         notificationsEnabled: Bool = true,
         createdAt: Date = Date(),
         lastLoginAt: Date = Date(),
         favoriteSpotIds: [Int] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.phone = phone
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.favoriteSpotIds = favoriteSpotIds
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case phone
        case notificationsEnabled = "notifications_enabled"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
        case favoriteSpotIds = "favorite_spot_ids"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decode(Date.self, forKey: .lastLoginAt)
        favoriteSpotIds = try container.decode([Int].self, forKey: .favoriteSpotIds)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastLoginAt, forKey: .lastLoginAt)
        try container.encode(favoriteSpotIds, forKey: .favoriteSpotIds)
    }
    
    // MARK: - Favorite Spots Management
    
    func toggleFavorite(spotId: Int) {
        if favoriteSpotIds.contains(spotId) {
            favoriteSpotIds.removeAll { $0 == spotId }
        } else {
            favoriteSpotIds.append(spotId)
        }
    }
    
    func isFavorite(spotId: Int) -> Bool {
        favoriteSpotIds.contains(spotId)
    }
} 