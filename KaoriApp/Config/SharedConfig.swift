import Foundation

struct SharedConfig {
    static let suiteName = "group.com.dehuacheng.kaori"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var serverURL: String {
        get { sharedDefaults?.string(forKey: "serverURL") ?? "" }
        set { sharedDefaults?.set(newValue, forKey: "serverURL") }
    }

    static var token: String {
        get { sharedDefaults?.string(forKey: "token") ?? "" }
        set { sharedDefaults?.set(newValue, forKey: "token") }
    }

    static var appLanguage: String {
        get { sharedDefaults?.string(forKey: "appLanguage") ?? "en" }
        set { sharedDefaults?.set(newValue, forKey: "appLanguage") }
    }

    static var isConfigured: Bool {
        !serverURL.isEmpty && !token.isEmpty
    }

    static var baseURL: URL? {
        URL(string: serverURL)
    }
}
