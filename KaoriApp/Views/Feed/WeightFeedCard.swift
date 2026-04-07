import SwiftUI

struct WeightFeedCard: View {
    let entry: WeightEntry
    var displayTime: String?
    @Environment(Localizer.self) private var L
    @Environment(ProfileStore.self) private var profileStore
    @Environment(WeightStore.self) private var weightStore

    private var wu: WeightUnit { profileStore.profile?.bodyWeightUnit ?? .kg }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(.cyan)
                Text(L.t("card.weight"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.cyan)
                Spacer()
                if let time = displayTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Text(UnitConverter.formatBodyWeight(entry.weightKg, unit: wu))
                    .font(.title2.bold())

                if let avg = weightStore.avg7d {
                    let delta = entry.weightKg - avg
                    Text(L.t("weight.deltaVsAvg", UnitConverter.formatWeightDelta(delta, unit: wu)))
                        .font(.caption)
                        .foregroundStyle(delta < 0 ? .green : delta > 0 ? .red : .secondary)
                }
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .feedCard()
    }
}
