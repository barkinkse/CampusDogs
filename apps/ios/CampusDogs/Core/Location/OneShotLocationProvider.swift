@preconcurrency import CoreLocation

enum OneShotLocationError: LocalizedError {
    case servicesDisabled, permissionDenied, unavailable
    var errorDescription: String? {
        switch self {
        case .servicesDisabled: "Konum servisleri kapalı. Ayarlardan konum servislerini açın."
        case .permissionDenied: "Konum izni verilmedi. Köpeğin konumu güncellenemedi."
        case .unavailable: "Geçerli konum alınamadı. Açık alanda tekrar deneyin."
        }
    }
}

@MainActor
final class OneShotLocationProvider: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyBest }

    func currentLocation() async throws -> CLLocationCoordinate2D {
        let servicesEnabled = CLLocationManager.locationServicesEnabled()
        print("[CampusDogsLocation] currentLocation started; servicesEnabled=\(servicesEnabled), authorizationStatus=\(authorizationDescription(manager.authorizationStatus))")
        guard servicesEnabled else {
            print("[CampusDogsLocation] location request failed before CoreLocation request: services disabled")
            throw OneShotLocationError.servicesDisabled
        }
        switch manager.authorizationStatus {
        case .notDetermined:
            print("[CampusDogsLocation] requesting when-in-use authorization")
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("[CampusDogsLocation] location request failed before CoreLocation request: authorizationStatus=\(authorizationDescription(manager.authorizationStatus))")
            throw OneShotLocationError.permissionDenied
        case .authorizedAlways, .authorizedWhenInUse: break
        @unknown default:
            print("[CampusDogsLocation] location request failed before CoreLocation request: unknown authorization status")
            throw OneShotLocationError.unavailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            if manager.authorizationStatus == .notDetermined { return }
            requestOneLocation(reason: "current authorization already granted")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("[CampusDogsLocation] authorization changed; status=\(authorizationDescription(manager.authorizationStatus)), continuationPending=\(continuation != nil)")
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: requestOneLocation(reason: "authorization delegate callback")
        case .denied, .restricted:
            print("[CampusDogsLocation] location request failed after authorization change")
            finish(.failure(OneShotLocationError.permissionDenied))
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("[CampusDogsLocation] didUpdateLocations received; count=\(locations.count)")
        for location in locations {
            print("[CampusDogsLocation] location latitude=\(location.coordinate.latitude), longitude=\(location.coordinate.longitude), horizontalAccuracy=\(location.horizontalAccuracy), timestamp=\(location.timestamp), ageSeconds=\(Date().timeIntervalSince(location.timestamp))")
        }
        guard let coordinate = locations.last?.coordinate else {
            print("[CampusDogsLocation] location request failed: didUpdateLocations contained no location")
            finish(.failure(OneShotLocationError.unavailable))
            return
        }
        print("[CampusDogsLocation] location request succeeded; latitude=\(coordinate.latitude), longitude=\(coordinate.longitude)")
        finish(.success(coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        if let clError = error as? CLError {
            print("[CampusDogsLocation] didFailWithError; domain=\(nsError.domain), code=\(nsError.code), description=\(error.localizedDescription), isCLError=true, clErrorCode=\(String(describing: clError.code))")
        } else {
            print("[CampusDogsLocation] didFailWithError; domain=\(nsError.domain), code=\(nsError.code), description=\(error.localizedDescription), isCLError=false")
        }
        print("[CampusDogsLocation] location request failed after CoreLocation error")
        finish(.failure(OneShotLocationError.unavailable))
    }

    private func requestOneLocation(reason: String) {
        print("[CampusDogsLocation] requestLocation invoked; reason=\(reason), authorizationStatus=\(authorizationDescription(manager.authorizationStatus))")
        manager.requestLocation()
    }

    private func authorizationDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "notDetermined"
        case .restricted: "restricted"
        case .denied: "denied"
        case .authorizedAlways: "authorizedAlways"
        case .authorizedWhenInUse: "authorizedWhenInUse"
        @unknown default: "unknown"
        }
    }

    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        let continuation = continuation; self.continuation = nil
        switch result { case .success(let coordinate): continuation?.resume(returning: coordinate); case .failure(let error): continuation?.resume(throwing: error) }
    }
}
