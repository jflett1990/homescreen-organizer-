import UIKit
import CoreML
import SiriKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
            let mainViewController = MainViewController()
            window?.rootViewController = UINavigationController(rootViewController: mainViewController)
        } else {
            let onboardingViewController = OnboardingViewController()
            window?.rootViewController = UINavigationController(rootViewController: onboardingViewController)
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
        
        window?.makeKeyAndVisible()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }

    // MARK: - Siri Intent Handling

    func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
        // Handle Siri intents here
        IntentHandler().handle(intent: intent, completion: completionHandler)
    }
}