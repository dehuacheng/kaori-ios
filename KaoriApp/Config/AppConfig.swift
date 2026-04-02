import Foundation

@Observable
class AppConfig {
    var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    var token: String {
        didSet { UserDefaults.standard.set(token, forKey: "token") }
    }

    var isConfigured: Bool {
        !serverURL.isEmpty && !token.isEmpty
    }

    var baseURL: URL? {
        URL(string: serverURL)
    }

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        self.token = UserDefaults.standard.string(forKey: "token") ?? ""
    }
}
