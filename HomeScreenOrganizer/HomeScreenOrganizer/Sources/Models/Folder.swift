import Foundation

struct Folder: Codable {
    let id: UUID
    var name: String
    var apps: [String] // Array of app bundle identifiers
    var category: FolderCategory
    var isSmartFolder: Bool
    var timeConstraints: TimeConstraints?
    var locationConstraints: LocationConstraints?

    init(name: String, category: FolderCategory, isSmartFolder: Bool = false) {
        self.id = UUID()
        self.name = name
        self.apps = []
        self.category = category
        self.isSmartFolder = isSmartFolder
    }
}

enum FolderCategory: String, Codable {
    case social
    case productivity
    case fitness
    case entertainment
    case travel
    case work
    case custom
}

struct TimeConstraints: Codable {
    var startTime: Date
    var endTime: Date
    var daysOfWeek: [Int] // 1 = Sunday, 2 = Monday, etc.
}

struct LocationConstraints: Codable {
    var latitude: Double
    var longitude: Double
    var radius: Double // in meters
}