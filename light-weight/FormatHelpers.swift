import Foundation

extension Double {
    /// Formats a weight for display: 185.0 → "185", 187.5 → "187.5"
    var formattedWeight: String {
        truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(self))" : String(format: "%.1f", self)
    }
}

/// Parses a weight string that may use either `.` or `,` as the decimal separator.
func parseWeight(_ text: String) -> Double? {
    Double(text.replacingOccurrences(of: ",", with: "."))
}

extension Int {
    /// Formats seconds as m:ss — e.g. 90 → "1:30", 30 → "0:30"
    var formattedDuration: String {
        let m = self / 60
        let s = self % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}

extension Double {
    /// Formats meters for display — e.g. 50.0 → "50m", 1500.0 → "1.5km"
    var formattedDistance: String {
        if self >= 1000 {
            let km = self / 1000
            return km.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(km))km" : String(format: "%.1fkm", km)
        }
        return truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(self))m" : String(format: "%.1fm", self)
    }
}
