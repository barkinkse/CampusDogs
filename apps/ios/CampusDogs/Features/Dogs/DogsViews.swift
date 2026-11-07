import MapKit
import SwiftUI

struct DogsView: View {
    @State private var dogs: [Dog] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading { CampusLoadingView("Köpekler yükleniyor…") }
            else if let error { retryState(title: "Köpekler yüklenemedi", message: error) }
            else if dogs.isEmpty { ContentUnavailableView("Kayıtlı köpek yok", systemImage: "pawprint", description: Text("Aktif köpek eklendiğinde burada görünür.")) }
            else { ScrollView { LazyVStack(spacing: 12) { ForEach(dogs) { dog in NavigationLink { DogDetailView(dog: dog) } label: { DogCard(dog: dog) }.buttonStyle(.plain) } }.padding(20) }.refreshable { await fetch() } }
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Köpekler")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
        .task { await fetch() }
    }

    private func retryState(title: String, message: String) -> some View {
        VStack(spacing: 14) { ContentUnavailableView(title, systemImage: "wifi.exclamationmark", description: Text(message)); Button("Tekrar dene") { Task { await fetch() } }.buttonStyle(.borderedProminent).tint(CampusPalette.primary) }
    }

    private func fetch() async {
        isLoading = true; error = nil; defer { isLoading = false }
        guard let client = SupabaseConfiguration.client else { error = "Sunucu bağlantısı yapılandırılmadı."; return }
        do { dogs = try await SupabaseDogRepository(client: client).activeDogs() }
        catch { self.error = "Köpek bilgileri alınamadı. Lütfen tekrar deneyin." }
    }
}

struct DogPhotoView: View {
    let url: URL?
    let size: CGFloat
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    case .empty: ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    default: fallback
                    }
                }
            } else { fallback }
        }
        .frame(width: size, height: size)
        .background(CampusPalette.light, in: Circle())
        .clipShape(Circle())
        .overlay(Circle().stroke(CampusPalette.border, lineWidth: 1))
        .accessibilityLabel("Köpek fotoğrafı")
    }
    private var fallback: some View { Image(systemName: "pawprint.fill").resizable().scaledToFit().padding(size * 0.27).foregroundStyle(CampusPalette.primary.opacity(0.78)) }
}

struct DogCard: View {
    let dog: Dog
    var body: some View {
        CampusSurfaceCard {
            HStack(spacing: 14) {
                DogPhotoView(url: dog.photoURL, size: 66)
                VStack(alignment: .leading, spacing: 7) {
                    Text(dog.name).font(.headline).foregroundStyle(CampusPalette.dark)
                    if !dog.profileSubtitle.isEmpty { Text(dog.profileSubtitle).font(.subheadline).foregroundStyle(CampusPalette.muted).lineLimit(2) }
                    CampusHealthBadge(status: dog.healthStatus)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.subheadline.weight(.bold)).foregroundStyle(CampusPalette.muted)
            }
        }
    }
}

struct DogDetailView: View {
    enum ProfileSection: String, CaseIterable { case information = "Bilgiler", health = "Sağlık Geçmişi", location = "Konum" }
    let dog: Dog
    @State private var section: ProfileSection
    @State private var selectedIcon: CareIcon?

