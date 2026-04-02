import SwiftUI

@main
struct KaoriApp: App {
    @State private var config = AppConfig()
    @State private var api: APIClient
    @State private var mealStore: MealStore
    @State private var weightStore: WeightStore
    @State private var profileStore: ProfileStore
    @State private var workoutStore: WorkoutStore
    @State private var timerEngine = TimerEngine()
    @State private var healthKit = HealthKitManager()

    init() {
        let config = AppConfig()
        let api = APIClient(config: config)
        _config = State(initialValue: config)
        _api = State(initialValue: api)
        _mealStore = State(initialValue: MealStore(api: api))
        _weightStore = State(initialValue: WeightStore(api: api))
        _profileStore = State(initialValue: ProfileStore(api: api))
        _workoutStore = State(initialValue: WorkoutStore(api: api))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(config)
                .environment(api)
                .environment(mealStore)
                .environment(weightStore)
                .environment(profileStore)
                .environment(workoutStore)
                .environment(timerEngine)
                .environment(healthKit)
        }
    }
}

struct ContentView: View {
    @Environment(AppConfig.self) private var config
    @Environment(APIClient.self) private var api
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(HealthKitManager.self) private var healthKit
    @State private var showImportPrompt = false
    @State private var importExistingWorkouts: [Workout] = []

    var body: some View {
        VStack(spacing: 0) {
            ConnectionBanner(isConnected: api.isConnected)

            if !config.isConfigured {
                NavigationStack {
                    SettingsView()
                }
            } else {
                TabView {
                    DashboardView()
                        .tabItem { Label("Home", systemImage: "house") }
                    NavigationStack {
                        MealListView()
                    }
                    .tabItem { Label("Meals", systemImage: "fork.knife") }
                    NavigationStack {
                        WeightView()
                    }
                    .tabItem { Label("Weight", systemImage: "scalemass") }
                    NavigationStack {
                        WorkoutListView()
                    }
                    .tabItem { Label("Gym", systemImage: "dumbbell") }
                }
            }
        }
        .task {
            if config.isConfigured {
                _ = await api.healthCheck()
                await workoutStore.checkForNewHealthKitWorkouts(healthKit: healthKit)
                if !workoutStore.pendingImportWorkouts.isEmpty {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dates = Set(workoutStore.pendingImportWorkouts.map { dateFormatter.string(from: $0.startDate) })
                    importExistingWorkouts = await workoutStore.fetchWorkoutsForDates(dates)
                    showImportPrompt = true
                }
            }
        }
        .sheet(isPresented: $showImportPrompt) {
            WorkoutImportView(workouts: workoutStore.pendingImportWorkouts, existingWorkouts: importExistingWorkouts)
        }
    }
}
