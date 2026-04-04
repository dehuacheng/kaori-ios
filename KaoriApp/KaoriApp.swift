import SwiftUI

struct IdentifiableInt: Identifiable {
    let value: Int
    var id: Int { value }
}

@main
struct KaoriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var config = AppConfig()
    @State private var localizer = Localizer()
    @State private var api: APIClient
    @State private var mealStore: MealStore
    @State private var weightStore: WeightStore
    @State private var profileStore: ProfileStore
    @State private var workoutStore: WorkoutStore
    @State private var financeStore: FinanceStore
    @State private var feedStore: FeedStore
    @State private var cardPreferenceStore: CardPreferenceStore
    @State private var postStore: PostStore
    @State private var reminderStore: ReminderStore
    @State private var cardRegistry = CardRegistry()
    @State private var timerEngine = TimerEngine()
    @State private var healthKit = HealthKitManager()
    @State private var notificationManager = NotificationManager()
    @State private var notificationSettings = NotificationSettings()

    init() {
        let config = AppConfig()
        let api = APIClient(config: config)
        _config = State(initialValue: config)
        _api = State(initialValue: api)
        _mealStore = State(initialValue: MealStore(api: api))
        _weightStore = State(initialValue: WeightStore(api: api))
        _profileStore = State(initialValue: ProfileStore(api: api))
        _workoutStore = State(initialValue: WorkoutStore(api: api))
        _financeStore = State(initialValue: FinanceStore(api: api))
        _feedStore = State(initialValue: FeedStore(api: api))
        _cardPreferenceStore = State(initialValue: CardPreferenceStore(api: api))
        _postStore = State(initialValue: PostStore(api: api))
        _reminderStore = State(initialValue: ReminderStore(api: api))

        // Register all card modules
        let registry = CardRegistry()
        registry.register(MealCardModule())
        registry.register(WeightCardModule())
        registry.register(WorkoutCardModule())
        registry.register(HealthKitWorkoutCardModule())
        registry.register(PortfolioCardModule())
        registry.register(NutritionCardModule())
        registry.register(SummaryCardModule())
        registry.register(PostCardModule())
        registry.register(ReminderCardModule())
        _cardRegistry = State(initialValue: registry)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(config)
                .environment(localizer)
                .environment(api)
                .environment(mealStore)
                .environment(weightStore)
                .environment(profileStore)
                .environment(workoutStore)
                .environment(financeStore)
                .environment(feedStore)
                .environment(cardPreferenceStore)
                .environment(cardRegistry)
                .environment(postStore)
                .environment(reminderStore)
                .environment(timerEngine)
                .environment(healthKit)
                .environment(notificationManager)
                .environment(notificationSettings)
        }
    }
}

struct ContentView: View {
    @Environment(AppConfig.self) private var config
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(NotificationSettings.self) private var notificationSettings
    @Environment(CardRegistry.self) private var cardRegistry
    @Environment(FeedStore.self) private var feedStore
    @State private var showImportPrompt = false
    @State private var importExistingWorkouts: [Workout] = []
    @State private var selectedTab = 0
    @State private var showAddMenu = false
    @State private var showMealCreate = false
    @State private var showWeightCreate = false
    /// Active card module for sheet-based creation (driven by "+" menu)
    @State private var activeCreateModule: String?
    @State private var newWorkoutId: IdentifiableInt?
    @State private var dismissedWorkoutId: Int?
    @State private var feedRefreshToken = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ConnectionBanner(isConnected: api.isConnected)

                if !config.isConfigured {
                    NavigationStack {
                        SettingsView()
                    }
                } else {
                    TabView(selection: $selectedTab) {
                        FeedView(showMealCreate: $showMealCreate, showWeightCreate: $showWeightCreate, refreshToken: feedRefreshToken)
                            .tag(0)
                            .tabItem { Label(L.t("tab.home"), systemImage: "house") }
                        // Center "+" button (intercepted, never actually selected)
                        Color.clear
                            .tag(99)
                            .tabItem { Label(L.t("tab.add"), systemImage: "plus.circle.fill") }
                        MoreView()
                            .tag(2)
                            .tabItem { Label(L.t("tab.more"), systemImage: "ellipsis.circle") }
                    }
                    .onChange(of: selectedTab) { oldValue, newValue in
                        if newValue == 99 {
                            // Intercept the "+" tab — show menu instead
                            selectedTab = oldValue
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAddMenu = true
                            }
                        }
                    }
                }
            }

            // Add menu overlay — Control Center style
            if showAddMenu {
                // Dimmed backdrop (tap to dismiss)
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showAddMenu = false
                        }
                    }

                // Blurred panel with buttons — driven by CardRegistry
                let columns = Array(repeating: GridItem(.fixed(80), spacing: 14), count: 4)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(cardRegistry.addableModules, id: \.cardType) { module in
                        addMenuButton(icon: module.iconName, label: L.t(module.displayNameKey)) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showAddMenu = false
                            }
                            handleAddAction(for: module.cardType)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.bottom, 90)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .task {
            if config.isConfigured {
                _ = await api.healthCheck()
                await notificationManager.checkPermission()
                if notificationSettings.notificationsEnabled {
                    notificationManager.rescheduleAll(settings: notificationSettings)
                    BackgroundTaskManager.scheduleDailySummaryFetch()
                }
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
        .fullScreenCover(item: $newWorkoutId, onDismiss: {
            Task {
                // Delete workout if no exercises were added
                if let id = dismissedWorkoutId {
                    if let detail = try? await workoutStore.getWorkout(id),
                       detail.exercises.isEmpty {
                        try? await workoutStore.deleteWorkout(id)
                    }
                    dismissedWorkoutId = nil
                }
                await workoutStore.loadWorkouts()
                feedRefreshToken = UUID()
            }
        }) { item in
            NavigationStack {
                WorkoutDetailView(workoutId: item.value)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(L.t("common.done")) {
                                dismissedWorkoutId = item.value
                                newWorkoutId = nil
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: Binding(
            get: { activeCreateModule != nil },
            set: { if !$0 { activeCreateModule = nil } }
        ), onDismiss: {
            Task { feedRefreshToken = UUID() }
        }) {
            if let moduleType = activeCreateModule,
               let module = cardRegistry.module(for: moduleType),
               let createView = module.createView(onDismiss: { activeCreateModule = nil }) {
                createView
            }
        }
        .sheet(isPresented: $showImportPrompt) {
            WorkoutImportView(workouts: workoutStore.pendingImportWorkouts, existingWorkouts: importExistingWorkouts)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if NotificationRouter.shared.pendingDestination != nil {
                selectedTab = 0
                NotificationRouter.shared.pendingDestination = nil
            }
        }
    }

    private func addMenuButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 80, height: 80)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    /// Route "+" menu tap to the right creation flow.
    /// Meal/weight/workout have existing bindings; all other card types
    /// use the generic activeCreateModule sheet — no switch needed for new types.
    private func handleAddAction(for cardType: String) {
        switch cardType {
        case "meal":
            showMealCreate = true
        case "weight":
            showWeightCreate = true
        case "workout":
            Task { await createWorkout() }
        default:
            // Generic: use the module's createView via sheet
            activeCreateModule = cardType
        }
    }

    private func createWorkout() async {
        do {
            let today = {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                return f.string(from: Date())
            }()
            let workout = try await workoutStore.createWorkout(date: today)
            await workoutStore.loadWorkouts()
            newWorkoutId = IdentifiableInt(value: workout.id)
        } catch {}
    }
}
