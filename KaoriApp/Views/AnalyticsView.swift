import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(WeightStore.self) private var weightStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(APIClient.self) private var api
    @Environment(Localizer.self) private var L

    @State private var dailyCalories: [DailyCalorie] = []
    @State private var isLoadingCalories = false

    private var wu: WeightUnit { profileStore.profile?.bodyWeightUnit ?? .kg }
    private var targetCalories: Int? { profileStore.profile?.targetCalories }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Calorie chart
                Section(L.t("analytics.dailyCalories")) {
                    if dailyCalories.count >= 2 {
                        CalorieChartView(data: dailyCalories, target: targetCalories)
                            .frame(height: 220)
                    } else if isLoadingCalories {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    } else {
                        Text(L.t("analytics.notEnoughData"))
                            .foregroundStyle(.secondary)
                    }
                }

                // Weight chart
                Section(L.t("dashboard.weight")) {
                    if weightStore.weights.count >= 2 {
                        WeightChartView(weights: weightStore.weights)
                            .frame(height: 220)
                    } else {
                        Text(L.t("analytics.notEnoughData"))
                            .foregroundStyle(.secondary)
                    }

                    // Quick stats
                    HStack(spacing: 24) {
                        if let latest = weightStore.latest {
                            AnalyticsStatBox(label: L.t("weight.latest"), value: String(format: "%.1f", UnitConverter.displayWeight(latest, unit: wu)), unit: wu.label)
                        }
                        if let avg = weightStore.avg7d {
                            AnalyticsStatBox(label: L.t("weight.7dAvg"), value: String(format: "%.1f", UnitConverter.displayWeight(avg, unit: wu)), unit: wu.label)
                        }
                        if let delta = weightStore.deltaWeek {
                            AnalyticsStatBox(
                                label: L.t("weight.weekChange"),
                                value: String(format: "%+.1f", UnitConverter.displayWeight(delta, unit: wu)),
                                unit: wu.label,
                                color: delta < 0 ? .green : delta > 0 ? .red : .primary
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(L.t("tab.analytics"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.t("common.done")) { dismiss() }
                }
            }
            .refreshable {
                await weightStore.load(force: true)
                await loadCalories()
            }
            .task {
                await weightStore.load()
                await loadCalories()
            }
        }
    }

    private func loadCalories() async {
        isLoadingCalories = true
        var results: [DailyCalorie] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Fetch last 30 days
        for dayOffset in 0..<30 {
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateStr = formatter.string(from: date)
            if let response: MealListResponse = try? await api.get("/api/meals", query: ["date": dateStr]) {
                if response.totals.totalCal > 0 {
                    results.append(DailyCalorie(date: date, calories: response.totals.totalCal))
                }
            }
        }

        dailyCalories = results.sorted { $0.date < $1.date }
        isLoadingCalories = false
    }
}

// MARK: - Data Model

struct DailyCalorie: Identifiable {
    let date: Date
    let calories: Int
    var id: Date { date }
}

// MARK: - Calorie Chart

private struct CalorieChartView: View {
    let data: [DailyCalorie]
    let target: Int?

    var body: some View {
        Chart {
            ForEach(data) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Calories", entry.calories)
                )
                .foregroundStyle(barColor(entry.calories))
            }

            if let target {
                RuleMark(y: .value("Target", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("\(target)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date, format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private func barColor(_ calories: Int) -> Color {
        guard let target else { return .blue }
        let ratio = Double(calories) / Double(target)
        if ratio > 1.15 { return .red }
        if ratio > 1.0 { return .orange }
        return .blue
    }
}

// MARK: - Stat Box

private struct AnalyticsStatBox: View {
    let label: String
    let value: String
    let unit: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
