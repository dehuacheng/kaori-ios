import SwiftUI

struct LockScreenView: View {
    @Environment(AppLockManager.self) private var appLockManager

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Kaori")
                    .font(.title.bold())

                Spacer()

                Button {
                    Task { await appLockManager.authenticate() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: appLockManager.biometrySystemImage)
                        Text("Unlock")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .task {
            await appLockManager.authenticate()
        }
    }
}
