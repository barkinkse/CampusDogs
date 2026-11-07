import SwiftUI

/// Development scanner UI. It presents only the devices emitted by the current scanner run.
struct BluetoothScanView: View {
    @State private var dogs: [Dog] = []
    @State private var detected: [DetectedCollar] = []
    @State private var isLoading = true
    @State private var isScanning = false
    @State private var loadError: String?
    @State private var scanner: MockBluetoothScanner?

    var body: some View {
        Group {
            if isLoading { CampusLoadingView("Köpekler yükleniyor…") }
            else if let loadError { ContentUnavailableView("Köpekler yüklenemedi", systemImage: "wifi.exclamationmark", description: Text(loadError)) }
            else if dogs.isEmpty { ContentUnavailableView("Gösterilecek aktif köpek yok", systemImage: "pawprint", description: Text("Tarama yalnızca etkin köpeklerle eşleşebilir.")) }
            else { ScrollView { VStack(alignment: .leading, spacing: 14) { CampusSurfaceCard { VStack(alignment: .leading, spacing: 8) { Label("Bluetooth taraması", systemImage: "dot.radiowaves.left.and.right").font(.headline).foregroundStyle(CampusPalette.dark); Text("Yalnızca mevcut taramada algılanan cihazla eşleşen köpekler listelenir.").font(.subheadline).foregroundStyle(CampusPalette.muted); CampusPrimaryButton(isScanning ? "Taranıyor…" : "Taramayı Başlat", icon: "dot.radiowaves.left.and.right", isLoading: isScanning) { startScan() }.disabled(isScanning) } }; if detected.isEmpty && !isScanning { ContentUnavailableView("Algılanan cihaz yok", systemImage: "dot.radiowaves.left.and.right", description: Text("Tarama başlattığınızda bu turda algılanan köpekler burada görünür.")) } else { ForEach(detected) { collar in NavigationLink { DogLocationUpdateView(dog: collar.dog) } label: { dogCard(collar.dog) }.buttonStyle(.plain) } } }.padding(20) } }
        }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
        .task { await loadDogs() }
        .onDisappear { scanner?.stopScanning(); scanner?.onDetection = nil }
    }

    private func dogCard(_ dog: Dog) -> some View {
        CampusSurfaceCard { HStack(spacing: 13) { DogPhotoView(url: dog.photoURL, size: 58); VStack(alignment: .leading, spacing: 6) { Text(dog.name).font(.headline).foregroundStyle(CampusPalette.dark); if let date = dog.locationUpdatedAt { Label("Son konum: \(turkishDate(date, includeTime: true))", systemImage: "mappin.and.ellipse").font(.caption).foregroundStyle(CampusPalette.muted) } else { Label("Henüz konum bilgisi yok", systemImage: "mappin.slash").font(.caption).foregroundStyle(CampusPalette.muted) } }; Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(CampusPalette.muted) } }
    }

    private func loadDogs() async { isLoading = true; loadError = nil; defer { isLoading = false }; guard let client = SupabaseConfiguration.client else { loadError = "Sunucu bağlantısı yapılandırılmadı."; return }; do { dogs = try await SupabaseDogRepository(client: client).activeDogs(); scanner = MockBluetoothScanner(scanCandidates: dogs) } catch { loadError = "Aktif köpekler alınamadı. Lütfen tekrar deneyin." } }
    private func startScan() { guard let scanner else { return }; detected = []; isScanning = true; scanner.onDetection = { found in Task { @MainActor in self.detected = found; self.isScanning = false } }; scanner.startScanning() }
}

struct DogLocationUpdateView: View {
    let dog: Dog
    @State private var isUpdating = false
    @State private var success = false
    @State private var error: String?
    private let locationProvider = OneShotLocationProvider()

    var body: some View {
        ScrollView { VStack(spacing: 18) {
            DogPhotoView(url: dog.photoURL, size: 118)
            Text(dog.name).font(.title.bold()).foregroundStyle(CampusPalette.dark)
            if !dog.profileSubtitle.isEmpty { Text(dog.profileSubtitle).font(.subheadline).foregroundStyle(CampusPalette.muted) }
            CampusSurfaceCard { VStack(alignment: .leading, spacing: 8) { CampusSectionTitle("Konum bilgisi"); if let date = dog.locationUpdatedAt { Label("Son güncelleme: \(turkishDate(date, includeTime: true))", systemImage: "clock") .foregroundStyle(CampusPalette.muted) } else { Label("Henüz kaydedilmiş konum yok", systemImage: "mappin.slash").foregroundStyle(CampusPalette.muted) } } }
            CampusSurfaceCard { Label("Bu işlem, yalnızca köpeğin yanındayken telefonunuzun mevcut konumunu haritada günceller. Sürekli takip yapılmaz.", systemImage: "location.fill").font(.subheadline).foregroundStyle(CampusPalette.muted) }
            if success { Label("Konum başarıyla güncellendi. Harita yeni kaydı gösterir.", systemImage: "checkmark.circle.fill").foregroundStyle(CampusPalette.primary).padding(12).frame(maxWidth: .infinity).background(CampusPalette.light, in: RoundedRectangle(cornerRadius: 14)); NavigationLink { DogDetailView(dog: dog, initialSection: .location) } label: { CampusActionLabel(title: "Konumu Görüntüle", icon: "mappin.and.ellipse") }.buttonStyle(.plain) }
            if let error { Text(error).font(.footnote).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading) }
            CampusPrimaryButton(isUpdating ? "Konum alınıyor…" : "Konum Güncellemesini Tamamla", icon: "location.fill", isLoading: isUpdating) { Task { await updateLocation() } }.disabled(isUpdating || success)
        }.padding(20) }
        .background(CampusPalette.background.ignoresSafeArea())
        .navigationTitle("Konum Güncelle")
        .navigationBarTitleDisplayMode(.inline)
        .appHomeToolbar()
    }

    private func updateLocation() async {
        isUpdating = true; error = nil; success = false
        defer { isUpdating = false }
        do {
            let coordinate = try await locationProvider.currentLocation()
            guard let client = SupabaseConfiguration.client else { error = "Sunucu bağlantısı yapılandırılmadı."; return }
            try await SupabaseDogLocationRepository(client: client).updateLocation(for: dog.id, latitude: coordinate.latitude, longitude: coordinate.longitude)
            success = true
        } catch let locationError as LocalizedError {
            self.error = locationError.errorDescription ?? "Konum alınamadı."
        } catch {
            self.error = "Konum kaydedilemedi. İnternet bağlantınızı kontrol edip tekrar deneyin."
        }
    }
}
