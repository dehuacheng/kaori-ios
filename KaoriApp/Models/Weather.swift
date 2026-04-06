import Foundation

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .celsius: "°C"
        case .fahrenheit: "°F"
        }
    }
    var symbol: String { label }

    static var current: TemperatureUnit {
        let raw = UserDefaults.standard.string(forKey: "temperatureUnit") ?? "fahrenheit"
        return TemperatureUnit(rawValue: raw) ?? .fahrenheit
    }

    static func save(_ unit: TemperatureUnit) {
        UserDefaults.standard.set(unit.rawValue, forKey: "temperatureUnit")
    }

    func format(_ celsius: Double) -> String {
        switch self {
        case .celsius:
            return String(format: "%.0f°C", celsius)
        case .fahrenheit:
            let f = celsius * 9.0 / 5.0 + 32.0
            return String(format: "%.0f°F", f)
        }
    }
}

/// A single cached weather record from the backend history endpoint.
struct WeatherHistoryEntry: Codable, Identifiable {
    let id: Int
    let date: String
    let weatherType: String
    let temperature: Double?
    let feelsLike: Double?
    let tempHigh: Double?
    let tempLow: Double?
    let humidity: Int?
    let windSpeed: Double?
    let weatherCode: Int?
    let condition: String?
    let icon: String?
    let precipitation: Double?
    let uvIndex: Double?
    let sunrise: String?
    let sunset: String?
    let fetchedAt: String?
}

struct WeatherData: Codable {
    let date: String
    let weatherType: String  // "current" or "forecast"
    let temperature: Double?
    let feelsLike: Double?
    let tempHigh: Double?
    let tempLow: Double?
    let humidity: Int?
    let windSpeed: Double?
    let weatherCode: Int?
    let condition: String?
    let icon: String?  // SF Symbol name from backend
    let precipitation: Double?
    let uvIndex: Double?
    let sunrise: String?
    let sunset: String?
}

struct WeatherLocation: Codable {
    let latitude: Double?
    let longitude: Double?
    let name: String?
}

struct WeatherResponse: Codable {
    let current: WeatherData?
    let forecast: WeatherData?
    let location: WeatherLocation?
    let isLive: Bool
}
