import Foundation
import SwiftData

struct LogSet: Codable, Hashable {
    var reps: Int
    var weight: Double
    var isWarmup: Bool = false
    var isFailure: Bool = false
    var completedAt: Date?
}

struct LogEntry: Codable, Hashable {
    var exerciseName: String
    var muscleGroup: String
    var sets: [LogSet]
}

@Model
final class WorkoutLog {
    var templateName: String
    var startedAt: Date
    var finishedAt: Date?
    var entriesData: Data

    var entries: [LogEntry] {
        get { (try? JSONDecoder().decode([LogEntry].self, from: entriesData)) ?? [] }
        set { entriesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var totalSets: Int { entries.reduce(0) { $0 + $1.sets.filter { $0.completedAt != nil }.count } }
    var durationMinutes: Int {
        guard let end = finishedAt else { return 0 }
        return Int(end.timeIntervalSince(startedAt) / 60)
    }
    var totalVolume: Double {
        entries.flatMap(\.sets)
            .filter { $0.completedAt != nil }
            .reduce(0) { $0 + $1.weight * Double($1.reps) }
    }
    var isInProgress: Bool { finishedAt == nil }

    init(templateName: String, entries: [LogEntry] = [], startedAt: Date = .now) {
        self.templateName = templateName
        self.startedAt = startedAt
        self.entriesData = (try? JSONEncoder().encode(entries)) ?? Data()
    }
}
