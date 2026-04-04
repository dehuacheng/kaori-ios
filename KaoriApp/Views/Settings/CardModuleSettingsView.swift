import SwiftUI

/// Settings view for managing card module enable/disable toggles
/// and navigating to per-card settings.
struct CardModuleSettingsView: View {
    @Environment(Localizer.self) private var L
    @Environment(CardRegistry.self) private var registry
    @Environment(CardPreferenceStore.self) private var prefStore

    var body: some View {
        List {
            Section {
                ForEach(registry.modules, id: \.cardType) { module in
                    HStack {
                        Image(systemName: module.iconName)
                            .foregroundStyle(module.accentColor)
                            .frame(width: 24)
                        Text(L.t(module.displayNameKey))

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { prefStore.isEnabled(module.cardType) },
                            set: { newValue in
                                Task { await prefStore.toggle(module.cardType, enabled: newValue) }
                            }
                        ))
                        .labelsHidden()
                    }
                }
            } header: {
                Text(L.t("settings.enabledCards"))
            } footer: {
                Text(L.t("settings.enabledCardsFooter"))
            }

            // Per-card settings for modules that have them
            let settingsModules = registry.settingsModules
            if !settingsModules.isEmpty {
                Section(L.t("settings.cardSettings")) {
                    ForEach(settingsModules, id: \.cardType) { module in
                        if let settingsView = module.settingsView() {
                            NavigationLink {
                                settingsView
                            } label: {
                                Label(L.t(module.displayNameKey), systemImage: module.iconName)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L.t("settings.cardModules"))
        .task {
            await prefStore.load()
        }
    }
}
