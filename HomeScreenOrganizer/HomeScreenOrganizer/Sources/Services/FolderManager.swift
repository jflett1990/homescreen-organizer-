import Foundation
import CoreML
import CoreLocation
import Intents
import MobileCoreServices

class FolderManager {
    static let shared = FolderManager()
    
    private var folders: [Folder] = []
    private var profiles: [Profile] = []
    private let folderStorageKey = "SavedFolders"
    private let profileStorageKey = "SavedProfiles"
    private let appSuggestionModel = AppSuggestionModel.shared
    private let appUsageAnalytics = AppUsageAnalytics.shared
    private let locationManager = CLLocationManager()
    
    private init() {
        loadFolders()
        loadProfiles()
        setupLocationManager()
    }
    
    // MARK: - Folder Management
    
    func createFolder(name: String, category: FolderCategory) -> Folder {
        let newFolder = Folder(id: UUID(), name: name, apps: [], category: category)
        folders.append(newFolder)
        saveFolders()
        return newFolder
    }
    
    func addApp(bundleIdentifier: String, to folderId: UUID) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].apps.append(bundleIdentifier)
            saveFolders()
        }
    }
    
    func removeApp(bundleIdentifier: String, from folderId: UUID) {
        if let index = folders.firstIndex(where: { $0.id == folderId }) {
            folders[index].apps.removeAll { $0 == bundleIdentifier }
            saveFolders()
        }
    }
    
    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        saveFolders()
    }
    
    func getFolderByName(_ name: String) -> Folder? {
        return folders.first { $0.name == name }
    }
    
    // MARK: - Profile Management
    
    func createProfile(name: String, folders: [UUID], activationRules: [ActivationRule]) -> Profile {
        let newProfile = Profile(id: UUID(), name: name, folders: folders, activationRules: activationRules)
        profiles.append(newProfile)
        saveProfiles()
        return newProfile
    }
    
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
    
    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        saveProfiles()
    }
    
    func getProfileByName(_ name: String) -> Profile? {
        return profiles.first { $0.name == name }
    }
    
    // MARK: - Dynamic Folder Management
    
    func createDynamicFolder(name: String, category: FolderCategory, rule: DynamicFolderRule) -> Folder {
        let newFolder = DynamicFolder(id: UUID(), name: name, apps: [], category: category, rule: rule)
        folders.append(newFolder)
        saveFolders()
        return newFolder
    }
    
    func updateDynamicFolder(_ folder: DynamicFolder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index] = folder
            saveFolders()
        }
    }
    
    func refreshDynamicFolders() {
        for (index, folder) in folders.enumerated() {
            if let dynamicFolder = folder as? DynamicFolder {
                let apps = dynamicFolder.rule.applyRule(appUsageAnalytics: appUsageAnalytics)
                folders[index] = DynamicFolder(id: dynamicFolder.id, name: dynamicFolder.name, apps: apps, category: dynamicFolder.category, rule: dynamicFolder.rule)
            }
        }
        saveFolders()
    }
    
    // MARK: - Location-based Profile Activation
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    // MARK: - Helper Methods
    
    func getBundleIdentifier(for appName: String) -> String? {
        let workspace = LSApplicationWorkspace.default()
        let apps = workspace.allApplications()
        
        for app in apps {
            if let localizedName = app.localizedName(), localizedName == appName {
                return app.bundleIdentifier()
            }
        }
        
        return nil
    }
    
    func getAppName(for bundleIdentifier: String) -> String? {
        let workspace = LSApplicationWorkspace.default()
        let apps = workspace.allApplications()
        
        for app in apps {
            if app.bundleIdentifier() == bundleIdentifier {
                return app.localizedName()
            }
        }
        
        return nil
    }
    
    func getAllInstalledApps() -> [(name: String, bundleIdentifier: String)] {
        let workspace = LSApplicationWorkspace.default()
        let apps = workspace.allApplications()
        
        return apps.compactMap { app in
            guard let name = app.localizedName(),
                  let bundleIdentifier = app.bundleIdentifier() else {
                return nil
            }
            return (name: name, bundleIdentifier: bundleIdentifier)
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: folderStorageKey),
           let decodedFolders = try? JSONDecoder().decode([Folder].self, from: data) {
            folders = decodedFolders
        }
    }
    
    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: folderStorageKey)
        }
    }
    
    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profileStorageKey),
           let decodedProfiles = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = decodedProfiles
        }
    }
    
    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profileStorageKey)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension FolderManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        for profile in profiles {
            for rule in profile.activationRules {
                if case let .location(coordinate, radius) = rule {
                    let regionCenter = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    let distance = location.distance(from: regionCenter)
                    
                    if distance <= radius {
                        // Activate this profile
                        activateProfile(profile)
                        return
                    }
                }
            }
        }
    }
    
    private func activateProfile(_ profile: Profile) {
        // TODO: Implement logic to activate the profile
        // This might involve updating the UI, rearranging apps, etc.
        print("Activating profile: \(profile.name)")
    }
}

// MARK: - Model Definitions

struct Folder: Codable {
    let id: UUID
    let name: String
    var apps: [String]
    let category: FolderCategory
}

class DynamicFolder: Folder {
    let rule: DynamicFolderRule
    
    init(id: UUID, name: String, apps: [String], category: FolderCategory, rule: DynamicFolderRule) {
        self.rule = rule
        super.init(id: id, name: name, apps: apps, category: category)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rule = try container.decode(DynamicFolderRule.self, forKey: .rule)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rule, forKey: .rule)
    }
    
    private enum CodingKeys: String, CodingKey {
        case rule
    }
}

enum FolderCategory: String, Codable {
    case custom
    case suggested
    case dynamic
}

struct Profile: Codable {
    let id: UUID
    let name: String
    var folders: [UUID]
    var activationRules: [ActivationRule]
}

enum ActivationRule: Codable {
    case time(start: Date, end: Date)
    case location(coordinate: CLLocationCoordinate2D, radius: Double)
    case appLaunch(bundleIdentifier: String)
}

enum DynamicFolderRule: Codable {
    case mostUsed(count: Int)
    case recentlyUsed(count: Int)
    case category(appCategory: String)
    
    func applyRule(appUsageAnalytics: AppUsageAnalytics) -> [String] {
        switch self {
        case .mostUsed(let count):
            return appUsageAnalytics.getFrequentlyUsedApps(threshold: count)
        case .recentlyUsed(let count):
            // TODO: Implement logic to get recently used apps
            return []
        case .category(let appCategory):
            // TODO: Implement logic to get apps by category
            return []
        }
    }
}

// MARK: - LSApplicationWorkspace Extension

extension LSApplicationWorkspace {
    @objc static func default() -> LSApplicationWorkspace {
        return LSApplicationWorkspace.performSelector(NSSelectorFromString("defaultWorkspace")).takeUnretainedValue() as! LSApplicationWorkspace
    }
    
    @objc func allApplications() -> [LSApplicationProxy] {
        return self.performSelector(NSSelectorFromString("allApplications")).takeUnretainedValue() as! [LSApplicationProxy]
    }
}

// MARK: - LSApplicationProxy Extension

extension LSApplicationProxy {
    @objc func localizedName() -> String? {
        return self.performSelector(NSSelectorFromString("localizedName")).takeUnretainedValue() as? String
    }
    
    @objc func bundleIdentifier() -> String? {
        return self.performSelector(NSSelectorFromString("bundleIdentifier")).takeUnretainedValue() as? String
    }
}