import SwiftUI
import Charts

/// Simple, non-interactive weight chart for the dashboard.
struct WeightMiniChartView: View {
    let weights: [WeightEntry]

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

    /// Last connected segment (gap ≤ 30 days), capped at 30 days.
    private var chartPoints: [ChartPoint] {
        let sorted = weights.compactMap { entry -> (date: Date, weight: Double)? in
            guard let date = Self.dateFormatter.date(from: entry.date) else { return nil }
            return (date, entry.weightKg)
        }.sorted { $0.date < $1.date }

        // Assign segments
        var points: [ChartPoint] = []
        var segment = 0
        for (i, item) in sorted.enumerated() {
            if i > 0, item.date.timeIntervalSince(sorted[i - 1].date) > 30 * 86400 {
                segment += 1
            }
            points.append(ChartPoint(date: item.date, weight: item.weight, segment: segment))
        }

        // Only keep the last segment, capped at 30 days
        guard let lastSeg = points.last?.segment else { return [] }
        let segPoints = points.filter { $0.segment == lastSeg }
        guard let lastDate = segPoints.last?.date else { return segPoints }
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: lastDate) ?? lastDate
        return segPoints.filter { $0.date >= cutoff }
    }

    var body: some View {
        let points = chartPoints
        if points.count >= 2 {
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .symbolSize(8)
                .foregroundStyle(.blue)
            }
            .chartLegend(.hidden)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let w = value.as(Double.self) {
                            Text(String(format: "%.0f", w))
                                .font(.caption2)
                        }
                    }
                }
            }
        }
    }
}
