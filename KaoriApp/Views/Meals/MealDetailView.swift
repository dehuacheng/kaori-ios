import SwiftUI

struct MealDetailView: View {
    let mealId: Int
    @Environment(MealStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api
    @Environment(\.dismiss) private var dismiss

    @State private var meal: Meal?
    @State private var analyses: [Analysis] = []
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var isReprocessing = false
    @State private var error: String?

    private var isPending: Bool {
        meal?.analysisStatus == "pending" || meal?.analysisStatus == "analyzing"
    }

    var body: some View {
        Group {
            if let meal {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Photos
                        let paths = meal.allPhotoPaths
                        if !paths.isEmpty {
                            if paths.count == 1, let url = api.photoURL(for: paths[0]) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    ProgressView()
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(paths, id: \.self) { path in
                                            if let url = api.photoURL(for: path) {
                                                AsyncImage(url: url) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.white.opacity(0.05))
                                                        .overlay { ProgressView() }
                                                }
                                                .frame(width: 240, height: 240)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Header
                        HStack {
                            Text(L.t("mealType.\(meal.mealType ?? "snack")"))
                                .font(.title2.bold())
                            if let state = mealDetailState {
                    CardStateBadge(state)
                }
                            if let confidence = meal.confidence {
                                Text(confidence)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.gray.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }

                        if let desc = meal.description, !desc.isEmpty {
                            Text(desc)
                                .font(.body)
                        }

                        if let notes = meal.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let photoDesc = meal.photoDescription {
                            DisclosureGroup(L.t("photo.description")) {
                                Text(photoDesc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }

                        // Nutrition
                        if isPending {
                            FullViewLoading(message: L.t("meal.analyzingNutrition"))
                        } else {
                            nutritionCard(meal)
                        }

                        // Actions
                        actionButtons

                        // Analysis history
                        if !analyses.isEmpty {
                            analysisHistory
                        }
                    }
                    .padding()
                }
            } else {
                FullViewLoading(message: L.t("shared.loading"))
            }
        }
        .navigationTitle(meal?.date ?? "Meal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(L.t("common.edit"), systemImage: "pencil") { showEdit = true }
                    Button(L.t("meal.reanalyze"), systemImage: "sparkles") {
                        Task { await reprocess() }
                    }
                    .disabled(isReprocessing)
                    Divider()
                    Button(L.t("common.delete"), systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(L.t("meal.deleteMeal"), isPresented: $showDeleteConfirm) {
            Button(L.t("common.delete"), role: .destructive) {
                Task { await deleteMeal() }
            }
            Button(L.t("common.cancel"), role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            if let meal {
                MealEditView(meal: meal) {
                    Task { await loadMeal() }
                }
            }
        }
        .task {
            await loadMeal()
        }
        .task(id: isPending) {
            guard isPending else { return }
            // Poll for analysis completion
            for _ in 0..<60 {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                if let updated = try? await store.getMeal(mealId) {
                    self.meal = updated
                    if updated.analysisStatus == "done" || updated.analysisStatus == "failed" {
                        break
                    }
                }
            }
        }
    }

    private func nutritionCard(_ meal: Meal) -> some View {
        VStack(spacing: 12) {
            HStack {
                NutritionStat(label: L.t("dashboard.calories"), value: "\(meal.calories ?? 0)", unit: "kcal")
                Divider().frame(height: 40)
                NutritionStat(label: L.t("dashboard.protein"), value: String(format: "%.0f", meal.proteinG ?? 0), unit: "g")
                Divider().frame(height: 40)
                NutritionStat(label: L.t("dashboard.carbs"), value: String(format: "%.0f", meal.carbsG ?? 0), unit: "g")
                Divider().frame(height: 40)
                NutritionStat(label: L.t("dashboard.fat"), value: String(format: "%.0f", meal.fatG ?? 0), unit: "g")
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await reprocess() }
            } label: {
                Label(L.t("meal.reanalyze"), systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isReprocessing || isPending)
        }
    }

    private var analysisHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.t("meal.analysisHistory"))
                .font(.headline)

            ForEach(analyses) { a in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(a.calories ?? 0) kcal")
                                .font(.subheadline.bold())
                            if a.isActive == 1 {
                                Text(L.t("meal.active"))
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(.green.opacity(0.2))
                                    .foregroundStyle(.green)
                                    .clipShape(Capsule())
                            }
                        }
                        Text("\(a.model ?? a.llmBackend ?? "unknown") - \(a.createdAt ?? "")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if a.isActive == 0 {
                        Button(L.t("meal.activate")) {
                            Task {
                                try? await store.activateAnalysis(mealId: mealId, analysisId: a.id)
                                await loadMeal()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 4)
                if a.id != analyses.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var mealDetailState: CardState? {
        switch meal?.analysisStatus {
        case "pending", "analyzing": .processing
        case "failed": .failed
        default:
            if meal?.isEstimated == 1 { .ai }
            else if meal?.isEstimated == 0 { .manual }
            else { nil }
        }
    }

    private func loadMeal() async {
        meal = try? await store.getMeal(mealId)
        if let response = try? await store.getAnalyses(mealId) {
            analyses = response.analyses
        }
    }

    private func reprocess() async {
        isReprocessing = true
        _ = try? await store.reprocess(mealId)
        await loadMeal()
        isReprocessing = false
    }

    private func deleteMeal() async {
        _ = try? await store.deleteMeal(mealId)
        dismiss()
    }
}

private struct NutritionStat: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text("\(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
