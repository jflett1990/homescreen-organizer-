import Foundation
import CoreLocation

struct Profile: Codable {
    let id: UUID
    var name: String
    var folderIds: [UUID]
    var timeConstraints: TimeConstraints?
    var locationConstraints: LocationConstraints?
}

class ProfileManager {
    static let shared = ProfileManager()
    
    private var profiles: [Profile] = []
    private let profileStorageKey = "SavedProfiles"
    private var currentProfile: Profile?
    
    private init() {
        loadProfiles()
        createDefaultProfiles()
    }
    
    func createProfile(name: String, folderIds: [UUID], timeConstraints: TimeConstraints? = nil, locationConstraints: LocationConstraints? = nil) -> Profile {
        let newProfile = Profile(id: UUID(), name: name, folderIds: folderIds, timeConstraints: timeConstraints, locationConstraints: locationConstraints)
        profiles.append(newProfile)
        saveProfiles()
        return newProfile
    }
    
    func updateProfile(_ updatedProfile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == updatedProfile.id }) else { return }
        profiles[index] = updatedProfile
        saveProfiles()
    }
    
    func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        saveProfiles()
    }
    
    func getAllProfiles() -> [Profile] {
        return profiles
    }
    
    func getCurrentProfile() -> Profile? {
        return currentProfile
    }
    
    func setCurrentProfile(_ profile: Profile) {
        currentProfile = profile
    }
    
    func updateCurrentProfile(basedOn location: CLLocation, andTime date: Date) {
        for profile in profiles {
            if let timeConstraints = profile.timeConstraints,
               let locationConstraints = profile.locationConstraints {
                let isTimeValid = FolderManager.shared.isTime(date, withinConstraints: timeConstraints)
                let isLocationValid = FolderManager.shared.isLocation(location, withinConstraints: locationConstraints)
                
                if isTimeValid && isLocationValid {
                    setCurrentProfile(profile)
                    return
                }
            }
        }
    }
    
    private func saveProfiles() {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profileStorageKey)
        } catch {
            print("Error saving profiles: \(error)")
        }
    }
    
    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(forKey: profileStorageKey) else { return }
        do {
            profiles = try JSONDecoder().decode([Profile].self, from: data)
        } catch {
            print("Error loading profiles: \(error)")
        }
    }
    
    private func createDefaultProfiles() {
        if profiles.isEmpty {
            let workProfile = createProfile(name: "Work Mode", folderIds: [])
            let weekendProfile = createProfile(name: "Weekend Mode", folderIds: [])
            let travelProfile = createProfile(name: "Travel Mode", folderIds: [])
            
            // Set default profile
            setCurrentProfile(workProfile)
        }
    }
}