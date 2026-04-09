import SwiftUI

struct MoreView: View {
    @Environment(Localizer.self) private var L
    @Environment(CardRegistry.self) private var registry
    @Environment(CardPreferenceStore.self) private var prefStore

    var body: some View {
        NavigationStack {
            List {
                // Data section — driven by CardRegistry
                Section(L.t("more.data")) {
                    ForEach(registry.dataModules, id: \.cardType) { module in
                        if prefStore.isEnabled(module.cardType),
                           let dataView = module.dataListView() {
                            NavigationLink {
                                dataView
                            } label: {
                                Label(L.t(module.displayNameKey), systemImage: module.iconName)
                            }
                        }
                    }
                }

                Section(L.t("more.tools")) {
                    NavigationLink {
                        TimerView()
                    } label: {
                        Label(L.t("timer.title"), systemImage: "timer")
                    }
                    NavigationLink {
                        DocumentListView()
                    } label: {
                        Label(L.t("document.title"), systemImage: "doc.text.magnifyingglass")
                    }
                }

                Section {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Label(L.t("profile.title"), systemImage: "person.crop.circle")
                    }
                    NavigationLink {
                        FinanceAccountListView()
                    } label: {
                        Label(L.t("finance.title"), systemImage: "chart.pie")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(L.t("settings.title"), systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle(L.t("tab.more"))
            .task {
                await prefStore.load()
            }
        }
    }
}
