import SwiftUI

struct ConnectionBanner: View {
    let isConnected: Bool

    var body: some View {
        if !isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Server unreachable")
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
