import SwiftUI

struct MealFeedCard: View {
    let meal: Meal
    var displayTime: String?
    @Environment(APIClient.self) private var api
    @Environment(Localizer.self) private var L

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header — colored label like Apple Health
            HStack {
                Image(systemName: mealIcon)
                    .foregroundStyle(mealColor)
                Text(L.t("mealType.\(meal.mealType ?? "snack")"))
                    .font(.subheadline.bold())
                    .foregroundStyle(mealColor)
                AnalysisStatusBadge(status: meal.analysisStatus, isEstimated: meal.isEstimated)
                Spacer()
                if let time = displayTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Photos
            let paths = meal.allPhotoPaths
            if paths.count == 1, let url = api.photoURL(for: paths[0]) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 200)
                        .overlay { ProgressView() }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 2)
            } else if paths.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(paths, id: \.self) { path in
                            if let url = api.photoURL(for: path) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay { ProgressView() }
                                }
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            // Description
            if let desc = meal.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            // Nutrition
            if let cal = meal.calories {
                HStack(spacing: 12) {
                    Text("\(cal) kcal")
                        .font(.subheadline.bold())
                    if let p = meal.proteinG {
                        Text("P:\(Int(p))g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let c = meal.carbsG {
                        Text("C:\(Int(c))g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let f = meal.fatG {
                        Text("F:\(Int(f))g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .feedCard()
    }

    private var mealIcon: String {
        switch meal.mealType {
        case "breakfast": "sunrise.fill"
        case "lunch": "sun.max.fill"
        case "dinner": "moon.fill"
        default: "leaf.fill"
        }
    }

    private var mealColor: Color {
        switch meal.mealType {
        case "breakfast": .orange
        case "lunch": .yellow
        case "dinner": .indigo
        default: .green
        }
    }
}
