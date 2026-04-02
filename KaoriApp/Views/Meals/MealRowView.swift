import SwiftUI

struct MealRowView: View {
    let meal: Meal
    @Environment(APIClient.self) private var api
    @Environment(Localizer.self) private var L

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let path = meal.photoPath, let url = api.photoURL(for: path) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(L.t("mealType.\(meal.mealType ?? "snack")"))
                        .font(.subheadline.bold())
                    AnalysisStatusBadge(status: meal.analysisStatus, isEstimated: meal.isEstimated)
                }
                if let desc = meal.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Nutrition
            VStack(alignment: .trailing, spacing: 2) {
                if meal.analysisStatus == "pending" || meal.analysisStatus == "analyzing" {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let cal = meal.calories {
                    Text("\(cal) kcal")
                        .font(.subheadline.bold())
                    if let p = meal.proteinG {
                        Text("\(L.t("meal.p")):\(Int(p))g")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
