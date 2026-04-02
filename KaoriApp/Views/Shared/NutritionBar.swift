import SwiftUI

struct NutritionBar: View {
    let label: String
    let current: Double
    let target: Double
    let unit: String
    var color: Color = .blue

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.5)
    }

    private var percentage: Int {
        guard target > 0 else { return 0 }
        return Int(current / target * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(current))/\(Int(target))\(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 1.0 ? .red : color)
                        .frame(width: geo.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 8)
        }
    }
}

struct MacroRow: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let targetProtein: Double
    let targetCarbs: Double

    var body: some View {
        HStack(spacing: 16) {
            MacroPill(label: "P", value: protein, target: targetProtein, color: .orange)
            MacroPill(label: "C", value: carbs, target: targetCarbs, color: .green)
            MacroPill(label: "F", value: fat, target: 0, color: .purple)
        }
    }
}

private struct MacroPill: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.caption)
            if target > 0 {
                Text("/\(Int(target))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
