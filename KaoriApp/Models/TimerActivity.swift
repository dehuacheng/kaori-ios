import ActivityKit
import Foundation

struct KaoriTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var currentSet: Int
        var totalSets: Int
        var endTime: Date
        var isPaused: Bool
        var remainingSeconds: Int
    }

    var presetName: String
}
