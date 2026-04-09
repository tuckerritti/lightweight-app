import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Colors

private enum WidgetColors {
    static let background = Color(hex: 0x0A0A0A)
    static let surface = Color(hex: 0x222222)
    static let accent = Color(hex: 0x34C759)
    static let textPrimary = Color(hex: 0xF5F5F5)
    static let textSecondary = Color.white.opacity(0.7)
}

// MARK: - Widget

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(WidgetColors.background)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedCenter(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                compactLeading(context: context)
            } compactTrailing: {
                compactTrailing(context: context)
            } minimal: {
                minimal(context: context)
            }
        }
    }

    // MARK: - Lock Screen

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        VStack(alignment: .leading, spacing: 10) {
            // Header — identical for both modes
            HStack(alignment: .center) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(WidgetColors.accent)
                Text("Workout")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WidgetColors.textSecondary)
                Spacer()
                Text("\(state.completedSets) of \(state.totalSets) sets")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(WidgetColors.textSecondary)
            }

            // Content — mode-specific, same height structure
            switch state.mode {
            case .restTimer:
                lockScreenRestTimer(state: state)
            case .activeSet:
                lockScreenActiveSet(state: state)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func lockScreenRestTimer(state: WorkoutActivityAttributes.ContentState) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.exerciseName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(WidgetColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(state.setDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WidgetColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if let endDate = state.timerEndDate {
                Text(timerInterval: min(Date.now, endDate)...endDate, countsDown: true)
                    .font(.system(size: 36, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(WidgetColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .frame(minWidth: 80, alignment: .trailing)
            }
        }

        Button(intent: SkipRestTimerIntent()) {
            Text("Skip")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(WidgetColors.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func lockScreenActiveSet(state: WorkoutActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.exerciseName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(state.setDescription)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WidgetColors.textSecondary)
                .lineLimit(1)
            Text(state.weightRepsLabel)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
        }

        Button(intent: CompleteSetIntent()) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                Text("Complete Set")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(WidgetColors.accent, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dynamic Island Compact

    @ViewBuilder
    private func compactLeading(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        Group {
            switch state.mode {
            case .restTimer:
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetColors.accent)
            case .activeSet:
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetColors.accent)
            }
        }
        .frame(width: 16, height: 16)
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        Group {
            switch state.mode {
            case .restTimer:
                if let endDate = state.timerEndDate {
                    Text(timerInterval: min(Date.now, endDate)...endDate, countsDown: true)
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(WidgetColors.accent)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("--:--")
                        .font(.system(size: 12, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(WidgetColors.accent)
                }
            case .activeSet:
                Text("\(state.completedSets)/\(state.totalSets)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(WidgetColors.textPrimary)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(width: 34)
    }

    // MARK: - Dynamic Island Minimal

    @ViewBuilder
    private func minimal(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        switch state.mode {
        case .restTimer:
            Image(systemName: "timer")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(WidgetColors.accent)
        case .activeSet:
            Text("\(state.completedSets)")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(WidgetColors.accent)
        }
    }

    // MARK: - Dynamic Island Expanded

    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        EmptyView()
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        EmptyView()
    }

    @ViewBuilder
    private func expandedCenter(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        switch state.mode {
        case .restTimer:
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WidgetColors.accent)
                        Text("Workout")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("\(state.completedSets)/\(state.totalSets)")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.exerciseName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(state.setDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    if let endDate = state.timerEndDate {
                        Text(timerInterval: min(Date.now, endDate)...endDate, countsDown: true)
                            .font(.system(size: 24, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        case .activeSet:
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(WidgetColors.accent)
                        Text("Workout")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("\(state.completedSets)/\(state.totalSets)")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.exerciseName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(state.weightRepsLabel)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        let state = context.state
        switch state.mode {
        case .restTimer:
            Button(intent: SkipRestTimerIntent()) {
                Text("Skip")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(WidgetColors.accent, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        case .activeSet:
            Button(intent: CompleteSetIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Complete Set")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(WidgetColors.accent, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}
