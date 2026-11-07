import Foundation
import Supabase

enum RepositoryError: LocalizedError { case configurationMissing; case invalidResponse
    var errorDescription: String? { switch self { case .configurationMissing: "Sunucu bağlantısı yapılandırılmadı."; case .invalidResponse: "Sunucudan geçerli veri alınamadı." } }
}
protocol DogRepository { func activeDogs() async throws -> [Dog] }
protocol HealthRecordRepository { func publicHealthRecords(for dogID: UUID) async throws -> [DatabaseHealthRecord] }
protocol AnnouncementRepository { func publishedAnnouncements() async throws -> [DatabaseAnnouncement] }
protocol MemberReportRepository { func submit(_ report: MemberReportInsert) async throws }
protocol DogLocationRepository { func updateLocation(for dogID: UUID, latitude: Double, longitude: Double) async throws }

private struct SubmitDogLocationParameters: Encodable {
    let targetDogID: UUID
    let inputLatitude: Double
    let inputLongitude: Double
    enum CodingKeys: String, CodingKey { case targetDogID = "target_dog_id"; case inputLatitude = "input_latitude"; case inputLongitude = "input_longitude" }
}


final class SupabaseDogRepository: DogRepository {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func activeDogs() async throws -> [Dog] {
        let dogs: [DatabaseDog] = try await client.from("dogs").select().eq("is_active", value: true).order("name").execute().value
        let assignments: [DatabaseDogCareIcon] = try await client.from("dog_care_icons").select().execute().value
        let icons: [DatabaseCareIcon] = try await client.from("care_icons").select().execute().value
        let locations: [DatabaseLocation] = try await client.from("dog_locations").select().execute().value
        return dogs.map { item in
            let iconIDs = Set(assignments.filter { $0.dogId == item.id }.map(\.careIconId))
            let care = icons.filter { iconIDs.contains($0.id) }.map { CareIcon(symbol: $0.iconKey, name: $0.name, explanation: $0.description) }
            let location = locations.first { $0.dogId == item.id }
            let photoURL: URL?
            if let path = item.photoPath {
                photoURL = path.hasPrefix("http") ? URL(string: path) : try? client.storage.from("dog-images").getPublicURL(path: path)
            } else { photoURL = nil }
            return Dog(id: item.id, name: item.name, photoURL: photoURL, gender: item.gender == "female" ? "Dişi" : item.gender == "male" ? "Erkek" : "Bilinmiyor", estimatedAge: item.estimatedBirthDate.map { "Doğum tarihi: \($0)" } ?? "Yaş bilgisi yok", description: item.description ?? "Açıklama bilgisi yok.", healthStatus: item.publicHealthStatus, publicCareInfo: item.publicCareInfo ?? "Özel bakım bilgisi yok.", careIcons: care, coordinate: location.map { .init(latitude: $0.latitude, longitude: $0.longitude) }, locationUpdatedAt: location?.updatedAt)
        }
    }
}
final class SupabaseHealthRecordRepository: HealthRecordRepository {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func publicHealthRecords(for dogID: UUID) async throws -> [DatabaseHealthRecord] {
        try await client.from("health_records").select().eq("dog_id", value: dogID.uuidString).eq("is_public", value: true).order("recorded_at", ascending: false).execute().value
    }
}
final class SupabaseAnnouncementRepository: AnnouncementRepository {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func publishedAnnouncements() async throws -> [DatabaseAnnouncement] { try await client.from("announcements").select().eq("is_published", value: true).order("published_at", ascending: false).execute().value }
}
final class SupabaseMemberReportRepository: MemberReportRepository {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func submit(_ report: MemberReportInsert) async throws { try await client.from("member_reports").insert(report).execute() }
}
final class SupabaseDogLocationRepository: DogLocationRepository {
    private let client: SupabaseClient
    init(client: SupabaseClient) { self.client = client }
    func updateLocation(for dogID: UUID, latitude: Double, longitude: Double) async throws {
        try await client.rpc("submit_dog_location", params: SubmitDogLocationParameters(targetDogID: dogID, inputLatitude: latitude, inputLongitude: longitude)).execute()
    }
    func publicLocation(for dogID: UUID) async throws -> DatabaseLocation? {
        try await client.from("dog_locations").select().eq("dog_id", value: dogID.uuidString).maybeSingle().execute().value
    }
}
