import Foundation

struct RPEAdjustmentService {

    /// Returns an adjusted weight if actual RPE differs from target by 2+, otherwise nil.
    /// Adjusts ~5% per RPE point of difference, rounded to the nearest 5 lbs.
    static func adjustedWeight(actualRpe: Int, targetRpe: Int, currentWeight: Double) -> Double? {
        let diff = targetRpe - actualRpe  // positive = too easy, negative = too hard

        guard abs(diff) >= 2 else { return nil }
        guard currentWeight > 0 else { return nil }

        let adjustmentPerPoint = 0.05
        let factor = 1.0 + Double(diff) * adjustmentPerPoint
        let raw = currentWeight * factor

        // Round to nearest 5 lbs
        let rounded = (raw / 5.0).rounded() * 5.0
        guard rounded != currentWeight, rounded > 0 else { return nil }

        return rounded
    }
}
