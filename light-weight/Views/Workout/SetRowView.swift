import SwiftUI

private func debugSetRowLog(_ message: String) {
    DebugLogStore.record(message, category: "SetRow")
}

struct SetRowView: View {
    private static let errorPulseCount = 3

    let exerciseType: ExerciseType
    let setNumber: Int
    let logSet: LogSet
    let plannedSet: WorkoutSet?
    let isActive: Bool
    let isUpdating: Bool
    let isAdjusting: Bool
    let adjustmentFailed: Bool
    let onLog: (Double, Int, Int, Int?, Double?) -> Void
    var onEdit: ((Double, Int, Int, Int?, Double?) -> Void)? = nil

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpeText: String = ""
    @State private var durationText: String = ""
    @State private var distanceText: String = ""
    @State private var didInit = false
    @State private var sweepPosition: CGFloat = 1.3
    @State private var contentOpacity: Double = 1.0
    @State private var sweepProgress: CGFloat = 1.3
    @State private var pulseOpacity: Double = 0.0
    @State private var isEditing = false
    @State private var editSaveCount = 0

    private var isCompleted: Bool { logSet.completedAt != nil }

    private var canLog: Bool {
        guard let rpe = Int(rpeText), (1...10).contains(rpe) else { return false }
        switch exerciseType {
        case .weightReps:
            return parseWeight(weightText) != nil && Int(repsText) != nil
        case .timed:
            return Int(durationText) != nil
        case .timedDistance:
            return Int(durationText) != nil && parseWeight(distanceText) != nil
        }
    }

    var body: some View {
        rowWithOverlays
            .sensoryFeedback(.success, trigger: logSet.completedAt) { oldValue, newValue in
                oldValue == nil && newValue != nil
            }
            .sensoryFeedback(.success, trigger: editSaveCount)
            .onChange(of: isUpdating) { handleUpdatingChanged() }
            .onChange(of: adjustmentFailed) { handleAdjustmentFailedChanged() }
            .onChange(of: isAdjusting) { handleAdjustingChanged() }
            .onDisappear { stopSweep() }
    }

    private var rowWithOverlays: some View {
        rowWithDataHandlers
            .opacity((isAdjusting && !isCompleted ? 0.5 : 1.0) * contentOpacity)
            .animation(.easeOut(duration: 0.2), value: isAdjusting)
            .overlay { adjustingSweepOverlay }
            .overlay { updatingSweepOverlay }
            .background {
                Rectangle()
                    .fill(Color.red)
                    .opacity(pulseOpacity)
            }
    }

    // MARK: - Row Content

