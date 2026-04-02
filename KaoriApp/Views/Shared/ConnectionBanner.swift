import SwiftUI

struct ConnectionBanner: View {
    let isConnected: Bool
    @Environment(Localizer.self) private var L

    var body: some View {
        if !isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text(L.t("shared.serverUnreachable"))
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.red)
        }
    }
}
