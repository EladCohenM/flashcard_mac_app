import Foundation

enum AppFormatting {
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        let minutes = seconds / 60
        let remainder = seconds % 60
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
    }

    static func accuracy(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}