    init(dog: Dog, initialSection: ProfileSection = .information) {
        self.dog = dog
        _section = State(initialValue: initialSection)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                profileHeader
                prominentWarning
                profileTabs
                switch section {
                case .information: information
                case .health: HealthHistorySection(dog: dog)
                case .location: ProfileLocationSection(dog: dog)
                }
            }.padding(20)
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Köpek Profili")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
        .sheet(item: $selectedIcon) { icon in CareIconDetailView(icon: icon) }
    }

    private var profileHeader: some View {
        VStack(spacing: 10) {
            DogPhotoView(url: dog.photoURL, size: 154)
            Text(dog.name).font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(CampusPalette.dark)
            ProfileAgeMetadataView(dog: dog)
            CampusHealthBadge(status: dog.healthStatus)
        }.frame(maxWidth: .infinity)
    }

    private var profileTabs: some View {
        HStack(spacing: 0) { ForEach(ProfileSection.allCases, id: \.self) { item in Button { withAnimation(.easeInOut) { section = item } } label: { Text(item.rawValue).font(.caption.weight(.bold)).foregroundStyle(section == item ? CampusPalette.dark : CampusPalette.muted).frame(maxWidth: .infinity).padding(.vertical, 12).overlay(alignment: .bottom) { Capsule().fill(section == item ? CampusPalette.primary : .clear).frame(height: 3) } }.buttonStyle(.plain) } }.background(CampusPalette.cream, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var information: some View {
        VStack(spacing: 14) {
            if !dog.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { CampusSurfaceCard { VStack(alignment: .leading, spacing: 7) { CampusSectionTitle("Profil bilgisi"); Text(dog.description).foregroundStyle(CampusPalette.muted) } } }
            careIcons
            NavigationLink { HealthReportView(preselectedDog: dog) } label: { CampusActionLabel(title: "Gözlem Bildir", icon: "square.and.pencil") }.buttonStyle(.plain)
        }
    }

    @ViewBuilder private var prominentWarning: some View {
        if dog.healthStatus != .normal || !dog.careIcons.isEmpty || dog.publicCareInfo != "Özel bakım bilgisi yok." {
            CampusSurfaceCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: dog.healthStatus == .normal ? "info.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title2).foregroundStyle(dog.healthStatus == .normal ? CampusPalette.primary : CampusPalette.warning)
                        .frame(width: 42, height: 42)
                        .background((dog.healthStatus == .normal ? CampusPalette.light : CampusPalette.warning.opacity(0.13)), in: RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Yaklaşım ve bakım bilgileri").font(.headline).foregroundStyle(CampusPalette.dark)
                        Text(dog.publicCareInfo).font(.subheadline).foregroundStyle(CampusPalette.muted)
                        NavigationLink { ApproachWarningView(dog: dog) } label: { Text("Ayrıntıyı incele →").font(.subheadline.weight(.bold)).foregroundStyle(CampusPalette.warning) }
                    }
                }
            }
        }
    }

    @ViewBuilder private var careIcons: some View {
        if !dog.careIcons.isEmpty {
            CampusSurfaceCard { VStack(alignment: .leading, spacing: 13) { CampusSectionTitle("Bakım uyarıları", subtitle: "Simgelere dokunarak ayrıntıyı okuyun."); LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) { ForEach(dog.careIcons) { icon in Button { selectedIcon = icon } label: { HStack(spacing: 10) { Image(careIconAsset(icon.symbol)).resizable().scaledToFit().frame(width: 24, height: 24).frame(width: 38, height: 38).background(CampusPalette.light, in: RoundedRectangle(cornerRadius: 11)); Text(icon.name).font(.subheadline.weight(.semibold)).foregroundStyle(CampusPalette.dark).multilineTextAlignment(.leading); Spacer(minLength: 0) }.padding(10).frame(maxWidth: .infinity, alignment: .leading).background(CampusPalette.background, in: RoundedRectangle(cornerRadius: 14)) }.buttonStyle(.plain) } } } }
        }
    }

}

private struct ProfileAgeMetadataView: View {
    let dog: Dog

