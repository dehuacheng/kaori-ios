import SwiftUI

struct AgentMemoryView: View {
    @Environment(AgentStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var showAdd = false
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newCategory = "general"

    private let categories = ["general", "preference", "fact"]

    var body: some View {
        List {
            ForEach(categories, id: \.self) { category in
                let entries = store.memoryEntries.filter { $0.category == category }
                if !entries.isEmpty {
                    Section(category.capitalized) {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.key)
                                    .font(.subheadline.bold())
                                Text(entry.value)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            deleteEntries(offsets, in: entries)
                        }
                    }
                }
            }

            if store.memoryEntries.isEmpty && !store.isLoadingMemory {
                ContentUnavailableView {
                    Label(L.t("chat.noMemories"), systemImage: "brain")
                } description: {
                    Text(L.t("chat.noMemoriesHint"))
                }
            }
        }
        .navigationTitle(L.t("chat.memory"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert(L.t("chat.addMemory"), isPresented: $showAdd) {
            TextField(L.t("chat.memoryKey"), text: $newKey)
            TextField(L.t("chat.memoryValue"), text: $newValue)
            Picker(L.t("chat.memoryCategory"), selection: $newCategory) {
                ForEach(categories, id: \.self) { Text($0).tag($0) }
            }
            Button(L.t("common.save")) { saveMemory() }
            Button(L.t("common.cancel"), role: .cancel) { resetForm() }
        }
        .task {
            await store.loadMemory()
        }
    }

    private func deleteEntries(_ offsets: IndexSet, in entries: [AgentMemoryEntry]) {
        for index in offsets {
            let entry = entries[index]
            Task { try? await store.deleteMemory(key: entry.key) }
        }
    }

    private func saveMemory() {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        let value = newValue.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, !value.isEmpty else { return }
        Task {
            try? await store.upsertMemory(key: key, value: value, category: newCategory)
            resetForm()
        }
    }

    private func resetForm() {
        newKey = ""
        newValue = ""
        newCategory = "general"
    }
}
