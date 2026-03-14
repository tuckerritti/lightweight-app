import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String
    var muscleGroup: String

    init(name: String, muscleGroup: String) {
        self.name = name
        self.muscleGroup = muscleGroup
    }
}
