import Foundation
import SwiftData

@Model
final class UserProfile {
    var apiKey: String
    var goals: String
    var schedule: String
    var equipment: String
    var injuries: String

    init(
        apiKey: String = "",
        goals: String = "",
        schedule: String = "",
        equipment: String = "",
        injuries: String = ""
    ) {
        self.apiKey = apiKey
        self.goals = goals
        self.schedule = schedule
        self.equipment = equipment
        self.injuries = injuries
    }
}
