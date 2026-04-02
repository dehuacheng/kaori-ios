import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String {
        switch self {
        case .kg: "kg"
        case .lb: "lb"
        }
    }
}

enum HeightUnit: String, Codable, CaseIterable, Identifiable {
    case cm
    case `in`
    var id: String { rawValue }
    var label: String {
        switch self {
        case .cm: "cm"
        case .in: "in"
        }
    }
}

struct UnitConverter {
    static let kgPerLb = 0.45359237
    static let cmPerIn = 2.54

    // MARK: - Weight conversion

    static func displayWeight(_ kg: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: kg
        case .lb: kg / kgPerLb
        }
    }

    static func toMetricWeight(_ value: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .kg: value
        case .lb: value * kgPerLb
        }
    }

    // MARK: - Height conversion

    static func displayHeight(_ cm: Double, unit: HeightUnit) -> Double {
        switch unit {
        case .cm: cm
        case .in: cm / cmPerIn
        }
    }

    static func toMetricHeight(_ value: Double, unit: HeightUnit) -> Double {
        switch unit {
        case .cm: value
        case .in: value * cmPerIn
        }
    }

    /// Convert cm to (feet, inches) tuple
    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / cmPerIn
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches.rounded()) % 12
        return (feet, inches)
    }

    /// Convert feet + inches to cm
    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * cmPerIn
    }

    // MARK: - Formatting

    static func formatBodyWeight(_ kg: Double, unit: WeightUnit) -> String {
        let v = displayWeight(kg, unit: unit)
        return String(format: "%.1f %@", v, unit.label)
    }

    static func formatExerciseWeight(_ kg: Double, unit: WeightUnit) -> String {
        let v = displayWeight(kg, unit: unit)
        return String(format: "%.1f %@", v, unit.label)
    }

    static func formatHeight(_ cm: Double, unit: HeightUnit) -> String {
        switch unit {
        case .cm:
            return String(format: "%.0f cm", cm)
        case .in:
            let (ft, inc) = cmToFeetInches(cm)
            return "\(ft)'\(inc)\""
        }
    }

    static func formatWeightDelta(_ deltaKg: Double, unit: WeightUnit) -> String {
        let v = displayWeight(deltaKg, unit: unit)
        return String(format: "%+.1f %@", v, unit.label)
    }

    /// Format a display value for pre-filling an edit field (no unit suffix)
    static func displayWeightString(_ kg: Double, unit: WeightUnit) -> String {
        String(format: "%.1f", displayWeight(kg, unit: unit))
    }
}
