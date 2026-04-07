import Foundation

enum ExerciseType: String, Codable, Sendable, CaseIterable {
    case weightReps
    case timed
    case timedDistance
}

struct Workout: Codable, Sendable, Hashable {
    var name: String
    var exercises: [WorkoutExercise]
    var insight: String?

    var totalSets: Int { exercises.reduce(0) { $0 + $1.sets.filter { !$0.isWarmup }.count } }
    var estimatedMinutes: Int {
        let totalRest = exercises.flatMap(\.sets).reduce(0) { $0 + $1.restSeconds }
        let workTime = exercises.flatMap(\.sets).count * 45 // ~45s per set
        return (totalRest + workTime) / 60
    }
}

struct WorkoutExercise: Codable, Sendable, Hashable {
    var name: String
    var muscleGroup: String
    var exerciseType: ExerciseType
    var targetMuscles: [TargetMuscle]
    var sets: [WorkoutSet]

    init(name: String, muscleGroup: String, exerciseType: ExerciseType = .weightReps, targetMuscles: [TargetMuscle] = [], sets: [WorkoutSet]) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.exerciseType = exerciseType
        self.targetMuscles = targetMuscles
        self.sets = sets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawName = try container.decode(String.self, forKey: .name)
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = trimmedName.isEmpty ? "Unknown Exercise" : trimmedName
        let rawGroup = try container.decode(String.self, forKey: .muscleGroup)
        let trimmedGroup = rawGroup.trimmingCharacters(in: .whitespacesAndNewlines)
        muscleGroup = trimmedGroup.isEmpty ? "Other" : trimmedGroup
        exerciseType = try container.decodeIfPresent(ExerciseType.self, forKey: .exerciseType) ?? .weightReps
        targetMuscles = try container.decodeIfPresent([TargetMuscle].self, forKey: .targetMuscles) ?? []
        sets = try container.decode([WorkoutSet].self, forKey: .sets)
    }
}

struct WorkoutSet: Codable, Sendable, Hashable {
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var targetRpe: Int?
    var isWarmup: Bool
    var durationSeconds: Int?
    var distanceMeters: Double?

    init(reps: Int = 0, weight: Double = 0, restSeconds: Int = 90, targetRpe: Int? = nil, isWarmup: Bool = false, durationSeconds: Int? = nil, distanceMeters: Double? = nil) {
        self.reps = reps
        self.weight = weight
        self.restSeconds = restSeconds
        self.targetRpe = targetRpe
        self.isWarmup = isWarmup
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reps = max(0, min(100, try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0))
        weight = max(0, min(2000, try container.decodeIfPresent(Double.self, forKey: .weight) ?? 0))
        restSeconds = max(10, min(600, try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 90))
        targetRpe = try container.decodeIfPresent(Int.self, forKey: .targetRpe).map { max(1, min(10, $0)) }
        isWarmup = try container.decodeIfPresent(Bool.self, forKey: .isWarmup) ?? false
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds).map { max(1, min(7200, $0)) }
        distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters).map { max(0, min(100000, $0)) }
    }
}