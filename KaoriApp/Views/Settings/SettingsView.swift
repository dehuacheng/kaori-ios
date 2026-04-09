import SwiftUI
import HealthKit

struct SettingsView: View {
    @Environment(AppConfig.self) private var config
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api
    @Environment(ProfileStore.self) private var profileStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(NotificationSettings.self) private var notificationSettings
    @State private var serverURL = ""
    @State private var token = ""
    @State private var testResult: String?
    @State private var isTesting = false
    @State private var isImporting = false
    @State private var importResult: String?
    @State private var showWorkoutImport = false
    @State private var workoutImportList: [HKWorkout] = []
    @State private var existingWorkouts: [Workout] = []
    @State private var isFetchingWorkouts = false
    @Environment(AppLockManager.self) private var appLockManager
    @State private var selectedLLMMode: LLMMode = .claudeCli
    @State private var isSavingLLM = false
    @State private var isBackfillingPhotos = false
    @State private var backfillResult: String?
    @State private var bodyWeightUnit: WeightUnit = .kg
    @State private var heightUnit: HeightUnit = .cm
    @State private var exerciseWeightUnit: WeightUnit = .kg
    @State private var temperatureUnit: TemperatureUnit = .current

    var body: some View {
        @Bindable var config = config
        @Bindable var L = L

        Form {
            // MARK: - Language
            Section {
                Picker(L.t("settings.language"), selection: $L.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            } header: {
                Text(L.t("settings.languageHeader"))
            }

            // MARK: - Units
            if config.isConfigured {
                Section {
                    Picker(L.t("settings.bodyWeightUnit"), selection: $bodyWeightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .onChange(of: bodyWeightUnit) { _, newValue in
                        Task { await saveUnit(unitBodyWeight: newValue.rawValue) }
                    }

                    Picker(L.t("settings.heightUnit"), selection: $heightUnit) {
                        ForEach(HeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .onChange(of: heightUnit) { _, newValue in
                        Task { await saveUnit(unitHeight: newValue.rawValue) }
                    }

                    Picker(L.t("settings.exerciseWeightUnit"), selection: $exerciseWeightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .onChange(of: exerciseWeightUnit) { _, newValue in
                        Task { await saveUnit(unitExerciseWeight: newValue.rawValue) }
                    }

                    Picker(L.t("settings.temperatureUnit"), selection: $temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .onChange(of: temperatureUnit) { _, newValue in
                        TemperatureUnit.save(newValue)
                    }
                } header: {
                    Text(L.t("settings.units"))
                }
            }

            // MARK: - Server connection
            Section(L.t("settings.server")) {
                TextField(L.t("settings.serverUrl"), text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField(L.t("settings.bearerToken"), text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text(L.t("settings.testConnection"))
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else if let testResult {
                            Image(systemName: testResult == "ok" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testResult == "ok" ? .green : .red)
                        }
                    }
                }
                .disabled(serverURL.isEmpty || token.isEmpty || isTesting)

                Button(L.t("common.save")) {
                    config.serverURL = serverURL
                    config.token = token
                }
                .disabled(serverURL.isEmpty || token.isEmpty)
            }

            if let testResult, testResult != "ok" {
                Section {
                    Text(testResult)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // MARK: - LLM Backend
            if config.isConfigured {
                Section {
                    Picker(L.t("settings.analysisEngine"), selection: $selectedLLMMode) {
                        ForEach(LLMMode.allCases) { mode in
                            VStack(alignment: .leading) {
                                Text(L.t("llm.\(mode.rawValue).label"))
                                Text(L.t("llm.\(mode.rawValue).description"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(mode)
                        }
                    }
                    .onChange(of: selectedLLMMode) { _, newValue in
                        Task { await saveLLMMode(newValue) }
                    }
                } header: {
                    Text(L.t("settings.llmBackend"))
                } footer: {
                    Text(L.t("settings.llmFooter"))
                }
            }

            // MARK: - Notifications
            if config.isConfigured {
                Section(L.t("settings.notifications")) {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Label(L.t("settings.manageNotifications"), systemImage: "bell")
                            Spacer()
                            Text(notificationSettings.hasAnyEnabled
                                ? L.t("notification.on") : L.t("notification.off"))
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // MARK: - Security
            if config.isConfigured {
                Section {
                    Toggle(L.t("settings.appLock"), isOn: Binding(
                        get: { appLockManager.isAppLockEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let ok = await appLockManager.authenticateToEnable()
                                    if ok {
                                        appLockManager.isAppLockEnabled = true
                                    }
                                }
                            } else {
                                appLockManager.isAppLockEnabled = false
                            }
                        }
                    ))
                } header: {
                    Text(L.t("settings.security"))
                } footer: {
                    Text(L.t("settings.appLockFooter", appLockManager.biometryLabel))
                }
            }

            // MARK: - AI Agent
            if config.isConfigured {
                Section(L.t("settings.aiAgent")) {
                    NavigationLink {
                        AgentMemoryView()
                    } label: {
                        Label(L.t("settings.agentMemory"), systemImage: "brain")
                    }
                }
            }

            // MARK: - Photo Descriptions
            if config.isConfigured {
                Section {
                    Button {
                        Task { await backfillPhotos() }
                    } label: {
                        HStack {
                            Image(systemName: "photo.badge.arrow.down")
                                .foregroundStyle(.blue)
                            Text(L.t("settings.backfillPhotos"))
                            Spacer()
                            if isBackfillingPhotos {
                                ProgressView()
                            } else if let backfillResult {
                                Text(backfillResult)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isBackfillingPhotos)
                } header: {
                    Text(L.t("settings.photoDescriptions"))
                } footer: {
                    Text(L.t("settings.backfillPhotosFooter"))
                }
            }

            // MARK: - Card Modules
            if config.isConfigured {
                Section {
                    NavigationLink {
                        CardModuleSettingsView()
                    } label: {
                        Label(L.t("settings.cardModules"), systemImage: "square.stack.3d.up")
                    }
                }
            }

            // MARK: - Apple Health
            if healthKit.isAvailable && config.isConfigured {
                Section(L.t("settings.appleHealth")) {
                    Button {
                        Task { await importFromHealth() }
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text(L.t("settings.importWeight"))
                            Spacer()
                            if isImporting {
                                ProgressView()
                            } else if let importResult {
                                Text(importResult)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isImporting)

                    Button {
                        Task { await fetchWorkoutsForImport() }
                    } label: {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundStyle(.orange)
                            Text(L.t("settings.importWorkouts"))
                            Spacer()
                            if isFetchingWorkouts {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isFetchingWorkouts)
                }
            }
        }
        .navigationTitle(L.t("settings.title"))
        .sheet(isPresented: $showWorkoutImport) {
            WorkoutImportView(workouts: workoutImportList, existingWorkouts: existingWorkouts)
        }
        .onAppear {
            serverURL = config.serverURL.isEmpty ? (AppConfig.bundledDefaults["serverURL"] ?? "") : config.serverURL
            token = config.token.isEmpty ? (AppConfig.bundledDefaults["token"] ?? "") : config.token
            if let mode = profileStore.profile?.llmMode, let llm = LLMMode(rawValue: mode) {
                selectedLLMMode = llm
            }
            if let profile = profileStore.profile {
                bodyWeightUnit = profile.bodyWeightUnit
                heightUnit = profile.heightUnit
                exerciseWeightUnit = profile.exerciseWeightUnit
            }
        }
    }

    private func importFromHealth() async {
        isImporting = true
        importResult = nil

        let authorized = await healthKit.requestAuthorization()
        guard authorized else {
            importResult = L.t("settings.accessDenied")
            isImporting = false
            return
        }

        do {
            let samples = try await healthKit.fetchWeightHistory()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let entries = samples.map { sample in
                BulkImportEntry(
                    date: dateFormatter.string(from: sample.date),
                    weightKg: (sample.kg * 10).rounded() / 10,
                    notes: "Imported from Apple Health"
                )
            }

            let result = try await weightStore.bulkImport(entries: entries)
            await weightStore.load(force: true)

            if result.imported > 0 {
                importResult = L.t("settings.importResult", result.imported, result.skipped)
            } else {
                importResult = L.t("settings.upToDate")
            }
        } catch {
            importResult = "Error: \(error.localizedDescription)"
        }
        isImporting = false
    }

    private func fetchWorkoutsForImport() async {
        isFetchingWorkouts = true
        let since = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        workoutImportList = await workoutStore.fetchAllWorkouts(healthKit: healthKit, since: since)

        // Fetch existing Kaori workouts for the same dates to detect duplicates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dates = Set(workoutImportList.map { dateFormatter.string(from: $0.startDate) })
        existingWorkouts = await workoutStore.fetchWorkoutsForDates(dates)

        isFetchingWorkouts = false
        showWorkoutImport = true
    }

    private func saveLLMMode(_ mode: LLMMode) async {
        isSavingLLM = true
        do {
            var update = ProfileUpdate()
            update.llmMode = mode.rawValue
            try await profileStore.update(update)
        } catch {
            // Revert picker on failure
            if let current = profileStore.profile?.llmMode, let llm = LLMMode(rawValue: current) {
                selectedLLMMode = llm
            }
        }
        isSavingLLM = false
    }

    private func saveUnit(
        unitBodyWeight: String? = nil,
        unitHeight: String? = nil,
        unitExerciseWeight: String? = nil
    ) async {
        var update = ProfileUpdate()
        update.unitBodyWeight = unitBodyWeight
        update.unitHeight = unitHeight
        update.unitExerciseWeight = unitExerciseWeight
        do {
            try await profileStore.update(update)
        } catch {
            // Revert on failure
            if let profile = profileStore.profile {
                bodyWeightUnit = profile.bodyWeightUnit
                heightUnit = profile.heightUnit
                exerciseWeightUnit = profile.exerciseWeightUnit
            }
        }
    }

    private func backfillPhotos() async {
        isBackfillingPhotos = true
        backfillResult = nil
        do {
            struct BackfillResponse: Codable {
                let postsProcessed: Int
                let errors: Int
            }
            let result: BackfillResponse = try await api.post("/api/feed/backfill-photos")
            backfillResult = L.t("settings.backfillResult", result.postsProcessed, result.errors)
        } catch {
            backfillResult = "Error"
        }
        isBackfillingPhotos = false
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil

        let oldURL = config.serverURL
        let oldToken = config.token
        config.serverURL = serverURL
        config.token = token

        let error = await api.healthCheckDetailed()
        testResult = error ?? "ok"

        if error != nil {
            config.serverURL = oldURL
            config.token = oldToken
        }
        isTesting = false
    }
}
