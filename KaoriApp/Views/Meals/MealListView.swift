import SwiftUI

struct MealListView: View {
    @Environment(MealStore.self) private var store
    @State private var showCreate = false

    var body: some View {
        @Bindable var store = store

        List {
            // Daily totals
            if let totals = store.totals {
                Section {
                    HStack {
                        StatPill(label: "Cal", value: "\(totals.totalCal)")
                        StatPill(label: "P", value: "\(Int(totals.totalProtein))g")
                        StatPill(label: "C", value: "\(Int(totals.totalCarbs))g")
                        StatPill(label: "F", value: "\(Int(totals.totalFat))g")
                    }
                }
            }

            // Meals
            Section {
                if store.meals.isEmpty && !store.isLoading {
                    Text("No meals logged")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.meals) { meal in
                        NavigationLink(destination: MealDetailView(mealId: meal.id)) {
                            MealRowView(meal: meal)
                        }
                    }
                }
            }
        }
        .navigationTitle(store.currentDateDisplay)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
                    Button {
                        store.navigateDay(offset: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        store.navigateDay(offset: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    if !store.isToday {
                        Button("Today") {
                            store.currentDate = MealStore.todayString()
                        }
                        .font(.caption)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await store.loadMeals()
        }
        .onChange(of: store.currentDate) {
            Task { await store.loadMeals() }
        }
        .task {
            await store.loadMeals()
        }
        .sheet(isPresented: $showCreate, onDismiss: {
            Task { await store.loadMeals() }
        }) {
            MealCreateView()
        }
        .task(id: store.hasPendingAnalysis) {
            // Poll every 3s while any meal has a pending analysis
            guard store.hasPendingAnalysis else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await store.loadMeals()
                if !store.hasPendingAnalysis { break }
            }
        }
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
