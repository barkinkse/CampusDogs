import Foundation
import CoreBluetooth

struct DetectedCollar: Identifiable, Hashable { let id: UUID; let dog: Dog; let signalStrength: Int; let isSimulated: Bool }
protocol BluetoothScanner: AnyObject { var onDetection: (([DetectedCollar]) -> Void)? { get set }; func startScanning(); func stopScanning() }
final class MockBluetoothScanner: BluetoothScanner { var onDetection: (([DetectedCollar]) -> Void)?; private var task: Task<Void, Never>?; private let scanCandidates: [Dog]
    init(scanCandidates: [Dog] = Dog.examples) { self.scanCandidates = scanCandidates }
    func startScanning() { task?.cancel(); task = Task { @MainActor in try? await Task.sleep(for: .milliseconds(700)); guard !Task.isCancelled else { return }; onDetection?(scanCandidates.prefix(2).enumerated().map { DetectedCollar(id: $0.element.id, dog: $0.element, signalStrength: -48 - $0.offset * 12, isSimulated: true) }) } }
    func stopScanning() { task?.cancel() }
}
// Intentionally not active until the selected collar protocol specifies its advertised identifier.
final class CoreBluetoothScanner: NSObject, BluetoothScanner { var onDetection: (([DetectedCollar]) -> Void)?; func startScanning() {} ; func stopScanning() {} }
