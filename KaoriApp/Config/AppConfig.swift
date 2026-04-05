import Foundation

@Observable
class AppConfig {
    var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
            SharedConfig.serverURL = serverURL
        }
    }
    var token: String {
        didSet {
            UserDefaults.standard.set(token, forKey: "token")
            SharedConfig.token = token
        }
    }

    var isConfigured: Bool {
        !serverURL.isEmpty && !token.isEmpty
    }

    var baseURL: URL? {
        URL(string: serverURL)
    }

    /// Defaults loaded from optional bundled defaults.json (gitignored).
    static let bundledDefaults: [String: String] = {
        guard let url = Bundle.main.url(forResource: "defaults", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }()

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        self.token = UserDefaults.standard.string(forKey: "token") ?? ""
        // Migrate to shared suite for Share Extension access
        if !serverURL.isEmpty { SharedConfig.serverURL = serverURL }
        if !token.isEmpty { SharedConfig.token = token }
    }
}
