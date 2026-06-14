import ActivityKit
import Foundation
import os

private let logger = Logger(subsystem: "com.light-weight", category: "LiveActivity")

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    weak var appState: AppState?
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
        guard let vm = appState?.activeViewModel else { return }

        let state: WorkoutActivityAttributes.ContentState
        if let (exerciseName, setDescription, weightRepsLabel) = vm.activeSetInfo() {
            state = WorkoutActivityAttributes.ContentState(
                mode: .activeSet,
                timerEndDate: nil,
                timerTotalSeconds: nil,
                exerciseName: exerciseName,
                setDescription: setDescription,
                weightRepsLabel: weightRepsLabel,
                completedSets: vm.completedSets,
                totalSets: vm.totalSets
            )
        } else {
            // All sets done — show a completed state until the user taps Done in-app.
            state = WorkoutActivityAttributes.ContentState(
                mode: .activeSet,
                timerEndDate: nil,
                timerTotalSeconds: nil,
                exerciseName: vm.workoutName,
                setDescription: "All sets complete",
                weightRepsLabel: "",
                completedSets: vm.completedSets,
                totalSets: vm.totalSets
            )
        }
        Task {
            await currentActivity?.update(.init(state: state, staleDate: nil))
            logger.info("live_activity update activeSet exercise=\(state.exerciseName, privacy: .public)")
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
        appState?.activeViewModel?.timerService.stop()
        updateToActiveSet()
    }

    func handleCompleteSet() {
        guard let vm = appState?.activeViewModel,
              let (ei, si) = vm.nextUncompletedSet() else { return }

        let set = vm.entries[ei].sets[si]
        let planned = vm.plannedSet(exerciseIndex: ei, setIndex: si)
        let rpe = (1...10).contains(set.rpe) ? set.rpe : (planned?.targetRpe ?? 5)
        vm.logSet(
            exerciseIndex: ei,
            setIndex: si,
            weight: set.weight,
            reps: set.reps,
            rpe: max(1, min(10, rpe)),
            durationSeconds: set.durationSeconds ?? planned?.durationSeconds,
            distanceMeters: set.distanceMeters ?? planned?.distanceMeters
        )
    }
}
