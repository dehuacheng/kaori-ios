import SwiftUI

struct DashboardView: View {
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api
    @Environment(MealStore.self) private var mealStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(WorkoutStore.self) private var workoutStore
    @Environment(NotificationSettings.self) private var notificationSettings

    // Summary state
    @State private var dailySummaryText: String?
    @State private var weeklySummaryText: String?
    @State private var isGeneratingDaily = false
    @State private var isGeneratingWeekly = false
    @State private var dailySectionsCollapsed = false
    @State private var weeklySectionsCollapsed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // On weekly summary day: show weekly instead of daily
                    // Other days: show daily only
                    if isWeeklySummaryDay {
                        if weeklySummaryText != nil || shouldShowWeeklySummary {
                            SwipeActionView(
                                icon: "arrow.clockwise",
                                color: .blue,
                                action: { Task { await generateWeeklySummary() } }
                            ) {
                                weeklySummaryCard
                            }
                        }
                    } else {
                        if dailySummaryText != nil || shouldShowDailySummary {
                            SwipeActionView(
                                icon: "arrow.clockwise",
                                color: .blue,
                                action: { Task { await generateDailySummary() } }
                            ) {
                                dailySummaryCard
                            }
                        }
                    }

                    // Calorie progress
                    if let profile = profileStore.profile,
                       let target = profile.targetCalories,
                       let totals = mealStore.totals {
                        calorieCard(current: Double(totals.totalCal), target: Double(target))
                    }

                    // Macros
                    if let totals = mealStore.totals, let profile = profileStore.profile {
                        macroCard(totals: totals, profile: profile)
                    }

                    // Today's workout
                    workoutCard

                    // Recent meals
                    recentMealsCard

