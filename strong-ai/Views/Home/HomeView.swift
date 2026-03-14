import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(
        filter: #Predicate<WorkoutLog> { $0.finishedAt != nil },
        sort: \WorkoutLog.startedAt,
        order: .reverse
    ) private var recentLogs: [WorkoutLog]

    private var todayTemplate: WorkoutTemplate? { templates.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    statCards
                    if let template = todayTemplate {
                        workoutSection(template)
                    } else {
                        emptyWorkoutSection
                    }
                }
                .padding(.bottom, 100)
            }
            .safeAreaInset(edge: .bottom) {
                chatBar
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Color.black.opacity(0.35))
            Text(greeting)
                .font(.custom("SpaceGrotesk-Bold", size: 36))
                .tracking(-1.4)
                .foregroundStyle(Color(hex: 0x0A0A0A))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 10) {
            StatCard(title: "WORKOUTS", value: "\(recentLogs.count)")
            StatCard(title: "THIS WEEK", value: "\(workoutsThisWeek)")
            StatCard(title: "STREAK", value: "\(streak)", highlight: streak > 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var workoutsThisWeek: Int {
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return recentLogs.filter { $0.startedAt >= startOfWeek }.count
    }

    private var streak: Int {
        // Simple streak: count consecutive days with workouts going back from today
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: .now)
        var count = 0
        let logDates = Set(recentLogs.map { calendar.startOfDay(for: $0.startedAt) })

        while logDates.contains(currentDate) {
            count += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        return count
    }

    // MARK: - Workout Section

    private func workoutSection(_ template: WorkoutTemplate) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Today's Workout")
                .font(.custom("SpaceGrotesk-Bold", size: 20))
                .tracking(-0.4)
                .foregroundStyle(Color(hex: 0x0A0A0A))
                .padding(.horizontal, 20)
                .padding(.top, 28)

            HStack(spacing: 8) {
                Text(template.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.6))
                Text("\(template.totalSets) sets · ~\(template.estimatedMinutes) min")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.black.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            exerciseList(template.exercises)
            startButton
        }
    }

    private func exerciseList(_ exercises: [TemplateExercise]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                if index > 0 {
                    Divider().padding(.horizontal, 16)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x0A0A0A))
                        Text("\(exercise.sets.count) sets · \(exercise.sets.first.map { "\($0.reps) reps · \(Int($0.weight)) lbs" } ?? "")")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.black.opacity(0.35))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color(hex: 0xF5F5F5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var startButton: some View {
        NavigationLink {
            // ActiveWorkoutView will go here in Phase 2
            Text("Active Workout")
        } label: {
            Text("Start Workout")
                .font(.custom("SpaceGrotesk-Bold", size: 17))
                .tracking(-0.2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: 0x0A0A0A))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var emptyWorkoutSection: some View {
        VStack(spacing: 12) {
            Text("No workout planned")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Create a template in the Library tab, or ask the AI to generate one.")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Chat Bar

    private var chatBar: some View {
        HStack(spacing: 12) {
            Text("I only have 30 min today...")
                .font(.system(size: 15))
                .foregroundStyle(Color.black.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(hex: 0xF5F5F5))
                .clipShape(RoundedRectangle(cornerRadius: 21))

            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color(hex: 0x0A0A0A))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("SpaceGrotesk-Bold", size: 28))
                .tracking(-0.5)
                .foregroundStyle(highlight ? Color(hex: 0x34C759) : Color(hex: 0x0A0A0A))
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.black.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: 0xF5F5F5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Color Helper

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