    var body: some View {
        TimelineView(.periodic(from: .now, by: 86_400)) { context in
            let age = dogAge(from: dog.estimatedAge, asOf: context.date)
            let details = [
                dog.gender == "Bilinmiyor" ? nil : dog.gender,
                age.map { "Yaş: \($0)" }
            ].compactMap { $0 }

            if !details.isEmpty {
                Text(details.joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(CampusPalette.muted)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private func dogAge(from storedValue: String, asOf date: Date) -> String? {
    let prefix = "Doğum tarihi: "
    guard storedValue.hasPrefix(prefix) else { return nil }

    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    guard let birthDate = formatter.date(from: String(storedValue.dropFirst(prefix.count))), birthDate <= date else { return nil }

    let components = Calendar.current.dateComponents([.year, .month], from: birthDate, to: date)
    let years = max(components.year ?? 0, 0)
    let months = max(components.month ?? 0, 0)
    if years == 0 { return "\(months) aylık" }
    if months == 0 { return "\(years) yaş" }
    return "\(years) yaş \(months) ay"
}

private struct ProfileLocationSection: View {
    let dog: Dog
    @State private var location: DatabaseLocation?
    @State private var isLoading = true
    @State private var error: String?
    var body: some View { VStack(spacing: 14) { CampusSurfaceCard { VStack(alignment: .leading, spacing: 10) { if isLoading { ProgressView("Konum yükleniyor…") } else if let error { Label(error, systemImage: "wifi.exclamationmark").foregroundStyle(CampusPalette.muted) } else if let location { let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude); Label("Son kaydedilen konum", systemImage: "mappin.and.ellipse").font(.headline).foregroundStyle(CampusPalette.dark); Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))) { Annotation(dog.name, coordinate: coordinate) { Image(systemName: "pawprint.circle.fill").font(.title).foregroundStyle(CampusPalette.primary) } }.frame(height: 170).clipShape(RoundedRectangle(cornerRadius: 15)); Text("Son görülme: \(turkishDate(location.updatedAt, includeTime: true))").font(.subheadline).foregroundStyle(CampusPalette.muted) } else { Label("Bu köpek için yayınlanmış bir son konum yok.", systemImage: "mappin.slash").foregroundStyle(CampusPalette.muted) }; Text("Konum, son kaydedilen noktayı gösterir; canlı takip değildir.").font(.caption).foregroundStyle(CampusPalette.muted) } }; NavigationLink { CampusMapView(selectedDogID: dog.id) } label: { CampusActionLabel(title: "Haritada Görüntüle", icon: "map") }.buttonStyle(.plain) }.task(id: dog.id) { await load() } }
    private func load() async { isLoading = true; error = nil; defer { isLoading = false }; guard let client = SupabaseConfiguration.client else { error = "Sunucu bağlantısı yapılandırılmadı."; return }; do { location = try await SupabaseDogLocationRepository(client: client).publicLocation(for: dog.id) } catch { self.error = "Konum bilgisi alınamadı." } }
}

private struct CareIconDetailView: View {
    let icon: CareIcon
    @Environment(\.dismiss) private var dismiss
    var body: some View { VStack(spacing: 18) { Image(careIconAsset(icon.symbol)).resizable().scaledToFit().frame(width: 44, height: 44).frame(width: 84, height: 84).background(CampusPalette.light, in: Circle()); Text(icon.name).font(.title2.bold()); Text(icon.explanation).multilineTextAlignment(.center).foregroundStyle(CampusPalette.muted); CampusPrimaryButton("Kapat") { dismiss() } }.padding(26).presentationDetents([.medium]) }
}

struct ApproachWarningView: View {
    let dog: Dog
    var body: some View { ScrollView { VStack(spacing: 20) { Image(systemName: dog.healthStatus == .normal ? "heart.circle.fill" : "exclamationmark.triangle.fill").font(.system(size: 62)).foregroundStyle(dog.healthStatus == .normal ? CampusPalette.primary : CampusPalette.warning).frame(width: 124, height: 124).background((dog.healthStatus == .normal ? CampusPalette.light : CampusPalette.warning.opacity(0.13)), in: Circle()); Text(dog.healthStatus.title).font(.title.bold()).foregroundStyle(CampusPalette.dark); CampusSurfaceCard { VStack(alignment: .leading, spacing: 8) { CampusSectionTitle("Yaklaşım bilgisi"); Text(dog.publicCareInfo).foregroundStyle(CampusPalette.dark) } }; if !dog.careIcons.isEmpty { CampusSurfaceCard { VStack(alignment: .leading, spacing: 9) { CampusSectionTitle("İlgili bakım uyarıları"); ForEach(dog.careIcons) { icon in HStack(spacing: 8) { Image(careIconAsset(icon.symbol)).resizable().scaledToFit().frame(width: 20, height: 20); Text(icon.name) }.foregroundStyle(CampusPalette.dark) } } } } }.padding(24) }.background(CampusPalette.background.ignoresSafeArea()).navigationTitle("Yaklaşım Uyarısı").navigationBarTitleDisplayMode(.inline).appHomeToolbar() }
}

private struct HealthHistorySection: View {
    let dog: Dog
    @State private var records: [DatabaseHealthRecord] = []
    @State private var isLoading = true
    @State private var error: String?
    var body: some View { VStack(alignment: .leading, spacing: 14) { CampusSurfaceCard { HStack { Image(systemName: healthStatusSymbol(dog.healthStatus)).foregroundStyle(healthStatusColor(dog.healthStatus)).font(.title2); VStack(alignment: .leading) { Text("Güncel sağlık durumu").font(.caption).foregroundStyle(CampusPalette.muted); CampusHealthBadge(status: dog.healthStatus) } } }; if isLoading { ProgressView("Sağlık geçmişi yükleniyor…").frame(maxWidth: .infinity).padding() } else if let error { CampusSurfaceCard { VStack(alignment: .leading, spacing: 10) { Text("Sağlık geçmişi yüklenemedi").font(.headline); Text(error).foregroundStyle(CampusPalette.muted); Button("Tekrar dene") { Task { await loadRecords() } }.foregroundStyle(CampusPalette.primary) } } } else if records.isEmpty { CampusSurfaceCard { Label("Henüz paylaşılmış sağlık kaydı bulunmuyor.", systemImage: "heart.text.square").foregroundStyle(CampusPalette.muted) } } else { VStack(spacing: 0) { ForEach(records) { record in NavigationLink { HealthRecordDetailView(record: record) } label: { HealthHistoryRow(record: record) }.buttonStyle(.plain) } } } }.task(id: dog.id) { await loadRecords() } }
    private func loadRecords() async { isLoading = true; error = nil; defer { isLoading = false }; guard let client = SupabaseConfiguration.client else { error = "Sunucu bağlantısı yapılandırılmadı."; return }; do { records = try await SupabaseHealthRecordRepository(client: client).publicHealthRecords(for: dog.id) } catch { self.error = "Paylaşılmış sağlık kayıtları alınamadı." } }
}

private struct HealthHistoryRow: View {
    let record: DatabaseHealthRecord
    var body: some View { HStack(alignment: .top, spacing: 14) { VStack(spacing: 0) { Circle().fill(healthStatusColor(record.status)).frame(width: 14, height: 14).overlay(Circle().stroke(CampusPalette.cream, lineWidth: 3)); Rectangle().fill(CampusPalette.border).frame(width: 2).frame(maxHeight: .infinity) }.frame(width: 16); VStack(alignment: .leading, spacing: 6) { Text(turkishDate(record.recordedAt)).font(.caption.weight(.bold)).foregroundStyle(CampusPalette.primary); Text(record.title).font(.headline).foregroundStyle(CampusPalette.dark); if let description = record.description, !description.isEmpty { Text(description).font(.subheadline).foregroundStyle(CampusPalette.muted).lineLimit(2) }; CampusHealthBadge(status: record.status) }.frame(maxWidth: .infinity, alignment: .leading); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(CampusPalette.muted) }.padding(.vertical, 12) }
}

private struct HealthRecordDetailView: View {
    let record: DatabaseHealthRecord
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Text(turkishDate(record.recordedAt, includeTime: true)).font(.subheadline.weight(.bold)).foregroundStyle(CampusPalette.primary); Text(record.title).font(.title.bold()).foregroundStyle(CampusPalette.dark); CampusHealthBadge(status: record.status); CampusSurfaceCard { VStack(alignment: .leading, spacing: 8) { CampusSectionTitle("Açıklama"); Text(record.description?.isEmpty == false ? record.description! : "Bu kayıt için açıklama paylaşılmadı.").foregroundStyle(CampusPalette.dark) } } }.padding(20) }.background(CampusPalette.background.ignoresSafeArea()).navigationTitle("Kayıt Detayı").navigationBarTitleDisplayMode(.inline).appHomeToolbar() }
}
