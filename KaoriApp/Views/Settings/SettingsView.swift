import SwiftUI
import HealthKit

struct SettingsView: View {
    @Environment(AppConfig.self) private var config
    @Environment(APIClient.self) private var api
    @Environment(ProfileStore.self) private var profileStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(HealthKitManager.self) private var healthKit
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
    @State private var selectedLLMMode: LLMMode = .claudeCli
    @State private var isSavingLLM = false

    var body: some View {
        @Bindable var config = config

        Form {
            // MARK: - Server connection
            Section("Server") {
                TextField("URL (e.g. http://100.x.y.z:8000)", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                SecureField("Bearer Token", text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("Test Connection")
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

                Button("Save") {
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
                    Picker("Analysis Engine", selection: $selectedLLMMode) {
                        ForEach(LLMMode.allCases) { mode in
                            VStack(alignment: .leading) {
                                Text(mode.label)
                                Text(mode.description)
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
                    Text("LLM Backend")
                } footer: {
                    Text("Which AI model to use for meal analysis")
                }
            }

            // MARK: - Workout
            if config.isConfigured {
                Section("Workout") {
                    NavigationLink {
                        ExerciseManageView()
                    } label: {
                        Label("Manage Exercises", systemImage: "dumbbell")
                    }
                }
            }

            // MARK: - Apple Health
            if healthKit.isAvailable && config.isConfigured {
                Section("Apple Health") {
                    Button {
                        Task { await importFromHealth() }
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("Import Weight from Apple Health")
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
                            Text("Import Workouts (Past Week)")
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
        .navigationTitle("Settings")
        .sheet(isPresented: $showWorkoutImport) {
            WorkoutImportView(workouts: workoutImportList, existingWorkouts: existingWorkouts)
        }
        .onAppear {
            serverURL = config.serverURL.isEmpty ? "https://REDACTED_SERVER_URL" : config.serverURL
            token = config.token.isEmpty ? "REDACTED_TOKEN" : config.token
            if let mode = profileStore.profile?.llmMode, let llm = LLMMode(rawValue: mode) {
                selectedLLMMode = llm
            }
        }
    }

    private func importFromHealth() async {
        isImporting = true
        importResult = nil

        let authorized = await healthKit.requestAuthorization()
        guard authorized else {
            importResult = "Access denied"
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
                importResult = "\(result.imported) imported, \(result.skipped) skipped"
            } else {
                importResult = "Up to date"
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
