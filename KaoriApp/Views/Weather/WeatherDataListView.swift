import SwiftUI

struct WeatherDataListView: View {
    @Environment(APIClient.self) private var api
    @Environment(Localizer.self) private var L
    @State private var entries: [WeatherHistoryEntry] = []
    @State private var isLoading = true
    @State private var location: WeatherLocation?

    private var unit: TemperatureUnit { .current }

    var body: some View {
        List {
            if let location {
                Section {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.name ?? String(format: "%.4f, %.4f", location.latitude ?? 0, location.longitude ?? 0))
                                    .font(.subheadline)
                                Text(String(format: "%.4f, %.4f", location.latitude ?? 0, location.longitude ?? 0))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        } icon: {
                            Image(systemName: "location.fill")
                                .foregroundStyle(.cyan)
                        }
                    }
                } header: {
                    Text(L.t("weather.location"))
                }
            }

            if entries.isEmpty && !isLoading {
                Section {
                    Text(L.t("weather.noData"))
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(entries) { entry in
                        weatherRow(entry)
                    }
                } header: {
                    Text(L.t("weather.history"))
                }
            }
        }
        .navigationTitle(L.t("card.weather"))
        .overlay {
            if isLoading && entries.isEmpty {
                ProgressView()
            }
        }
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private func weatherRow(_ entry: WeatherHistoryEntry) -> some View {
        HStack {
            if let icon = entry.icon {
                Image(systemName: icon)
                    .foregroundStyle(.cyan)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date)
                    .font(.subheadline)
                if let condition = entry.condition {
                    Text(condition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let temp = entry.temperature {
                    Text(unit.format(temp))
                        .font(.subheadline.bold())
                }
                if let high = entry.tempHigh, let low = entry.tempLow {
                    Text("\(unit.format(high)) / \(unit.format(low))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func loadData() async {
        isLoading = true
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let loc: WeatherLocation = try? await api.get("/api/weather/location"),
           loc.latitude != nil {
            location = loc
        }
        if let history: [WeatherHistoryEntry] = try? await api.get("/api/weather/history") {
            entries = history
        }
        isLoading = false
    }
}
