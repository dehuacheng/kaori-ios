import SwiftUI
import Charts

struct WeightChartView: View {
    let weights: [WeightEntry]

    @State private var visibleDays: Double = 30
    @State private var baseVisibleDays: Double = 30

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let segment: Int
    }

    /// All points with segment IDs, filtered to the visible date range.
    private var chartPoints: [ChartPoint] {
        let sorted = weights.compactMap { entry -> (date: Date, weight: Double)? in
            guard let date = Self.dateFormatter.date(from: entry.date) else { return nil }
            return (date, entry.weightKg)
        }.sorted { $0.date < $1.date }

        // Assign segments on full dataset
        var allPoints: [ChartPoint] = []
        var segment = 0
        for (i, item) in sorted.enumerated() {
            if i > 0, item.date.timeIntervalSince(sorted[i - 1].date) > 30 * 86400 {
                segment += 1
            }
            allPoints.append(ChartPoint(date: item.date, weight: item.weight, segment: segment))
        }

        // Filter to visible window from latest date, always keep at least 2 points
        guard let lastDate = allPoints.last?.date else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: -Int(visibleDays), to: lastDate) ?? lastDate
        let filtered = allPoints.filter { $0.date >= cutoff }
        if filtered.count >= 2 {
            return filtered
        }
        return Array(allPoints.suffix(min(allPoints.count, 2)))
    }

    private var axisStrideDays: Int {
        switch visibleDays {
        case ..<15: return 2
        case ..<60: return 7
        case ..<180: return 14
        case ..<400: return 30
        default: return 60
        }
    }

    private enum RangePreset: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case year = "1Y"
        case twoYears = "2Y"
        case all = "All"

        var days: Double {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .year: return 365
            case .twoYears: return 730
            case .all: return 9999
            }
        }
    }

    var body: some View {
        let points = chartPoints
        VStack(spacing: 8) {
            // Range preset buttons
            HStack(spacing: 8) {
                ForEach(RangePreset.allCases, id: \.self) { preset in
                    Button(preset.rawValue) {
                        withAnimation {
                            visibleDays = preset.days
                            baseVisibleDays = preset.days
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(isActive(preset) ? Color.blue : Color.clear)
                    .foregroundStyle(isActive(preset) ? .white : .blue)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.blue, lineWidth: 1))
                    .buttonStyle(.borderless)
                }
            }

            if points.count >= 2 {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight),
                        series: .value("S", point.segment)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(.blue)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .symbolSize(12)
                    .foregroundStyle(.blue)
                }
                .chartLegend(.hidden)
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: axisStrideDays)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                VStack(spacing: 1) {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                    Text(date, format: .dateTime.year())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            visibleDays = max(7, min(9999, baseVisibleDays / value.magnification))
                        }
                        .onEnded { _ in
                            baseVisibleDays = visibleDays
                        }
                )
            }
        }
    }

    private func isActive(_ preset: RangePreset) -> Bool {
        if preset == .all { return visibleDays >= 9999 }
        return abs(visibleDays - preset.days) < 1
    }
}
