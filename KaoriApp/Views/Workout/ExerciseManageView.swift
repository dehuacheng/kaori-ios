import SwiftUI
import PhotosUI

struct ExerciseManageView: View {
    @Environment(WorkoutStore.self) private var store

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
            Section("Identify by Photo") {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if isIdentifying {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Identifying...")
                        }
                    } else {
                        Label("Take or Choose Photo", systemImage: "camera")
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
            Section("Create Custom") {
                if showCreate {
                    TextField("Exercise Name", text: $newName)
                    Picker("Category", selection: $newCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized).tag(cat)
                        }
                    }
                    Button("Save") {
                        Task { await createExercise() }
                    }
                    .disabled(newName.isEmpty)
                } else {
                    Button {
                        showCreate = true
                    } label: {
                        Label("New Exercise Type", systemImage: "plus.circle")
                    }
                }
            }

            // All exercise types
            Section("Exercise Types") {
                ForEach(filtered) { et in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(et.name)
                                .font(.subheadline)
                            if let cat = et.category {
                                Text(cat.capitalized)
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
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter exercises")
        .navigationTitle("Manage Exercises")
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
            identifyResult = "Failed to load photo"
            return
        }
        do {
            let result = try await store.identifyExercise(photo: data, hint: nil)
            identifyResult = "Identified: \(result.name)"
            await reload()
        } catch {
            identifyResult = "Identification failed"
        }
    }
}
