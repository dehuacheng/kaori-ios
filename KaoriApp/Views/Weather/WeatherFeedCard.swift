import SwiftUI

struct WeatherFeedCard: View {
    let payload: WeatherPayload
    @Environment(Localizer.self) private var L

    private var data: WeatherData { payload.data }
    private var isCurrent: Bool { payload.kind == .current }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if isCurrent {
                currentWeatherBody
            } else {
                forecastBody
            }
        }
        .feedCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: isCurrent ? (data.icon ?? "cloud.sun.fill") : "calendar")
                .foregroundStyle(.cyan)
                .font(.body.bold())
            Text(isCurrent ? L.t("weather.current") : L.t("weather.tomorrow"))
                .font(.subheadline.bold())
                .foregroundStyle(.cyan)
            if let name = payload.location?.name {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isCurrent && payload.isLive {
                CardStateBadge(.live)
            }
        }
    }

    // MARK: - Current Weather

    private var currentWeatherBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Temperature + condition
            HStack(alignment: .firstTextBaseline) {
                if let temp = data.temperature {
                    Text(formatTemp(temp))
                        .font(.title.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let condition = data.condition {
                        HStack(spacing: 4) {
                            if let icon = data.icon {
                                Image(systemName: icon)
                                    .font(.caption)
                            }
                            Text(condition)
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                    if let feelsLike = data.feelsLike {
                        Text("\(L.t("weather.feelsLike")) \(formatTemp(feelsLike))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            // High/Low
            if data.tempHigh != nil || data.tempLow != nil {
                HStack(spacing: 12) {
                    if let high = data.tempHigh {
                        Label(formatTemp(high), systemImage: "arrow.up")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let low = data.tempLow {
                        Label(formatTemp(low), systemImage: "arrow.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Details row
            HStack(spacing: 16) {
                if let humidity = data.humidity {
                    Label("\(humidity)%", systemImage: "humidity.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let wind = data.windSpeed {
                    Label(String(format: "%.0f km/h", wind), systemImage: "wind")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let uv = data.uvIndex {
                    Label(String(format: "%.0f", uv), systemImage: "sun.max.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let precip = data.precipitation, precip > 0 {
                    Label(String(format: "%.1f mm", precip), systemImage: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Forecast

    private var forecastBody: some View {
        HStack {
            // Condition icon + text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let icon = data.icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.cyan)
                    }
                    if let condition = data.condition {
                        Text(condition)
                            .font(.subheadline)
                    }
                }
                if let precip = data.precipitation, precip > 0 {
                    Label(String(format: "%.1f mm", precip), systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // High/Low temps
            VStack(alignment: .trailing, spacing: 2) {
                if let high = data.tempHigh {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text(formatTemp(high))
                            .font(.subheadline.bold())
                    }
                }
                if let low = data.tempLow {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                        Text(formatTemp(low))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatTemp(_ celsius: Double) -> String {
        TemperatureUnit.current.format(celsius)
    }
}
