import Foundation
import Combine
import UIKit
import ActivityKit

enum TimerPhase: String {
    case idle = "Ready"
    case work = "Work"
    case rest = "Rest"
    case done = "Done"
}

@Observable
class TimerEngine {
    var phase: TimerPhase = .idle
    var currentSet: Int = 0
    var totalSets: Int = 0
    var remainingSeconds: Int = 0
    var isRunning: Bool = false

    private(set) var restSeconds: Int = 60
    private(set) var workSeconds: Int = 0
    private(set) var presetName: String = ""

    private var phaseEndTime: Date?
    private var cancellable: AnyCancellable?
    private var foregroundObserver: Any?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()
    private var currentActivity: Activity<KaoriTimerAttributes>?

    var progress: Double {
        let total = (phase == .work) ? workSeconds : restSeconds
        guard total > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(total)
    }

    var displayTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    init() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.onForeground()
        }
    }

    deinit {
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
    }

    func configure(preset: TimerPreset) {
        reset()
        presetName = preset.name
        restSeconds = preset.restSeconds
        workSeconds = preset.workSeconds
        totalSets = preset.sets
    }

    func start() {
        guard phase == .idle || phase == .done else {
            if !isRunning { resume() }
            return
        }
        currentSet = 1
        if workSeconds > 0 {
            enterPhase(.work, seconds: workSeconds)
        } else {
            enterPhase(.rest, seconds: restSeconds)
        }
        startLiveActivity()
    }

    func pause() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
        updateLiveActivity()
    }

    func resume() {
        guard !isRunning, phase == .work || phase == .rest else { return }
        isRunning = true
        phaseEndTime = Date().addingTimeInterval(Double(remainingSeconds))
        startTicking()
        updateLiveActivity()
    }

    func reset() {
        pause()
        phase = .idle
        currentSet = 0
        remainingSeconds = 0
        phaseEndTime = nil
        endLiveActivity()
    }

    func skip() {
        guard phase == .work || phase == .rest else { return }
        advancePhase()
    }

    // MARK: - Foreground catch-up

    private func onForeground() {
        guard isRunning, phase == .work || phase == .rest else { return }
        catchUpPhases()
        if isRunning && phase != .done {
            startTicking()
        }
    }

    private func catchUpPhases() {
        guard var endTime = phaseEndTime else { return }
        while Date() >= endTime {
            cancellable?.cancel()
            switch phase {
            case .work:
                phase = .rest
                endTime = endTime.addingTimeInterval(Double(restSeconds))
                phaseEndTime = endTime
            case .rest:
                if currentSet < totalSets {
                    currentSet += 1
                    if workSeconds > 0 {
                        phase = .work
                        endTime = endTime.addingTimeInterval(Double(workSeconds))
                    } else {
                        endTime = endTime.addingTimeInterval(Double(restSeconds))
                    }
                    phaseEndTime = endTime
                } else {
                    notification.notificationOccurred(.warning)
                    phase = .done
                    isRunning = false
                    remainingSeconds = 0
                    phaseEndTime = nil
                    endLiveActivity()
                    return
                }
            default:
                return
            }
        }
        remainingSeconds = max(0, Int(ceil(endTime.timeIntervalSinceNow)))
        updateLiveActivity()
    }

    // MARK: - Internal timer

    private func enterPhase(_ newPhase: TimerPhase, seconds: Int) {
        phase = newPhase
        remainingSeconds = seconds
        isRunning = true
        phaseEndTime = Date().addingTimeInterval(Double(seconds))
        startTicking()
    }

    private func startTicking() {
        cancellable?.cancel()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard isRunning, let endTime = phaseEndTime else { return }
        let remaining = Int(ceil(endTime.timeIntervalSinceNow))
        remainingSeconds = max(0, remaining)

        if remainingSeconds > 0 && remainingSeconds <= 3 {
            impactLight.impactOccurred()
        }

        if remainingSeconds <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        cancellable?.cancel()
        isRunning = false

        switch phase {
        case .work:
            notification.notificationOccurred(.success)
            enterPhase(.rest, seconds: restSeconds)
            updateLiveActivity()

        case .rest:
            if currentSet < totalSets {
                notification.notificationOccurred(.success)
                currentSet += 1
                if workSeconds > 0 {
                    enterPhase(.work, seconds: workSeconds)
                } else {
                    enterPhase(.rest, seconds: restSeconds)
                }
                updateLiveActivity()
            } else {
                notification.notificationOccurred(.warning)
                phase = .done
                remainingSeconds = 0
                endLiveActivity()
            }

        default:
            break
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = KaoriTimerAttributes(presetName: presetName)
        let state = makeContentState()
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity not available
        }
    }

    private func updateLiveActivity() {
        guard let currentActivity else { return }
        let state = makeContentState()
        Task {
            await currentActivity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }

    private func makeContentState() -> KaoriTimerAttributes.ContentState {
        KaoriTimerAttributes.ContentState(
            phase: phase.rawValue,
            currentSet: currentSet,
            totalSets: totalSets,
            endTime: phaseEndTime ?? Date(),
            isPaused: !isRunning,
            remainingSeconds: remainingSeconds
        )
    }
}
