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
