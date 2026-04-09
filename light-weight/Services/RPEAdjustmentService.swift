import Foundation
import os

private let logger = Logger(subsystem: "com.light-weight", category: "RPEAdjustment")

struct RPEAdjustmentService {

    /// Adjusts the remaining planned sets for a single exercise based on RPE data.
    /// `completedExercise` provides the progress for the exercise being adjusted.
    /// `fatigueContext` optionally provides a just-finished exercise for fatigue transfer (last-set case).
    /// Returns adjusted planned sets, or nil if the call fails.
    static func adjustExerciseSets(
        apiKey: String,
        exercise: WorkoutExercise,
        completedExercise: LogEntry,
        fatigueContext: LogEntry? = nil,
        onCost: @Sendable @escaping (TokenCost) -> Void = { _ in }
    ) async -> [WorkoutSet]? {
        let api = ClaudeAPIService(apiKey: apiKey, onCost: onCost)
        let completedSetCount = completedExercise.sets.filter { $0.completedAt != nil }.count
        logger.info(
            "rpe_adjustment start exercise=\(exercise.name, privacy: .public) completedSets=\(completedSetCount, privacy: .public)"
        )

        let fatigueNote = fatigueContext.map { ctx in
            """

            The user just finished this exercise before starting \(exercise.name). \
            Consider fatigue transfer when adjusting:
            \(ctx.exerciseName) (\(ctx.muscleGroup)):
            \([ctx].formattedProgress())
            """
        } ?? ""

        let systemPrompt = """
        You are an expert strength coach making real-time adjustments to a workout in progress.

        The user just logged a set with their RPE (rate of perceived exertion, 1-10 scale). \
        Adjust ONLY the remaining planned sets for this exercise.

        Consider:
        - If actual RPE is higher than target, the weight is too heavy, reps are too high, or rest is too short
        - If actual RPE is lower than target, the weight is too light, reps are too low, or rest is too long
        - Cumulative fatigue — RPE naturally climbs across sets, but a big jump signals a problem
        - Adjust weight, reps, rest, and targetRpe for remaining planned sets as needed

        Respond with ONLY a JSON array of the adjusted PLANNED sets (do not include completed sets). Schema:
        [
          { "reps": 8, "weight": 135, "restSeconds": 90, "targetRpe": 8, "isWarmup": false }
        ]

        Exercise type: "\(exercise.exerciseType.rawValue)".
        For timed exercises, adjust durationSeconds instead of reps. Keep exerciseType unchanged.

        Rules:
        - Preserve the isWarmup flag on all sets
        - Weight changes should use real plate increments (2.5 lb minimum)
        - Rest range: 30-300 seconds
        - Reps minimum: 1 (for weightReps), durationSeconds minimum: 5 (for timed)
        - If all RPEs are on target, return the sets unchanged
        - Be conservative — small adjustments are better than dramatic ones
        """

        let userMessage = """
        Exercise: \(exercise.name) (\(exercise.muscleGroup))

        Progress:
        \([completedExercise].formattedProgress())

        Planned sets to adjust:
        \(exercise.sets.dropFirst(completedSetCount).enumerated().map { i, s in
            "Set \(completedSetCount + i + 1): \(s.weight)lbs x \(s.reps) @targetRPE \(s.targetRpe ?? 0) rest \(s.restSeconds)s"
        }.joined(separator: "\n"))
        \(fatigueNote)
        """

        do {
            let response = try await api.send(
                operation: "adjust_rpe_exercise",
                systemPrompt: systemPrompt,
                userMessage: userMessage
            )
            let jsonString = JSONExtractor.extractArray(from: response)
            guard let data = jsonString.data(using: .utf8) else { return nil }
            let adjustedSets = try JSONDecoder().decode([WorkoutSet].self, from: data)
            logger.info(
                "rpe_adjustment success exercise=\(exercise.name, privacy: .public) adjustedSets=\(adjustedSets.count, privacy: .public)"
            )
            return adjustedSets
        } catch {
            logger.error("RPE adjustment failed: \(error)")
            return nil
        }
    }

}
