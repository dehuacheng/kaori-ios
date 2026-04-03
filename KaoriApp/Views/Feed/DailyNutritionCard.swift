import SwiftUI

struct DailyNutritionCard: View {
    let totals: NutritionTotals
    let profile: Profile?

    private var targetCal: Int? { profile?.targetCalories }
    private var targetProtein: Int? { profile?.targetProteinG }
    private var targetCarbs: Int? { profile?.targetCarbsG }
    // Fat target: remaining calories after protein (4cal/g) and carbs (4cal/g), divided by 9cal/g
    private var targetFat: Int? {
        guard let cal = targetCal, let p = targetProtein, let c = targetCarbs else { return nil }
        let remaining = max(cal - p * 4 - c * 4, 0)
        return remaining / 9
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            nutrientBar(
                label: "Cal",
                current: Double(totals.totalCal),
                target: targetCal.map(Double.init),
                unit: "kcal",
                color: .red
            )
            nutrientBar(
                label: "Protein",
                current: totals.totalProtein,
                target: targetProtein.map(Double.init),
                unit: "g",
                color: .blue
            )
            nutrientBar(
                label: "Carbs",
                current: totals.totalCarbs,
                target: targetCarbs.map(Double.init),
                unit: "g",
                color: .orange
            )
            nutrientBar(
                label: "Fat",
                current: totals.totalFat,
                target: targetFat.map(Double.init),
                unit: "g",
                color: .yellow
            )
        }
        .feedCard()
    }

    private func nutrientBar(label: String, current: Double, target: Double?, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .frame(width: 50, alignment: .leading)
                if let target {
                    Text("\(Int(current)) / \(Int(target)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(Int(current)) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let target, target > 0 {
                    Text("\(Int(min(current / target, 9.99) * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(current > target ? .red : .secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.gray.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * barProgress(current: current, target: target))
                }
            }
            .frame(height: 6)
        }
    }

    private func barProgress(current: Double, target: Double?) -> Double {
        guard let target, target > 0 else {
            return current > 0 ? 1.0 : 0.0
        }
        return min(current / target, 1.0)
    }
}
