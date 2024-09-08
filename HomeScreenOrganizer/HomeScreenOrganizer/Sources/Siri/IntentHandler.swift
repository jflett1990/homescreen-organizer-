import Intents
import CoreML

class IntentHandler: INExtension, ObservableObject {
    @Published var currentMode: String = "Normal"
    
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is INCreateFolderIntent:
            return CreateFolderIntentHandler()
        case is INMoveAppsIntent:
            return MoveAppsIntentHandler()
        case is OrganizeAppsIntent:
            return OrganizeAppsIntentHandler()
        default:
            fatalError("Unhandled intent type: \(intent)")
        }
    }
}

class CreateFolderIntentHandler: NSObject, INCreateFolderIntentHandling {
    func handle(intent: INCreateFolderIntent, completion: @escaping (INCreateFolderIntentResponse) -> Void) {
        guard let folderName = intent.folderName else {
            completion(INCreateFolderIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let folderManager = FolderManager.shared
        let newFolder = folderManager.createFolder(name: folderName, category: .custom)
        
        if let appNames = intent.apps {
            for appName in appNames {
                // TODO: Implement logic to get bundle identifier from app name
                let bundleIdentifier = appName // Placeholder
                folderManager.addApp(bundleIdentifier: bundleIdentifier, to: newFolder.id)
            }
        }
        
        completion(INCreateFolderIntentResponse(code: .success, userActivity: nil))
    }
}

class MoveAppsIntentHandler: NSObject, INMoveAppsIntentHandling {
    func handle(intent: INMoveAppsIntent, completion: @escaping (INMoveAppsIntentResponse) -> Void) {
        guard let folderName = intent.targetFolder,
              let appNames = intent.apps,
              let folder = FolderManager.shared.getFolderByName(folderName) else {
            completion(INMoveAppsIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        let folderManager = FolderManager.shared
        
        for appName in appNames {
            // TODO: Implement logic to get bundle identifier from app name
            let bundleIdentifier = appName // Placeholder
            folderManager.addApp(bundleIdentifier: bundleIdentifier, to: folder.id)
        }
        
        completion(INMoveAppsIntentResponse(code: .success, userActivity: nil))
    }
}

class OrganizeAppsIntentHandler: NSObject, OrganizeAppsIntentHandling {
    func handle(intent: OrganizeAppsIntent, completion: @escaping (OrganizeAppsIntentResponse) -> Void) {
        guard let folderName = intent.folderName else {
            completion(OrganizeAppsIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // Use CoreML to suggest app organization
        let appUsageAnalytics = AppUsageAnalytics.shared
        let suggestedApps = appUsageAnalytics.suggestAppsForFolder(folderName)
        
        let folderManager = FolderManager.shared
        let newFolder = folderManager.createFolder(name: folderName, category: .suggested)
        
        for app in suggestedApps {
            folderManager.addApp(bundleIdentifier: app.bundleIdentifier, to: newFolder.id)
        }
        
        completion(OrganizeAppsIntentResponse(code: .success, userActivity: nil))
    }
}

@available(iOS 17.0, *)
struct HomeScreenOrganizerAppShortcuts: AppShortcuts {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OrganizeAppsIntent(),
            phrases: ["Organize my apps", "Sort apps by usage"],
            shortTitle: "Organize Apps"
        )
    }
}