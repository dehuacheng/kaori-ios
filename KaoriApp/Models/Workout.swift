import Foundation

// MARK: - Exercise Types

struct ExerciseType: Codable, Identifiable {
    let id: Int
    let name: String
    let category: String?
    let photoPath: String?
    let notes: String?
    let isStandard: Int?
    let isEnabled: Int?
    let status: String?
    let createdAt: String?
}

struct ExerciseTypeCreate: Codable {
    let name: String
    let category: String?
    let notes: String?
}

// MARK: - Workouts (list level)

struct Workout: Codable, Identifiable {
    let id: Int
    let date: String
    let notes: String?
    let activityType: String?
    let durationMinutes: Double?
    let caloriesBurned: Double?
    let summary: String?
    let exerciseCount: Int?
    let source: String?  // "manual" or "healthkit"
    let createdAt: String?

    var isImported: Bool { source == "healthkit" }
}

// MARK: - Workout Detail (full tree)

struct WorkoutDetail: Codable, Identifiable {
    let id: Int
    let date: String
    let notes: String?
    let activityType: String?
    let durationMinutes: Double?
    let caloriesBurned: Double?
    let summary: String?
    let exercises: [WorkoutExercise]
    let createdAt: String?
}

struct WorkoutExercise: Codable, Identifiable {
    let id: Int
    let workoutId: Int
    let exerciseTypeId: Int
    let orderIndex: Int
    let notes: String?
    let exerciseName: String
    let exerciseCategory: String?
    let sets: [ExerciseSet]
    let createdAt: String?
}

struct ExerciseSet: Codable, Identifiable {
    let id: Int
    let workoutExerciseId: Int
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let notes: String?
}

// MARK: - Workout Analysis

struct WorkoutAnalysis: Codable, Identifiable {
    let id: Int
    let workoutId: Int
    let isActive: Int?
    let totalSets: Int?
    let totalReps: Int?
    let totalVolumeKg: Double?
    let estimatedCalories: Double?
    let intensity: String?
    let muscleGroups: [String]?
    let summary: String?
    let trainerNotes: String?
    let progressNotes: String?
    let recommendations: String?
    let createdAt: String?
}

// MARK: - Timer Presets

struct TimerPreset: Codable, Identifiable {
    let id: Int
    let name: String
    let restSeconds: Int
    let workSeconds: Int
    let sets: Int
    let notes: String?
    let createdAt: String?
}

struct TimerPresetCreate: Codable {
    let name: String
    let restSeconds: Int
    let workSeconds: Int
    let sets: Int
    let notes: String?
}

// MARK: - Request/Response types

struct WorkoutCreate: Codable {
    let date: String?
    let notes: String?
    let activityType: String?
    let durationMinutes: Double?
    let caloriesBurned: Double?
    let source: String?  // "manual" or "healthkit"
}

struct WorkoutUpdate: Codable {
    let notes: String?
    let activityType: String?
    let durationMinutes: Double?
}

struct ExerciseAdd: Codable {
    let exerciseTypeId: Int
    let orderIndex: Int
    let notes: String?
}

struct SetCreate: Codable {
    let setNumber: Int
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let notes: String?
}

struct SetUpdate: Codable {
    let reps: Int?
    let weightKg: Double?
    let durationSeconds: Int?
    let notes: String?
}

struct AddExerciseResponse: Codable {
    let id: Int
    let workoutId: Int
}

struct AddSetResponse: Codable {
    let id: Int
    let workoutExerciseId: Int
}

struct DeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}

struct SummarizeResponse: Codable {
    let workoutId: Int
    let totalSets: Int
    let totalReps: Int
    let totalVolumeKg: Double
    let estimatedCalories: Double
    let muscleGroupsWorked: [String]
    let summary: String
    let intensity: String
    let trainerNotes: String
    let progressNotes: String
    let recommendations: String
}

struct EnableDisableResponse: Codable {
    let id: Int
    let isEnabled: Bool
}

// MARK: - Activity display helpers

func activityDisplayName(_ activityType: String?) -> String {
    switch activityType {
    case "traditionalStrengthTraining": "Strength Training"
    case "functionalStrengthTraining": "Functional Training"
    case "highIntensityIntervalTraining": "HIIT"
    case "coreTraining": "Core Training"
    case "flexibility": "Flexibility"
    case "mixedCardio": "Mixed Cardio"
    case "running": "Running"
    case "cycling": "Cycling"
    case "swimming": "Swimming"
    case "walking": "Walking"
    case "hiking": "Hiking"
    case "yoga": "Yoga"
    case "pilates": "Pilates"
    case "crossTraining": "Cross Training"
    case "elliptical": "Elliptical"
    case "rowing": "Rowing"
    case "dance": "Dance"
    default: "Workout"
    }
}

func activityIconName(_ activityType: String?) -> String {
    switch activityType {
    case "traditionalStrengthTraining": "dumbbell"
    case "functionalStrengthTraining": "figure.strengthtraining.functional"
    case "highIntensityIntervalTraining": "bolt.heart"
    case "coreTraining": "figure.core.training"
    case "flexibility": "figure.flexibility"
    case "running": "figure.run"
    case "cycling": "figure.outdoor.cycle"
    case "swimming": "figure.pool.swim"
    case "walking": "figure.walk"
    case "hiking": "figure.hiking"
    case "yoga": "figure.yoga"
    case "pilates": "figure.pilates"
    case "crossTraining": "figure.cross.training"
    case "elliptical": "figure.elliptical"
    case "rowing": "figure.rowing"
    case "dance": "figure.dance"
    case "mixedCardio": "figure.mixed.cardio"
    default: "dumbbell"
    }
}
