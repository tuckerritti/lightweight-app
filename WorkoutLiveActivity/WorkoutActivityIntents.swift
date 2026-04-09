import AppIntents

struct SkipRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Rest Timer"
    static var description: IntentDescription = "Skip the current rest timer"

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await MainActor.run {
            LiveActivityManager.shared.handleSkipTimer()
        }
        #endif
        return .result()
    }
}

struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var description: IntentDescription = "Complete the current set"

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await MainActor.run {
            LiveActivityManager.shared.handleCompleteSet()
        }
        #endif
        return .result()
    }
}
