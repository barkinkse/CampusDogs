import MapKit
import SwiftUI

struct CampusMapView: View {
    @State private var dogs: [Dog] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedDogID: UUID?

    init(selectedDogID: UUID? = nil) {
        _selectedDogID = State(initialValue: selectedDogID)
    }

    private var locatedDogs: [Dog] { dogs.filter { $0.coordinate != nil } }

    var body: some View {
        Group {
            if isLoading {
                CampusLoadingView("Son konumlar yükleniyor…")
            } else if let errorMessage {
                ContentUnavailableView("Konumlar yüklenemedi", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
            } else if locatedDogs.isEmpty {
                ContentUnavailableView("Konum bilgisi yok", systemImage: "mappin.slash", description: Text("Aktif köpekler için yayınlanmış gerçek bir son konum bulunmuyor."))
            } else {
                Map(position: $position) {
                    ForEach(locatedDogs) { dog in
                        if let coordinate = dog.coordinate {
                            Annotation(dog.name, coordinate: coordinate, anchor: .bottom) {
                                Button { select(dog) } label: { mapMarker(for: dog) }
                                    .buttonStyle(.plain)
                                    // Only the presentation is offset; stored coordinates are unchanged.
                                    .offset(markerOffset(for: dog))
                                    .accessibilityLabel("\(dog.name) konumunu seç")
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) { dogPicker }
            }
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Harita")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Yenile") { Task { await loadDogs() } }.disabled(isLoading) } }
        .appHomeToolbar()
        .task { await loadDogs() }
    }

    private func mapMarker(for dog: Dog) -> some View {
        let isSelected = dog.id == selectedDogID
        return VStack(spacing: 3) {
            Image(systemName: "pawprint.circle.fill")
                .font(isSelected ? .title : .title2)
                .foregroundStyle(isSelected ? CampusPalette.warning : CampusPalette.primary)
                .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
            Text(dog.name)
                .font(.caption2.weight(isSelected ? .bold : .semibold))
                .lineLimit(1)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.regularMaterial, in: Capsule())
        }
        .scaleEffect(isSelected ? 1.18 : 1)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    private var dogPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(locatedDogs) { dog in
                    Button { select(dog) } label: {
                        HStack(spacing: 9) {
                            DogPhotoView(url: dog.photoURL, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dog.name).font(.subheadline.weight(.bold)).lineLimit(1)
                                Text(dog.locationUpdatedAt.map { turkishDate($0, includeTime: true) } ?? "Son konum")
                                    .font(.caption2).lineLimit(1)
                            }
                        }
                        .foregroundStyle(dog.id == selectedDogID ? CampusPalette.dark : CampusPalette.muted)
                        .padding(8)
                        .background(dog.id == selectedDogID ? CampusPalette.light : Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(dog.id == selectedDogID ? CampusPalette.primary : CampusPalette.border, lineWidth: dog.id == selectedDogID ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(dog.name) konumunu göster")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.thinMaterial)
    }

    private func markerOffset(for dog: Dog) -> CGSize {
        guard let coordinate = dog.coordinate else { return .zero }
        let colocated = locatedDogs.filter {
            guard let candidate = $0.coordinate else { return false }
            return candidate.latitude == coordinate.latitude && candidate.longitude == coordinate.longitude
        }
        guard colocated.count > 1, let index = colocated.firstIndex(where: { $0.id == dog.id }) else { return .zero }
        let angle = (Double(index) / Double(colocated.count) * 2 * Double.pi) - (.pi / 2)
        return CGSize(width: cos(angle) * 25, height: sin(angle) * 25)
    }

    private func select(_ dog: Dog) {
        guard let coordinate = dog.coordinate else { return }
        selectedDogID = dog.id
        position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)))
    }

    private func loadDogs() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        guard let client = SupabaseConfiguration.client else { errorMessage = "Sunucu bağlantısı yapılandırılmadı."; return }
        do {
            dogs = try await SupabaseDogRepository(client: client).activeDogs()
            if let selected = locatedDogs.first(where: { $0.id == selectedDogID }) { select(selected) }
            else if let first = locatedDogs.first { select(first) }
        } catch {
            errorMessage = "Gerçek konum verileri alınamadı. Lütfen tekrar deneyin."
        }
    }
}