    private var rowWithDataHandlers: some View {
        HStack(spacing: 8) {
            Text(logSet.isWarmup ? "W" : "\(setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(logSet.isWarmup ? .textTertiary : (isCompleted ? Color.accent : .textSecondary))
                .frame(width: 40, alignment: .leading)

            if isCompleted && isEditing {
                editingRow
            } else if isCompleted {
                completedRow
            } else if isActive {
                activeRow
            } else {
                futureRow
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(
            isActive
                ? RoundedRectangle(cornerRadius: 10).stroke(Color.textPrimary, lineWidth: 1.5).padding(.horizontal, 8)
                : nil
        )
        .onAppear {
            guard !didInit else { return }
            didInit = true
            syncDisplayedValues()
            debugSetRowLog("Row \(self.setNumber) appeared active=\(self.isActive) completed=\(self.isCompleted) adjusting=\(self.isAdjusting)")
            if isAdjusting {
                startSweep()
            }
        }
        .onChange(of: logSet.weight) { syncPendingValues() }
        .onChange(of: logSet.reps) { syncPendingValues() }
        .onChange(of: logSet.durationSeconds) { syncPendingValues() }
        .onChange(of: logSet.distanceMeters) { syncPendingValues() }
        .onChange(of: logSet.rpe) {
            if isCompleted {
                rpeText = logSet.rpe > 0 ? String(logSet.rpe) : ""
            }
        }
    }

    // MARK: - Input Fields

    private var weightField: some View {
        NumericTextField(text: $weightText, placeholder: exerciseType == .weightReps ? "0" : "BW", keyboardType: .decimalPad)
            .frame(maxWidth: .infinity)
            .frame(height: 33)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var repsField: some View {
        NumericTextField(text: $repsText, placeholder: "0", keyboardType: .numberPad)
            .frame(maxWidth: .infinity)
            .frame(height: 33)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var durationField: some View {
        NumericTextField(text: $durationText, placeholder: "sec", keyboardType: .numberPad)
            .frame(maxWidth: .infinity)
            .frame(height: 33)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var distanceField: some View {
        NumericTextField(text: $distanceText, placeholder: "m", keyboardType: .decimalPad)
            .frame(maxWidth: .infinity)
            .frame(height: 33)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var rpeField: some View {
        NumericTextField(text: $rpeText, placeholder: plannedSet?.targetRpe.map { "@\($0)" } ?? "—", keyboardType: .numberPad)
            .frame(width: 48)
            .frame(height: 33)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func inputFields(rpeEditPlaceholder: Bool = false) -> some View {
        weightField
        switch exerciseType {
        case .weightReps:
            repsField
        case .timed:
            durationField
        case .timedDistance:
            durationField
            distanceField
        }
        if rpeEditPlaceholder {
            NumericTextField(text: $rpeText, placeholder: "—", keyboardType: .numberPad)
                .frame(width: 48)
                .frame(height: 33)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            rpeField
        }
    }

    // MARK: - Completed

    @ViewBuilder
    private var completedRow: some View {
        Text(weightText)
            .font(.system(size: 14, weight: .medium))
            .frame(maxWidth: .infinity)
        switch exerciseType {
        case .weightReps:
            Text(repsText)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
        case .timed:
            Text(durationText.isEmpty ? "—" : "\(durationText)s")
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
        case .timedDistance:
            Text(durationText.isEmpty ? "—" : "\(durationText)s")
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
            Text(distanceText.isEmpty ? "—" : "\(distanceText)m")
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
        }
        Text(rpeText.isEmpty ? "—" : rpeText)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 48, alignment: .center)
        Button {
            isEditing = true
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.accent)
                .frame(width: 28)
        }
        .accessibilityLabel("Edit set")
    }

    // MARK: - Editing

    @ViewBuilder
    private var editingRow: some View {
        inputFields(rpeEditPlaceholder: true)

        Button {
            guard let values = collectValues() else { return }
            onEdit?(values.weight, values.reps, values.rpe, values.duration, values.distance)
            isEditing = false
            editSaveCount += 1
        } label: {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 20))
                .foregroundStyle(canLog ? Color.accent : .textQuaternary)
        }
        .disabled(!canLog)
        .frame(width: 28)
        .accessibilityLabel("Save edit")
    }

    // MARK: - Active

    @ViewBuilder
    private var activeRow: some View {
        inputFields()

        Button {
            guard let values = collectValues() else { return }
            onLog(values.weight, values.reps, values.rpe, values.duration, values.distance)
        } label: {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 20))
                .foregroundStyle(canLog ? Color.textPrimary : .textQuaternary)
        }
        .disabled(!canLog)
        .frame(width: 28)
        .accessibilityLabel(canLog ? "Log set" : "Enter values and RPE (1–10) to log")
    }

    // MARK: - Future

    @ViewBuilder
    private var futureRow: some View {
        Text(plannedSet.map { $0.weight > 0 ? $0.weight.formattedWeight : "BW" } ?? "—")
            .font(.system(size: 14))
            .foregroundStyle(Color.textTertiary)
            .frame(maxWidth: .infinity)
        switch exerciseType {
        case .weightReps:
            Text(plannedSet.map { "\($0.reps)" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity)
        case .timed:
            Text(plannedSet?.durationSeconds.map { "\($0)s" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity)
        case .timedDistance:
            Text(plannedSet?.durationSeconds.map { "\($0)s" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity)
            Text(plannedSet?.distanceMeters.map { "\($0.formattedDistance)" } ?? "—")
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity)
        }
        Text(plannedSet?.targetRpe.map { "@\($0)" } ?? "—")
            .font(.system(size: 14))
            .foregroundStyle(Color.textTertiary)
            .frame(width: 48, alignment: .center)
        Circle()
            .strokeBorder(Color.divider, lineWidth: 1.5)
            .frame(width: 20, height: 20)
            .frame(width: 28)
    }

    // MARK: - Value Collection

    private func collectValues() -> (weight: Double, reps: Int, rpe: Int, duration: Int?, distance: Double?)? {
        guard let rpe = Int(rpeText), (1...10).contains(rpe) else { return nil }
        let weight = parseWeight(weightText) ?? 0
        switch exerciseType {
        case .weightReps:
            guard let reps = Int(repsText) else { return nil }
            return (weight, reps, rpe, nil, nil)
        case .timed:
            guard let duration = Int(durationText) else { return nil }
            return (weight, 0, rpe, duration, nil)
        case .timedDistance:
            guard let duration = Int(durationText), let distance = parseWeight(distanceText) else { return nil }
            return (weight, 0, rpe, duration, distance)
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private var adjustingSweepOverlay: some View {
        if !isCompleted {
            GeometryReader { proxy in
                let bandWidth: CGFloat = 72
                let travel = proxy.size.width + (bandWidth * 2)
                let xOffset = (travel * sweepProgress) - bandWidth

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray.opacity(0.0),
                                Color.gray.opacity(0.45),
                                Color.gray.opacity(0.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: bandWidth)
                    .opacity(isAdjusting ? 0.9 : 0)
                    .offset(x: xOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .clipped()
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var updatingSweepOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: max(0, min(1, sweepPosition - 0.15))),
                        .init(color: Color.textQuaternary, location: max(0, min(1, sweepPosition))),
                        .init(color: .clear, location: max(0, min(1, sweepPosition + 0.15))),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(sweepPosition < 1.3 ? 1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: - State Helpers

    private func syncDisplayedValues() {
        weightText = logSet.weight > 0 ? logSet.weight.formattedWeight : ""
        repsText = logSet.reps > 0 ? "\(logSet.reps)" : ""
        rpeText = logSet.rpe > 0 ? String(logSet.rpe) : ""
        durationText = logSet.durationSeconds.map { "\($0)" } ?? ""
        distanceText = logSet.distanceMeters.map { $0.formattedWeight } ?? ""
    }

    private func syncPendingValues() {
        guard !isCompleted else { return }
        weightText = logSet.weight > 0 ? logSet.weight.formattedWeight : ""
        repsText = logSet.reps > 0 ? "\(logSet.reps)" : ""
        durationText = logSet.durationSeconds.map { "\($0)" } ?? ""
        distanceText = logSet.distanceMeters.map { $0.formattedWeight } ?? ""
    }

    private func handleUpdatingChanged() {
        guard isUpdating else { return }
        sweepPosition = -0.3
        contentOpacity = 0.3
        withAnimation(.easeOut(duration: 0.8)) {
            sweepPosition = 1.3
            contentOpacity = 1.0
        }
    }

    private func handleAdjustmentFailedChanged() {
        guard !isCompleted else { return }

        guard adjustmentFailed else {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                pulseOpacity = 0.0
            }
            return
        }

        pulseOpacity = 0.0
        withAnimation(
            .easeInOut(duration: 0.25)
                .repeatCount(Self.errorPulseCount * 2, autoreverses: true)
        ) {
            pulseOpacity = 0.3
        }
    }

    private func handleAdjustingChanged() {
        debugSetRowLog("Row \(self.setNumber) adjusting=\(self.isAdjusting) completed=\(self.isCompleted)")
        if isAdjusting {
            startSweep()
        } else {
            stopSweep()
        }
    }

    private func startSweep() {
        guard !isCompleted else { return }

        debugSetRowLog("Starting sweep row=\(self.setNumber) active=\(self.isActive)")

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            sweepProgress = -0.3
        }

        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            sweepProgress = 1.3
        }
    }

    private func stopSweep() {
        debugSetRowLog("Stopping sweep row=\(self.setNumber) completed=\(self.isCompleted)")

        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            sweepProgress = 1.3
        }
    }
}
