import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    var workoutName: String

    enum Mode: String, Codable {
        case restTimer
        case activeSet
    }

    struct ContentState: Codable, Hashable {
        var mode: Mode
        var timerEndDate: Date?
        var timerTotalSeconds: Int?
        var exerciseName: String
        var setDescription: String
        var weightRepsLabel: String
        var completedSets: Int
        var totalSets: Int
    }
}
