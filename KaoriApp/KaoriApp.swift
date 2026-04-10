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
    @State private var documentStore: DocumentStore
    @State private var reminderStore: ReminderStore
    @State private var agentStore: AgentStore
    @State private var cardRegistry = CardRegistry()
    @State private var timerEngine = TimerEngine()
    @State private var healthKit = HealthKitManager()
    @State private var notificationManager = NotificationManager()
    @State private var notificationSettings = NotificationSettings()
    @State private var locationManager = LocationManager()
    @State private var appLockManager = AppLockManager()

    init() {
        let config = AppConfig()
        let api = APIClient(config: config)

        // Register all card modules first so shared stores can delegate to them.
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
        registry.register(WeatherCardModule())

        _config = State(initialValue: config)
        _api = State(initialValue: api)
        _mealStore = State(initialValue: MealStore(api: api))
        _weightStore = State(initialValue: WeightStore(api: api))
        _profileStore = State(initialValue: ProfileStore(api: api))
        _workoutStore = State(initialValue: WorkoutStore(api: api))
        _financeStore = State(initialValue: FinanceStore(api: api))
        _feedStore = State(initialValue: FeedStore(api: api, cardRegistry: registry))
        _cardPreferenceStore = State(initialValue: CardPreferenceStore(api: api))
        _postStore = State(initialValue: PostStore(api: api))
        _documentStore = State(initialValue: DocumentStore(api: api))
        _reminderStore = State(initialValue: ReminderStore(api: api))
        _agentStore = State(initialValue: AgentStore(api: api, config: config))
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
                .environment(documentStore)
                .environment(reminderStore)
                .environment(agentStore)
                .environment(timerEngine)
                .environment(healthKit)
                .environment(notificationManager)
                .environment(notificationSettings)
                .environment(locationManager)
                .environment(appLockManager)
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
    @Environment(LocationManager.self) private var locationManager
    @Environment(AppLockManager.self) private var appLockManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showImportPrompt = false
    @State private var importExistingWorkouts: [Workout] = []
    @State private var selectedTab = 0
    @State private var showAddMenu = false
    /// Active card module for sheet-based creation (driven by "+" menu)
    @State private var activeCreateModule: String?
    @State private var pendingAddActionCardType: String?
    @State private var newWorkoutId: IdentifiableInt?
    @State private var dismissedWorkoutId: Int?
    @State private var feedRefreshToken = UUID()
    var body: some View {
        VStack(spacing: 0) {
            ConnectionBanner(isConnected: api.isConnected)

            if !config.isConfigured {
                NavigationStack {
                    SettingsView()
                }
            } else {
                // Custom binding intercepts the "+" tab (99) without ever
                // changing selectedTab, preventing NavigationStack disruption.
                TabView(selection: Binding(
                    get: { selectedTab },
                    set: { newValue in
                        if newValue == 99 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAddMenu = true
                            }
                        } else {
                            selectedTab = newValue
                        }
                    }
                )) {
                    FeedView(refreshToken: feedRefreshToken)
                        .tag(0)
                        .tabItem { Label(L.t("tab.home"), systemImage: "house") }
                    ChatSessionListView()
                        .tag(1)
                        .tabItem { Label(L.t("tab.chat"), systemImage: "bubble.left.and.text.bubble.right") }
                    // Center "+" button (intercepted via binding, never actually selected)
                    Color.clear
                        .tag(99)
                        .tabItem { Label(L.t("tab.add"), systemImage: "plus.circle.fill") }
                    MoreView()
                        .tag(2)
                        .tabItem { Label(L.t("tab.more"), systemImage: "ellipsis.circle") }
                }
            }
        }
        // Add menu overlay — Control Center style.
        // The overlay is ALWAYS in the view tree (never conditionally
        // added/removed). Toggling showAddMenu only changes opacity and
        // hit-testing. This avoids SwiftUI view-hierarchy mutations that
        // corrupt the NavigationStack's UIKit hosting controller layout
        // for pushed detail views.
        .overlay {
            ZStack(alignment: .bottom) {
                // Dimmed backdrop — always present, opacity-driven
                Color.black
                    .opacity(showAddMenu ? 0.4 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(showAddMenu)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showAddMenu = false
                        }
                    }

                // Blurred panel with buttons — always present, visibility-driven
                let columns = Array(repeating: GridItem(.fixed(80), spacing: 14), count: 4)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(cardRegistry.addableModules, id: \.cardType) { module in
                        addMenuButton(icon: module.iconName, label: L.t(module.displayNameKey)) {
                            pendingAddActionCardType = module.cardType
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showAddMenu = false
                            }
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.bottom, 90)
                .opacity(showAddMenu ? 1 : 0)
                .scaleEffect(showAddMenu ? 1 : 0.8)
                .allowsHitTesting(showAddMenu)
                .accessibilityHidden(!showAddMenu)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAddMenu)
        }
        .task {
            if config.isConfigured {
                _ = await api.healthCheck()
                await notificationManager.checkPermission()
                if notificationSettings.notificationsEnabled {
                    notificationManager.rescheduleAll(settings: notificationSettings)
                    BackgroundTaskManager.scheduleDailySummaryFetch()
                    BackgroundTaskManager.scheduleAgentPostCheck()
                }
                locationManager.requestLocation(api: api)
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
        .onChange(of: showAddMenu) { _, isShowing in
            guard !isShowing, let cardType = pendingAddActionCardType else { return }
            pendingAddActionCardType = nil
            Task { @MainActor in
                // Let the add-menu dismissal settle before mutating
                // feed/navigation state.
                try? await Task.sleep(for: .milliseconds(350))
                selectedTab = 0
                await cardRegistry.performAddAction(
                    for: cardType,
                    context: CardAddActionContext(
                        presentCreateModule: { activeCreateModule = $0 },
                        createWorkout: createWorkout,
                        startSummaryGeneration: feedStore.startSummaryGeneration
                    )
                )
            }
        }
        .overlay {
            if appLockManager.isLocked {
                LockScreenView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                appLockManager.appDidEnterBackground()
            case .active:
                appLockManager.appWillEnterForeground()
            default:
                break
            }
        }
    }

    private func addMenuButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(height: 28)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 80, height: 80)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
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
