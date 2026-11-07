import SwiftUI

@MainActor
final class BluetoothViewModel: ObservableObject {
    @Published private(set) var detected: [DetectedCollar] = []
    @Published var selectedDog: Dog?
    @Published private(set) var message = "Yakındaki tasmalar aranıyor…"

    private let scanner: BluetoothScanner
    private let locationService: LocationService

    init(scanner: BluetoothScanner = MockBluetoothScanner(), locationService: LocationService = MockLocationService()) {
        self.scanner = scanner
        self.locationService = locationService
    }

    func startScanning() {
        scanner.onDetection = { [weak self] found in
            Task { @MainActor in
                self?.detected = found
                self?.message = found.isEmpty ? "Yakında kayıtlı tasma bulunamadı." : "\(found.count) simüle edilmiş tasma bulundu."
            }
        }
        scanner.startScanning()
    }

    func stopScanning() { scanner.stopScanning(); scanner.onDetection = nil }

    func select(_ dog: Dog) {
        Task {
            do {
                _ = try await locationService.currentLocation()
                message = "Geliştirme simülasyonu: \(dog.name) için gerçek GPS kullanılmadan örnek konum güncellemesi yapıldı."
                selectedDog = dog
            } catch {
                message = "Örnek konum üretilemedi."
            }
        }
    }
}

struct BluetoothView: View {
    @StateObject private var viewModel = BluetoothViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Geliştirme simülasyonu • Gerçek BLE/GPS kullanılmaz", systemImage: "info.circle").foregroundStyle(.orange)
                    Text(viewModel.message).font(.subheadline)
                } header: { Text("Bluetooth taraması") }
                ForEach(viewModel.detected) { collar in
                    Button { viewModel.select(collar.dog) } label: {
                        HStack { Image(systemName: "dot.radiowaves.left.and.right").foregroundStyle(.green); VStack(alignment: .leading) { Text(collar.dog.name); Text("Simüle edilmiş sonuç • Sinyal \(collar.signalStrength) dBm").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
                    }
                }
            }
            .navigationTitle("Bluetooth")
            .task { viewModel.startScanning() }
            .onDisappear { viewModel.stopScanning() }
            .navigationDestination(item: $viewModel.selectedDog) { DogDetailView(dog: $0) }
        }
    }
}
