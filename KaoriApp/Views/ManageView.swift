import SwiftUI

struct MoreView: View {
    @Environment(Localizer.self) private var L

    var body: some View {
        NavigationStack {
            List {
                Section(L.t("more.data")) {
                    NavigationLink {
                        MealListView()
                    } label: {
                        Label(L.t("tab.meals"), systemImage: "fork.knife")
                    }
                    NavigationLink {
                        WeightView()
                    } label: {
                        Label(L.t("tab.weight"), systemImage: "scalemass")
                    }
                    NavigationLink {
                        WorkoutListView()
                    } label: {
                        Label(L.t("tab.gym"), systemImage: "dumbbell")
                    }
                }

                Section(L.t("more.tools")) {
                    NavigationLink {
                        TimerView()
                    } label: {
                        Label(L.t("timer.title"), systemImage: "timer")
                    }
                }

                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label(L.t("profile.title"), systemImage: "person.crop.circle")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(L.t("settings.title"), systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle(L.t("tab.more"))
        }
    }
}
