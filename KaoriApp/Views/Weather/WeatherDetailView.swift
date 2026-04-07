import SwiftUI

struct WeatherDetailView: View {
    let payload: WeatherPayload
    @Environment(Localizer.self) private var L

    private var data: WeatherData { payload.data }
    private var isCurrent: Bool { payload.kind == .current }
    private var unit: TemperatureUnit { .current }

    var body: some View {
        List {
            // Temperature section
            Section {
                if let temp = data.temperature {
                    detailRow(
                        icon: "thermometer.medium",
                        label: L.t("weather.current"),
                        value: unit.format(temp)
                    )
                }
                if let feelsLike = data.feelsLike {
                    detailRow(
                        icon: "thermometer.sun",
                        label: L.t("weather.feelsLike"),
                        value: unit.format(feelsLike)
                    )
                }
                if let high = data.tempHigh {
                    detailRow(
                        icon: "arrow.up",
                        label: L.t("weather.high"),
                        value: unit.format(high)
                    )
                }
                if let low = data.tempLow {
                    detailRow(
                        icon: "arrow.down",
                        label: L.t("weather.low"),
                        value: unit.format(low)
                    )
                }
            } header: {
                // Large header with condition
                VStack(spacing: 8) {
                    if let icon = data.icon {
                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundStyle(.cyan)
                    }
                    if let condition = data.condition {
                        Text(condition)
                            .font(.title3.bold())
                    }
                    if let name = payload.location?.name {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .textCase(nil)
            }

            // Conditions section
            Section(L.t("weather.conditions")) {
                if let humidity = data.humidity {
                    detailRow(
                        icon: "humidity.fill",
                        label: L.t("weather.humidity"),
                        value: "\(humidity)%"
                    )
                }
                if let wind = data.windSpeed {
                    detailRow(
                        icon: "wind",
                        label: L.t("weather.wind"),
                        value: String(format: "%.1f km/h", wind)
                    )
                }
                if let uv = data.uvIndex {
                    detailRow(
                        icon: "sun.max.fill",
                        label: L.t("weather.uv"),
                        value: String(format: "%.1f", uv),
                        detail: uvDescription(uv)
                    )
                }
                if let precip = data.precipitation {
                    detailRow(
                        icon: "drop.fill",
                        label: L.t("weather.precipitation"),
                        value: String(format: "%.1f mm", precip)
                    )
                }
            }

            // Sun section
            if data.sunrise != nil || data.sunset != nil {
                Section(L.t("weather.sun")) {
                    if let sunrise = data.sunrise {
                        detailRow(
                            icon: "sunrise.fill",
                            label: L.t("weather.sunrise"),
                            value: formatSunTime(sunrise)
                        )
                    }
                    if let sunset = data.sunset {
                        detailRow(
                            icon: "sunset.fill",
                            label: L.t("weather.sunset"),
                            value: formatSunTime(sunset)
                        )
                    }
                }
            }
        }
        .navigationTitle(isCurrent ? L.t("weather.current") : L.t("weather.tomorrow"))
    }

    private func detailRow(icon: String, label: String, value: String, detail: String? = nil) -> some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                    .frame(width: 24)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold())
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func uvDescription(_ uv: Double) -> String {
        switch uv {
        case ..<3: return L.t("weather.uv.low")
        case 3..<6: return L.t("weather.uv.moderate")
        case 6..<8: return L.t("weather.uv.high")
        case 8..<11: return L.t("weather.uv.veryHigh")
        default: return L.t("weather.uv.extreme")
        }
    }

    private func formatSunTime(_ isoTime: String) -> String {
        // Input: "2026-04-06T06:30" → "6:30 AM"
        let parts = isoTime.split(separator: "T")
        guard parts.count == 2 else { return isoTime }
        let timeParts = parts[1].split(separator: ":")
        guard timeParts.count >= 2,
              let hour = Int(timeParts[0]),
              let minute = Int(timeParts[1]) else { return String(parts[1]) }

        let ampm = hour >= 12 ? "PM" : "AM"
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", h12, minute, ampm)
    }
}
