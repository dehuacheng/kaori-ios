import Foundation

@Observable
class Localizer {
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            loadStrings()
        }
    }

    private(set) var strings: [String: String] = [:]

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.language = AppLanguage(rawValue: saved) ?? .english
        loadStrings()
    }

    func t(_ key: String, _ args: CVarArg...) -> String {
        let template = strings[key] ?? key
        return args.isEmpty ? template : String(format: template, arguments: args)
    }

    /// Static lookup for non-view contexts (notifications, background tasks).
    /// Reads the current language from UserDefaults and loads the JSON file.
    static func localized(_ key: String) -> String {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = AppLanguage(rawValue: saved) ?? .english
        guard let url = Bundle.main.url(forResource: lang.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return key }
        return dict[key] ?? key
    }

    private func loadStrings() {
        guard let url = Bundle.main.url(forResource: language.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            strings = [:]
            return
        }
        strings = dict
    }
}
