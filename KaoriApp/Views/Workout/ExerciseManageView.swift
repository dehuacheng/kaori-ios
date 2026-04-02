import SwiftUI
import PhotosUI

struct ExerciseManageView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(Localizer.self) private var L

    @State private var allTypes: [ExerciseType] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @State private var newName = ""
    @State private var newCategory = "other"
    @State private var searchText = ""

    // Photo identification
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isIdentifying = false
    @State private var identifyResult: String?

    private let categories = ["chest", "back", "legs", "shoulders", "arms", "core", "cardio", "full_body", "other"]

    private var filtered: [ExerciseType] {
        if searchText.isEmpty { return allTypes }
        return allTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            // Photo identify section
            Section(L.t("exercise.identifyByPhoto")) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if isIdentifying {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text(L.t("exercise.identifying"))
                        }
                    } else {
                        Label(L.t("exercise.takeOrChoosePhoto"), systemImage: "camera")
                    }
                }
                .disabled(isIdentifying)

                if let identifyResult {
                    Text(identifyResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Create custom
            Section(L.t("exercise.createCustom")) {
                if showCreate {
                    TextField(L.t("exercise.exerciseName"), text: $newName)
                    Picker(L.t("exercise.category"), selection: $newCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(L.t("exerciseCategory.\(cat)")).tag(cat)
                        }
                    }
                    Button(L.t("common.save")) {
                        Task { await createExercise() }
                    }
                    .disabled(newName.isEmpty)
                } else {
                    Button {
                        showCreate = true
                    } label: {
                        Label(L.t("exercise.newExerciseType"), systemImage: "plus.circle")
                    }
                }
            }

            // All exercise types
            Section(L.t("exercise.exerciseTypes")) {
                ForEach(filtered) { et in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(et.name)
                                .font(.subheadline)
                            if let cat = et.category {
                                Text(L.t("exerciseCategory.\(cat)"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { (et.isEnabled ?? 1) == 1 },
                            set: { enabled in
                                Task {
                                    if enabled {
                                        try? await store.enableExerciseType(et.id)
                                    } else {
                                        try? await store.disableExerciseType(et.id)
                                    }
                                    await reload()
                                }
                            }
                        ))
                        .labelsHidden()
                    }
                    .swipeActions {
                        if et.isStandard != 1 {
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteExerciseType(et.id)
                                    await reload()
                                }
                            } label: {
                                Label(L.t("common.delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: L.t("exercise.filterExercises"))
        .navigationTitle(L.t("exercise.manageExercises"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await reload() }
        .onChange(of: selectedPhoto) {
            guard let selectedPhoto else { return }
            Task { await identifyFromPhoto(selectedPhoto) }
        }
    }

    @MainActor
    private func reload() async {
        isLoading = true
        allTypes = (try? await store.loadAllExerciseTypes()) ?? []
        isLoading = false
    }

    private func createExercise() async {
        _ = try? await store.createExerciseType(name: newName, category: newCategory, notes: nil)
        newName = ""
        showCreate = false
        await reload()
    }

    @MainActor
    private func identifyFromPhoto(_ item: PhotosPickerItem) async {
        isIdentifying = true
        identifyResult = nil
        defer {
            isIdentifying = false
            selectedPhoto = nil
        }
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            identifyResult = L.t("exercise.failedToLoadPhoto")
            return
        }
        do {
            let result = try await store.identifyExercise(photo: data, hint: nil)
            identifyResult = L.t("exercise.identified", result.name)
            await reload()
        } catch {
            identifyResult = L.t("exercise.identificationFailed")
        }
    }
}
