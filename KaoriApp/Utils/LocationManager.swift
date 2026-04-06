import CoreLocation

/// Simple CLLocationManager wrapper that gets the current location once
/// and saves it to the backend via PUT /api/weather/location.
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var api: APIClient?
    private var completion: ((CLLocation?) -> Void)?

    var lastLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    /// Request location permission and get current location.
    func requestLocation(api: APIClient) {
        self.api = api
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse ||
                    manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    /// Save the current location to the backend.
    func saveLocationToBackend() async {
        guard let location = lastLocation, let api else { return }

        let geocoder = CLGeocoder()
        var name: String?
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let place = placemarks.first {
            let parts = [place.locality, place.administrativeArea].compactMap { $0 }
            name = parts.joined(separator: ", ")
        }

        struct LocationBody: Encodable {
            let latitude: Double
            let longitude: Double
            let name: String?
        }

        struct LocationResponse: Decodable {
            let latitude: Double?
            let longitude: Double?
            let name: String?
        }

        let body = LocationBody(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: name
        )

        let _: LocationResponse? = try? await api.put(
            "/api/weather/location",
            body: body
        )
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
        completion?(lastLocation)
        completion = nil

        Task {
            await saveLocationToBackend()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(nil)
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
