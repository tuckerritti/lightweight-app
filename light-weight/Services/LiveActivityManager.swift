import ActivityKit
import Foundation
import os

private let logger = Logger(subsystem: "com.light-weight", category: "LiveActivity")

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<WorkoutActivityAttributes>?

    // MARK: - Lifecycle

    func startWorkout(name: String, exerciseName: String, setDescription: String, weightRepsLabel: String, completedSets: Int, totalSets: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.info("live_activity disabled by user")
            return
        }

        let attributes = WorkoutActivityAttributes(workoutName: name)
        let state = WorkoutActivityAttributes.ContentState(
            mode: .activeSet,
            timerEndDate: nil,
            timerTotalSeconds: nil,
            exerciseName: exerciseName,
            setDescription: setDescription,
            weightRepsLabel: weightRepsLabel,
            completedSets: completedSets,
            totalSets: totalSets
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            logger.info("live_activity start success")
        } catch {
            logger.error("live_activity start failure: \(error)")
        }
    }

    func updateToRestTimer(exerciseName: String, setDescription: String, timerEndDate: Date, totalSeconds: Int, completedSets: Int, totalSets: Int) {
        let state = WorkoutActivityAttributes.ContentState(
            mode: .restTimer,
            timerEndDate: timerEndDate,
            timerTotalSeconds: totalSeconds,
            exerciseName: exerciseName,
            setDescription: setDescription,
            weightRepsLabel: "",
            completedSets: completedSets,
            totalSets: totalSets
        )
        Task {
            await currentActivity?.update(.init(state: state, staleDate: timerEndDate))
            logger.info("live_activity update restTimer seconds=\(totalSeconds, privacy: .public)")
        }
    }

    func updateToActiveSet() {
        guard let vm = AppState.shared?.activeViewModel else { return }

        guard let (exerciseName, setDescription, weightRepsLabel) = findActiveSetInfo(in: vm) else { return }

        let state = WorkoutActivityAttributes.ContentState(
            mode: .activeSet,
            timerEndDate: nil,
            timerTotalSeconds: nil,
            exerciseName: exerciseName,
            setDescription: setDescription,
            weightRepsLabel: weightRepsLabel,
            completedSets: vm.completedSets,
            totalSets: vm.totalSets
        )
        Task {
            await currentActivity?.update(.init(state: state, staleDate: nil))
            logger.info("live_activity update activeSet exercise=\(exerciseName, privacy: .public)")
        }
    }

    func endWorkout() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("live_activity end")
        }
        currentActivity = nil
    }

    // MARK: - Intent Handlers

    func handleSkipTimer() {
        AppState.shared?.activeViewModel?.timerService.stop()
        updateToActiveSet()
    }

    func handleCompleteSet() {
        guard let vm = AppState.shared?.activeViewModel else { return }
        for (ei, entry) in vm.entries.enumerated() {
            for (si, set) in entry.sets.enumerated() {
                if set.completedAt == nil {
                    let planned = vm.plannedSet(exerciseIndex: ei, setIndex: si)
                    let rpe = (1...10).contains(set.rpe) ? set.rpe : (planned?.targetRpe ?? 5)
                    vm.logSet(
                        exerciseIndex: ei,
                        setIndex: si,
                        weight: set.weight,
                        reps: set.reps,
                        rpe: max(1, min(10, rpe))
                    )
                    return
                }
            }
        }
    }

    // MARK: - Helpers

    private func findActiveSetInfo(in vm: ActiveWorkoutViewModel) -> (exerciseName: String, setDescription: String, weightRepsLabel: String)? {
        for (ei, entry) in vm.entries.enumerated() {
            for (si, set) in entry.sets.enumerated() {
                if set.completedAt == nil {
                    let workingSetsBeforeThis = entry.sets.prefix(si).filter { !$0.isWarmup }.count + 1
                    let totalWorkingSets = entry.sets.filter { !$0.isWarmup }.count
                    let setDesc = set.isWarmup ? "Warm-up" : "Set \(workingSetsBeforeThis) of \(totalWorkingSets)"

                    let planned = vm.plannedSet(exerciseIndex: ei, setIndex: si)
                    let weight = planned?.weight ?? set.weight
                    let reps = planned?.reps ?? set.reps
                    let weightLabel = weight.truncatingRemainder(dividingBy: 1) == 0
                        ? "\(Int(weight))" : String(format: "%.1f", weight)
                    let label = "\(weightLabel) lbs x \(reps) reps"

                    return (entry.exerciseName, setDesc, label)
                }
            }
        }
        return nil
    }
}
