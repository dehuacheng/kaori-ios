import Foundation
import HealthKit

@Observable
class WorkoutStore {
    var workouts: [Workout] = []
    var exerciseTypes: [ExerciseType] = []
    var timerPresets: [TimerPreset] = []
    var currentDate: String = WorkoutStore.todayString()
    var isLoading = false
    var error: String?
    var pendingImportWorkouts: [HKWorkout] = []

    private let api: APIClient
    private var exerciseTypesLoaded = false

    private static let importedKey = "importedWorkoutUUIDs"
    private static let dismissedKey = "dismissedWorkoutUUIDs"
    private static let metaKey = "importedWorkoutMeta"

    static var importedUUIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: importedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: importedKey) }
    }

    static var dismissedUUIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: dismissedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: dismissedKey) }
    }

    init(api: APIClient) {
        self.api = api
    }

    static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var currentDateDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: currentDate) else { return currentDate }
        f.dateStyle = .medium
        return f.string(from: d)
    }

    var isToday: Bool {
        currentDate == Self.todayString()
    }

    func navigateDay(offset: Int) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: currentDate),
              let next = Calendar.current.date(byAdding: .day, value: offset, to: d) else { return }
        currentDate = f.string(from: next)
    }

    // MARK: - Workouts

    @MainActor
    func loadWorkouts() async {
        isLoading = true
        error = nil
        do {
            workouts = try await api.get("/api/workouts", query: ["date": currentDate])
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchWorkoutsForDates(_ dates: Set<String>) async -> [Workout] {
        var all: [Workout] = []
        for date in dates {
            if let result: [Workout] = try? await api.get("/api/workouts", query: ["date": date]) {
                all.append(contentsOf: result)
            }
        }
        return all
    }

    func createWorkout(date: String? = nil, notes: String? = nil, activityType: String = "traditionalStrengthTraining") async throws -> WorkoutDetail {
        let body = WorkoutCreate(date: date ?? currentDate, notes: notes, activityType: activityType)
        let response: WorkoutDetail = try await api.post("/api/workouts", body: body)
        await loadWorkouts()
        return response
    }

    func getWorkout(_ id: Int) async throws -> WorkoutDetail {
        try await api.get("/api/workouts/\(id)")
    }

    func updateWorkout(_ id: Int, body: WorkoutUpdate) async throws -> WorkoutDetail {
        try await api.put("/api/workouts/\(id)", body: body)
    }

    func deleteWorkout(_ id: Int) async throws {
        let _: DeleteResponse = try await api.delete("/api/workouts/\(id)")

        // Clean up import tracking so the HK workout can be re-imported
        if let meta = Self.importedMeta(forWorkoutId: id), let hkUUID = meta.hkUUID {
            var imported = Self.importedUUIDs
            imported.remove(hkUUID)
            Self.importedUUIDs = imported
        }
        Self.removeImportedMeta(forWorkoutId: id)
        await loadWorkouts()
    }

    // MARK: - Exercises within a workout

    func addExercise(workoutId: Int, exerciseTypeId: Int, orderIndex: Int, notes: String? = nil) async throws -> AddExerciseResponse {
        let body = ExerciseAdd(exerciseTypeId: exerciseTypeId, orderIndex: orderIndex, notes: notes)
        return try await api.post("/api/workouts/\(workoutId)/exercises", body: body)
    }

    func deleteExercise(workoutId: Int, exerciseId: Int) async throws {
        let _: DeleteResponse = try await api.delete("/api/workouts/\(workoutId)/exercises/\(exerciseId)")
    }

    // MARK: - Sets

    func addSet(workoutId: Int, exerciseId: Int, body: SetCreate) async throws -> AddSetResponse {
        try await api.post("/api/workouts/\(workoutId)/exercises/\(exerciseId)/sets", body: body)
    }

    func updateSet(workoutId: Int, exerciseId: Int, setId: Int, body: SetUpdate) async throws {
        let _: [String: AnyCodable] = try await api.put(
            "/api/workouts/\(workoutId)/exercises/\(exerciseId)/sets/\(setId)", body: body
        )
    }

    func deleteSet(workoutId: Int, exerciseId: Int, setId: Int) async throws {
        let _: DeleteResponse = try await api.delete(
            "/api/workouts/\(workoutId)/exercises/\(exerciseId)/sets/\(setId)"
        )
    }

    // MARK: - AI Summary

    func summarize(_ workoutId: Int) async throws -> SummarizeResponse {
        try await api.post("/api/workouts/\(workoutId)/summarize")
    }

    func getAnalysis(_ workoutId: Int) async throws -> WorkoutAnalysis {
        try await api.get("/api/workouts/\(workoutId)/analysis")
    }

    // MARK: - Exercise Types

    @MainActor
    func loadExerciseTypes(force: Bool = false) async {
        guard force || !exerciseTypesLoaded else { return }
        do {
            exerciseTypes = try await api.get("/api/exercise-types", query: ["enabled_only": "true"])
            exerciseTypesLoaded = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadAllExerciseTypes() async throws -> [ExerciseType] {
        try await api.get("/api/exercise-types")
    }

    func createExerciseType(name: String, category: String?, notes: String?) async throws -> ExerciseType {
        let body = ExerciseTypeCreate(name: name, category: category, notes: notes)
        let result: ExerciseType = try await api.post("/api/exercise-types", body: body)
        exerciseTypesLoaded = false
        return result
    }

    func identifyExercise(photo: Data, hint: String?) async throws -> ExerciseType {
        var fields: [String: String] = [:]
        if let hint, !hint.isEmpty { fields["hint"] = hint }
        let result: ExerciseType = try await api.postMultipart("/api/exercise-types/identify", fields: fields, imageData: photo)
        exerciseTypesLoaded = false
        return result
    }

    func enableExerciseType(_ id: Int) async throws {
        let _: EnableDisableResponse = try await api.post("/api/exercise-types/\(id)/enable")
        exerciseTypesLoaded = false
    }

    func disableExerciseType(_ id: Int) async throws {
        let _: EnableDisableResponse = try await api.post("/api/exercise-types/\(id)/disable")
        exerciseTypesLoaded = false
    }

    func deleteExerciseType(_ id: Int) async throws {
        let _: DeleteResponse = try await api.delete("/api/exercise-types/\(id)")
        exerciseTypesLoaded = false
    }

    // MARK: - Timer Presets

    @MainActor
    func loadTimerPresets() async {
        do {
            timerPresets = try await api.get("/api/timer-presets")
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createTimerPreset(body: TimerPresetCreate) async throws -> TimerPreset {
        try await api.post("/api/timer-presets", body: body)
    }

    func deleteTimerPreset(_ id: Int) async throws {
        let _: DeleteResponse = try await api.delete("/api/timer-presets/\(id)")
    }

    // MARK: - Apple Health Import

    @MainActor
    func checkForNewHealthKitWorkouts(healthKit: HealthKitManager) async {
        guard healthKit.isAvailable else { return }
        _ = await healthKit.requestAuthorization()
        let since = Date().addingTimeInterval(-24 * 60 * 60)
        guard let hkWorkouts = try? await healthKit.fetchWorkouts(since: since) else { return }

        let imported = Self.importedUUIDs
        let dismissed = Self.dismissedUUIDs
        pendingImportWorkouts = hkWorkouts.filter { w in
            let uuid = w.uuid.uuidString
            return !imported.contains(uuid) && !dismissed.contains(uuid)
        }
    }

    func fetchAllWorkouts(healthKit: HealthKitManager, since: Date) async -> [HKWorkout] {
        guard healthKit.isAvailable else { return [] }
        _ = await healthKit.requestAuthorization()
        return (try? await healthKit.fetchWorkouts(since: since)) ?? []
    }

    static func isAlreadyImported(_ hkWorkout: HKWorkout) -> Bool {
        importedUUIDs.contains(hkWorkout.uuid.uuidString)
    }

    func importHealthKitWorkout(_ hkWorkout: HKWorkout) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: hkWorkout.startDate)

        let activityType = HealthKitManager.activityTypeString(from: hkWorkout.workoutActivityType)
        let displayName = HealthKitManager.activityDisplayName(from: hkWorkout.workoutActivityType)
        let durationMinutes = hkWorkout.duration / 60
        let calories = hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
        let distance = hkWorkout.totalDistance?.doubleValue(for: .meter())

        let notes = "Imported from Apple Health"

        let created = try await createWorkout(date: dateStr, notes: notes, activityType: activityType)
        let update = WorkoutUpdate(notes: notes, activityType: activityType, durationMinutes: durationMinutes)
        _ = try await updateWorkout(created.id, body: update)

        // Save HK metadata locally for rich display
        let meta = ImportedWorkoutMeta(
            hkUUID: hkWorkout.uuid.uuidString,
            activityType: activityType,
            activityDisplayName: displayName,
            startDate: hkWorkout.startDate,
            endDate: hkWorkout.endDate,
            durationSeconds: hkWorkout.duration,
            distanceMeters: distance,
            caloriesBurned: calories
        )
        Self.saveImportedMeta(meta, forWorkoutId: created.id)

        var imported = Self.importedUUIDs
        imported.insert(hkWorkout.uuid.uuidString)
        Self.importedUUIDs = imported
    }

    func dismissHealthKitWorkout(_ hkWorkout: HKWorkout) {
        var dismissed = Self.dismissedUUIDs
        dismissed.insert(hkWorkout.uuid.uuidString)
        Self.dismissedUUIDs = dismissed
    }

    // MARK: - Imported Workout Metadata

    static func saveImportedMeta(_ meta: ImportedWorkoutMeta, forWorkoutId id: Int) {
        var all = allImportedMeta()
        all[String(id)] = meta
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: metaKey)
        }
    }

    static func importedMeta(forWorkoutId id: Int) -> ImportedWorkoutMeta? {
        allImportedMeta()[String(id)]
    }

    static func removeImportedMeta(forWorkoutId id: Int) {
        var all = allImportedMeta()
        all.removeValue(forKey: String(id))
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: metaKey)
        }
    }

    private static func allImportedMeta() -> [String: ImportedWorkoutMeta] {
        guard let data = UserDefaults.standard.data(forKey: metaKey),
              let dict = try? JSONDecoder().decode([String: ImportedWorkoutMeta].self, from: data) else {
            return [:]
        }
        return dict
    }
}
