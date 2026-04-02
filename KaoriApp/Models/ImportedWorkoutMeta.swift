import Foundation

struct ImportedWorkoutMeta: Codable {
    let hkUUID: String?
    let activityType: String
    let activityDisplayName: String
    let startDate: Date
    let endDate: Date
    let durationSeconds: Double
    let distanceMeters: Double?
    let caloriesBurned: Double?
}
