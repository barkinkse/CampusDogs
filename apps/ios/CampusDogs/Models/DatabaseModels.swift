import Foundation

struct DatabaseDog: Codable, Identifiable {
    let id: UUID; let name: String; let photoPath: String?; let gender: String?; let estimatedBirthDate: String?
    let description: String?; let publicHealthStatus: DogHealthStatus; let publicCareInfo: String?; let isActive: Bool
    let createdAt: Date; let updatedAt: Date
    enum CodingKeys: String, CodingKey { case id, name, gender, description; case photoPath = "photo_path"; case estimatedBirthDate = "estimated_birth_date"; case publicHealthStatus = "public_health_status"; case publicCareInfo = "public_care_info"; case isActive = "is_active"; case createdAt = "created_at"; case updatedAt = "updated_at" }
}
struct DatabaseLocation: Codable { let dogId: UUID; let latitude: Double; let longitude: Double; let updatedAt: Date
    enum CodingKeys: String, CodingKey { case dogId = "dog_id"; case latitude, longitude; case updatedAt = "updated_at" } }
struct DatabaseCareIcon: Codable, Identifiable { let id: UUID; let name: String; let iconKey: String; let description: String
    enum CodingKeys: String, CodingKey { case id, name, description; case iconKey = "icon_key" } }
struct DatabaseDogCareIcon: Codable { let dogId: UUID; let careIconId: UUID
    enum CodingKeys: String, CodingKey { case dogId = "dog_id"; case careIconId = "care_icon_id" } }
struct DatabaseHealthRecord: Codable, Identifiable {
    let id: UUID; let dogId: UUID; let title: String; let description: String?; let status: DogHealthStatus; let isPublic: Bool; let recordedAt: Date
    enum CodingKeys: String, CodingKey { case id, title, description, status; case dogId = "dog_id"; case isPublic = "is_public"; case recordedAt = "recorded_at" }
}
struct DatabaseAnnouncement: Codable, Identifiable { let id: UUID; let title: String; let body: String; let imagePath: String?; let publishedAt: Date?
    enum CodingKeys: String, CodingKey { case id, title, body; case imagePath = "image_path"; case publishedAt = "published_at" } }
struct MemberReportInsert: Codable { let dogId: UUID; let category: String; let description: String; let severity: String; let imagePath: String?
    enum CodingKeys: String, CodingKey { case dogId = "dog_id"; case category, description, severity; case imagePath = "image_path" } }