                    // Weight
                    weightCard
                }
                .padding()
            }
            .navigationTitle(L.t("dashboard.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.crop.circle")
                        }
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .refreshable {
                await loadAll()
            }
            .task {
                await loadAll()
            }
        }
    }

    // MARK: - Daily Summary Card

    private var shouldShowDailySummary: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= notificationSettings.dailySummaryHour
    }

    private var isWeeklySummaryDay: Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == notificationSettings.weeklySummaryWeekday
    }

    private var shouldShowWeeklySummary: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return isWeeklySummaryDay && hour >= notificationSettings.weeklySummaryHour
    }

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var dailySummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text(L.t("summary.dailyTitle"))
                    .font(.headline)
                Spacer()
                if isGeneratingDaily {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if isGeneratingDaily && dailySummaryText == nil {
                Text(L.t("summary.generating"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else if let text = dailySummaryText {
                SummarySectionsView(markdown: text, allCollapsed: $dailySectionsCollapsed)
            } else {
                Button(L.t("summary.generate")) {
                    Task { await generateDailySummary() }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2) {
            withAnimation { dailySectionsCollapsed.toggle() }
        }
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
                Text(L.t("summary.weeklyTitle"))
                    .font(.headline)
                Spacer()
                if isGeneratingWeekly {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if isGeneratingWeekly && weeklySummaryText == nil {
                Text(L.t("summary.generating"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else if let text = weeklySummaryText {
                SummarySectionsView(markdown: text, allCollapsed: $weeklySectionsCollapsed)
            } else {
                Button(L.t("summary.generate")) {
                    Task { await generateWeeklySummary() }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(count: 2) {
            withAnimation { weeklySectionsCollapsed.toggle() }
        }
    }

    // MARK: - Summary Loading

    private func loadSummaries() async {
        if isWeeklySummaryDay {
            // On weekly day, load weekly summary
            do {
                let result: SummaryDetail = try await api.get(
                    "/api/summary/weekly-detail",
                    query: ["date": todayString]
                )
                weeklySummaryText = result.summaryText
            } catch {}
        } else {
            // Other days, load daily summary
            do {
                let result: SummaryDetail = try await api.get(
                    "/api/summary/daily-detail",
                    query: ["date": todayString]
                )
                dailySummaryText = result.summaryText
            } catch {}
        }
    }

    private func generateDailySummary() async {
        isGeneratingDaily = true
        defer { isGeneratingDaily = false }

        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"

        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/daily-detail",
                query: ["language": lang, "date": todayString]
            )
            dailySummaryText = result.summaryText
        } catch {
            dailySummaryText = "Error: \(error.localizedDescription)"
        }
    }

    private func generateWeeklySummary() async {
        isGeneratingWeekly = true
        defer { isGeneratingWeekly = false }

        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"

        do {
            let result: SummaryDetail = try await api.post(
                "/api/summary/weekly-detail",
                query: ["language": lang]
            )
            weeklySummaryText = result.summaryText
        } catch {
            weeklySummaryText = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Existing Cards

    private func calorieCard(current: Double, target: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.t("dashboard.today"))
                .font(.headline)
            NutritionBar(
                label: L.t("dashboard.calories"),
                current: current,
                target: target,
                unit: " kcal",
                color: .blue
            )
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func macroCard(totals: NutritionTotals, profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NutritionBar(
                label: L.t("dashboard.protein"),
                current: totals.totalProtein,
                target: Double(profile.targetProteinG ?? 0),
                unit: "g",
                color: .orange
            )
            NutritionBar(
                label: L.t("dashboard.carbs"),
                current: totals.totalCarbs,
                target: Double(profile.targetCarbsG ?? 0),
                unit: "g",
                color: .green
            )
            NutritionBar(
                label: L.t("dashboard.fat"),
                current: totals.totalFat,
                target: 0,
                unit: "g",
                color: .purple
            )
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var workoutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L.t("dashboard.workout"))
                    .font(.headline)
                Spacer()
                NavigationLink(L.t("dashboard.goToGym")) {
                    WorkoutListView()
                }
                .font(.caption)
            }

            if workoutStore.workouts.isEmpty {
                Text(L.t("dashboard.noWorkoutsToday"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(workoutStore.workouts) { workout in
                    let meta = WorkoutStore.importedMeta(forWorkoutId: workout.id)
                    HStack {
                        Image(systemName: activityIconName(workout.activityType))
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(meta != nil ? L.t("activity.\(meta!.activityType)") : workoutDisplayLabel(workout))
                                .font(.subheadline.bold())

                            HStack(spacing: 12) {
                                if let dur = workout.durationMinutes, dur > 0 {
                                    Label("\(Int(dur)) min", systemImage: "clock")
                                }
                                if let cal = workout.caloriesBurned ?? meta?.caloriesBurned, cal > 0 {
                                    Label("\(Int(cal)) kcal", systemImage: "flame")
                                }
                                if let dist = meta?.distanceMeters, dist > 0 {
                                    Label(dist >= 1000 ? String(format: "%.1f km", dist / 1000) : String(format: "%.0f m", dist), systemImage: "location")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let summary = workout.summary, !summary.isEmpty {
                                Text(summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recentMealsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L.t("dashboard.meals"))
                    .font(.headline)
                Spacer()
                NavigationLink(L.t("dashboard.seeAll")) {
                    MealListView()
                }
                .font(.caption)
            }

            if mealStore.meals.isEmpty {
                Text(L.t("dashboard.noMealsToday"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(mealStore.meals.prefix(3)) { meal in
                    NavigationLink(destination: MealDetailView(mealId: meal.id)) {
                        MealRowView(meal: meal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L.t("dashboard.weight"))
                    .font(.headline)
                Spacer()
                NavigationLink(L.t("dashboard.details")) {
                    WeightView()
                }
                .font(.caption)
            }

            HStack(spacing: 24) {
                if let latest = weightStore.latest {
                    VStack {
                        Text(String(format: "%.1f", latest))
                            .font(.title2.bold())
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let avg = weightStore.avg7d {
                    VStack {
                        Text(String(format: "%.1f", avg))
                            .font(.title3)
                        Text(L.t("dashboard.7dAvg"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let delta = weightStore.deltaWeek {
                    VStack {
                        Text(String(format: "%+.1f", delta))
                            .font(.title3)
                            .foregroundStyle(delta < 0 ? .green : delta > 0 ? .red : .primary)
                        Text(L.t("dashboard.week"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if weightStore.weights.count >= 2 {
                WeightMiniChartView(weights: weightStore.weights)
                    .frame(height: 120)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func workoutDisplayLabel(_ workout: Workout) -> String {
        if let summary = workout.summary, !summary.isEmpty {
            return summary
        }
        let name = L.t("activity.\(workout.activityType ?? "workout")")
        if let count = workout.exerciseCount, count > 0 {
            return "\(name) · \(L.t("workout.exerciseCount", count))"
        }
        return name
    }

    private func loadAll() async {
        mealStore.currentDate = MealStore.todayString()
        workoutStore.currentDate = WorkoutStore.todayString()
        async let m: () = mealStore.loadMeals()
        async let w: () = weightStore.load()
        async let p: () = profileStore.load()
        async let g: () = workoutStore.loadWorkouts()
        async let s: () = loadSummaries()
        _ = await (m, w, p, g, s)
    }
}
