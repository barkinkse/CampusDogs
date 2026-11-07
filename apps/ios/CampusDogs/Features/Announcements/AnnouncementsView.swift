import SwiftUI

struct AnnouncementsView: View {
    @State private var announcements: [DatabaseAnnouncement] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        Group {
            if loading { CampusLoadingView("Duyurular yükleniyor…") }
            else if let error { VStack(spacing: 14) { ContentUnavailableView("Duyurular yüklenemedi", systemImage: "wifi.exclamationmark", description: Text(error)); Button("Tekrar dene") { Task { await fetch() } }.buttonStyle(.borderedProminent).tint(CampusPalette.primary) } }
            else if announcements.isEmpty { ContentUnavailableView("Yayınlanmış duyuru yok", systemImage: "megaphone", description: Text("Yeni duyurular burada görünür.")) }
            else { ScrollView { LazyVStack(spacing: 12) { ForEach(announcements) { item in NavigationLink { AnnouncementDetailView(item: item) } label: { AnnouncementCard(item: item) }.buttonStyle(.plain) } }.padding(20) }.refreshable { await fetch() } }
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Duyurular")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
        .task { await fetch() }
    }
    private func fetch() async { loading = true; error = nil; defer { loading = false }; guard let client = SupabaseConfiguration.client else { error = "Sunucu bağlantısı yapılandırılmadı."; return }; do { announcements = try await SupabaseAnnouncementRepository(client: client).publishedAnnouncements() } catch { self.error = "Yayınlanmış duyurular alınamadı." } }
}

private struct AnnouncementCard: View {
    let item: DatabaseAnnouncement
    var body: some View { CampusSurfaceCard { HStack(spacing: 13) { Image(systemName: "megaphone.fill").font(.title3).foregroundStyle(CampusPalette.primary).frame(width: 45, height: 45).background(CampusPalette.light, in: RoundedRectangle(cornerRadius: 13)); VStack(alignment: .leading, spacing: 5) { Text(item.title).font(.headline).foregroundStyle(CampusPalette.dark); Text(item.publishedAt.map { turkishDate($0) } ?? "Yayın tarihi belirtilmedi").font(.caption).foregroundStyle(CampusPalette.muted) }; Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(CampusPalette.muted) } } }
}

private struct AnnouncementDetailView: View {
    let item: DatabaseAnnouncement
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 16) { Image(systemName: "megaphone.fill").font(.title).foregroundStyle(CampusPalette.primary).frame(width: 62, height: 62).background(CampusPalette.light, in: RoundedRectangle(cornerRadius: 18)); Text(item.title).font(.title.bold()).foregroundStyle(CampusPalette.dark); Text(item.publishedAt.map { turkishDate($0) } ?? "Yayın tarihi belirtilmedi").font(.subheadline.weight(.bold)).foregroundStyle(CampusPalette.primary); CampusSurfaceCard { Text(item.body).font(.body).foregroundStyle(CampusPalette.dark).lineSpacing(5) } }.padding(20) }.background(CampusPalette.background.ignoresSafeArea()).navigationTitle("Duyuru Detayı").navigationBarTitleDisplayMode(.inline).appHomeToolbar() }
}
