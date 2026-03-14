import Foundation
import SwiftData

struct TemplateSet: Codable, Hashable {
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var isWarmup: Bool = false
}

struct TemplateExercise: Codable, Hashable {
    var name: String
    var muscleGroup: String
    var sets: [TemplateSet]
}

@Model
final class WorkoutTemplate {
    var name: String
    var exercisesData: Data

    var exercises: [TemplateExercise] {
        get { (try? JSONDecoder().decode([TemplateExercise].self, from: exercisesData)) ?? [] }
        set { exercisesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.count } }
    var estimatedMinutes: Int { totalSets * 3 }

    init(name: String, exercises: [TemplateExercise] = []) {
        self.name = name
        self.exercisesData = (try? JSONEncoder().encode(exercises)) ?? Data()
    }
}
