import CoreLocation
protocol LocationService { func currentLocation() async throws -> CLLocationCoordinate2D }
enum LocationError: Error { case unavailable }
struct MockLocationService: LocationService { func currentLocation() async throws -> CLLocationCoordinate2D { .init(latitude: 41.0135, longitude: 28.959) } }
