import Foundation
import Intents

class MoveAppIntent: INIntent {
    @NSManaged public var appName: String?
    @NSManaged public var folderName: String?
}

class MoveAppIntentHandler: NSObject, MoveAppIntentHandling {
    func handle(intent: MoveAppIntent, completion: @escaping (MoveAppIntentResponse) -> Void) {
        guard let appName = intent.appName, let folderName = intent.folderName else {
            completion(MoveAppIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        // TODO: Implement logic to move the app to the specified folder
        print("Moving app \(appName) to folder: \(folderName)")
        
        completion(MoveAppIntentResponse(code: .success, userActivity: nil))
    }
}

@available(iOS 17.0, *)
struct MoveAppAppShortcuts: AppShortcuts {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MoveAppIntent(),
            phrases: ["Move app to folder", "Organize specific app"],
            shortTitle: "Move App"
        )
    }
}