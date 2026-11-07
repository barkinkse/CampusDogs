import Foundation
import CoreLocation

enum DogHealthStatus: String, Codable, CaseIterable { case normal; case underObservation = "under_observation"; case underTreatment = "under_treatment"; case recovering
    var title: String { switch self { case .normal: "Normal"; case .underObservation: "Gözlem Altında"; case .underTreatment: "Tedavi Altında"; case .recovering: "İyileşiyor" } }
}
struct CareIcon: Identifiable, Hashable { let id = UUID(); let symbol: String; let name: String; let explanation: String }
struct Dog: Identifiable, Hashable { let id: UUID; let name: String; let photoURL: URL?; let gender: String; let estimatedAge: String; let description: String; let healthStatus: DogHealthStatus; let publicCareInfo: String; let careIcons: [CareIcon]; let coordinate: CLLocationCoordinate2D?; let locationUpdatedAt: Date?
    static func == (lhs: Dog, rhs: Dog) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    var profileSubtitle: String {
        [gender == "Bilinmiyor" ? nil : gender, estimatedAge == "Yaş bilgisi yok" ? nil : estimatedAge]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
    static let examples: [Dog] = [
        Dog(id: UUID(), name: "Duman", photoURL: nil, gender: "Erkek", estimatedAge: "Yaklaşık 5 yaşında", description: "Kampüsün sakin ve insan canlısı sakini.", healthStatus: .normal, publicCareInfo: "Özel bir bakım gereksinimi bulunmuyor.", careIcons: [], coordinate: .init(latitude: 41.013, longitude: 28.958), locationUpdatedAt: .now),
        Dog(id: UUID(), name: "Tarçın", photoURL: nil, gender: "Dişi", estimatedAge: "Yaklaşık 3 yaşında", description: "Meraklı ve oyunsever bir kampüs köpeği.", healthStatus: .underObservation, publicCareInfo: "Lütfen sakin yaklaşın ve gözlemlenen durumu bildirin.", careIcons: [CareIcon(symbol: "limit_running", name: "Koşmayı Sınırla", explanation: "Eklem, kalp veya solunum hassasiyeti nedeniyle koşmasını teşvik etmeyin."), CareIcon(symbol: "special_diet", name: "Özel Beslenme", explanation: "Veterinerin belirlediği beslenme düzeni var; izinsiz yiyecek vermeyin.")], coordinate: .init(latitude: 41.014, longitude: 28.960), locationUpdatedAt: .now.addingTimeInterval(-3600)),
        Dog(id: UUID(), name: "Boncuk", photoURL: nil, gender: "Erkek", estimatedAge: "Yaklaşık 7 yaşında", description: "Kampüsün tecrübeli sakini.", healthStatus: .recovering, publicCareInfo: "Dinlenmeye ihtiyacı olabilir.", careIcons: [CareIcon(symbol: "recovery", name: "İyileşme Süreci", explanation: "Tedavi süreci devam ediyor.")], coordinate: .init(latitude: 41.011, longitude: 28.957), locationUpdatedAt: .now.addingTimeInterval(-7200))]
}
struct Announcement: Identifiable { let id = UUID(); let title: String; let body: String; let date: String }
