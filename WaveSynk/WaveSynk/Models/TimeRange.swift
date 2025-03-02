import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case week = "Week"
    
    var id: String { self.rawValue }
} 