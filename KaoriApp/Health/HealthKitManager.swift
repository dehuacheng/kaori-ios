import Foundation
import HealthKit

@Observable
class HealthKitManager {
    private let store = HKHealthStore()
    private let weightType = HKQuantityType(.bodyMass)
    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private let workoutType = HKObjectType.workoutType()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var isAuthorized = false

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(
                toShare: [weightType, workoutType],
                read: [weightType, workoutType]
            )
            let status = store.authorizationStatus(for: weightType)
            let authorized = status == .sharingAuthorized
            await MainActor.run { isAuthorized = authorized }
            return authorized
        } catch {
            return false
        }
    }

    // MARK: - Weight

    func fetchWeightHistory() async throws -> [(date: Date, kg: Double)] {
        let query = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: weightType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
            limit: HKObjectQueryNoLimit
        )
        let samples = try await query.result(for: store)
        return samples.map { sample in
            let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            return (date: sample.startDate, kg: kg)
        }
    }

    func saveWeight(kg: Double, date: Date) async throws {
        guard isAvailable else { return }
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
        try await store.save(sample)
    }

    // MARK: - Workouts

    func saveWorkout(activityType: HKWorkoutActivityType, start: Date, end: Date, calories: Double?) async throws {
        guard isAvailable else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try await builder.beginCollection(at: start)
        if let calories, calories > 0 {
            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let energySample = HKQuantitySample(
                type: activeEnergyType,
                quantity: energyQuantity,
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])
        }
        try await builder.endCollection(at: end)
        try await builder.finishWorkout()
    }

    func fetchWorkouts(since: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: since, end: Date(), options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
                }
            }
            self.store.execute(query)
        }
    }

    // MARK: - Activity Type Mapping

    static func workoutActivityType(from string: String?) -> HKWorkoutActivityType {
        switch string {
        case "traditionalStrengthTraining": .traditionalStrengthTraining
        case "functionalStrengthTraining": .functionalStrengthTraining
        case "running": .running
        case "cycling": .cycling
        case "swimming": .swimming
        case "yoga": .yoga
        case "pilates": .pilates
        case "hiking": .hiking
        case "crossTraining": .crossTraining
        case "highIntensityIntervalTraining": .highIntensityIntervalTraining
        case "coreTraining": .coreTraining
        case "walking": .walking
        default: .traditionalStrengthTraining
        }
    }

    static func activityTypeString(from type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: "traditionalStrengthTraining"
        case .functionalStrengthTraining: "functionalStrengthTraining"
        case .running: "running"
        case .cycling: "cycling"
        case .swimming: "swimming"
        case .yoga: "yoga"
        case .pilates: "pilates"
        case .hiking: "hiking"
        case .crossTraining: "crossTraining"
        case .highIntensityIntervalTraining: "highIntensityIntervalTraining"
        case .coreTraining: "coreTraining"
        case .walking: "walking"
        default: "other"
        }
    }

    static func activityDisplayName(from type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: "Strength Training"
        case .functionalStrengthTraining: "Functional Training"
        case .running: "Running"
        case .cycling: "Cycling"
        case .swimming: "Swimming"
        case .yoga: "Yoga"
        case .pilates: "Pilates"
        case .hiking: "Hiking"
        case .crossTraining: "Cross Training"
        case .highIntensityIntervalTraining: "HIIT"
        case .coreTraining: "Core Training"
        case .walking: "Walking"
        case .elliptical: "Elliptical"
        case .rowing: "Rowing"
        case .stairClimbing: "Stair Climbing"
        case .flexibility: "Flexibility"
        case .mixedCardio: "Mixed Cardio"
        case .dance: "Dance"
        case .jumpRope: "Jump Rope"
        default: "Workout"
        }
    }
}
