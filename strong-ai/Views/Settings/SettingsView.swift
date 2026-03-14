import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let new = UserProfile()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("API Key") {
                    SecureField("sk-ant-...", text: binding(\.apiKey))
                }
                Section("Goals") {
                    TextField("e.g. Build muscle, lose fat", text: binding(\.goals), axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Schedule") {
                    TextField("e.g. 4 days/week, Mon/Tue/Thu/Fri", text: binding(\.schedule), axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Equipment") {
                    TextField("e.g. Full gym, home dumbbells only", text: binding(\.equipment), axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Injuries / Limitations") {
                    TextField("e.g. Bad left shoulder, avoid overhead", text: binding(\.injuries), axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func binding(_ keyPath: ReferenceWritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { profile[keyPath: keyPath] = $0 }
        )
    }
}
