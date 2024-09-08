import Foundation
import CoreML
import NaturalLanguage

class ContextAwareSuggestions {
    static let shared = ContextAwareSuggestions()
    
    private let appUsageAnalytics = AppUsageAnalytics.shared
    private let folderManager = FolderManager.shared
    
    private init() {}
    
    func suggestFolderCreationBasedOnUsage() {
        let frequentApps = appUsageAnalytics.getFrequentlyUsedApps(threshold: 5)
        let categories = categorizeApps(frequentApps)
        
        for (category, apps) in categories {
            if apps.count >= 3 && !folderExists(with: category) {
                let newFolder = folderManager.createFolder(name: category, category: .suggested)
                for app in apps {
                    folderManager.addApp(bundleIdentifier: app, to: newFolder.id)
                }
                print("Created new folder: \(category) with apps: \(apps)")
            }
        }
    }
    
    func processUserCommand(_ command: String) {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = command
        
        var verbs: [String] = []
        var nouns: [String] = []
        
        tagger.enumerateTags(in: command.startIndex..<command.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag {
                let word = String(command[tokenRange])
                switch tag {
                case .verb:
                    verbs.append(word)
                case .noun:
                    nouns.append(word)
                default:
                    break
                }
            }
            return true
        }
        
        interpretCommand(verbs: verbs, nouns: nouns)
    }
    
    private func interpretCommand(verbs: [String], nouns: [String]) {
        guard let mainVerb = verbs.first?.lowercased() else { return }
        
        switch mainVerb {
        case "move", "put":
            if let appType = nouns.first, let destination = nouns.last {
                moveApps(of: appType, to: destination)
            }
        case "create":
            if let folderName = nouns.last {
                createFolder(named: folderName)
            }
        case "organize":
            organizeApps()
        default:
            print("Unable to interpret command")
        }
    }
    
    private func moveApps(of type: String, to destination: String) {
        let apps = appUsageAnalytics.getAllInstalledApps().filter { $0.name.lowercased().contains(type.lowercased()) }
        if let folder = folderManager.getFolderByName(destination) {
            for app in apps {
                folderManager.addApp(bundleIdentifier: app.bundleIdentifier, to: folder.id)
            }
            print("Moved \(apps.count) apps to \(destination) folder")
        } else {
            print("Folder '\(destination)' not found")
        }
    }
    
    private func createFolder(named name: String) {
        let newFolder = folderManager.createFolder(name: name, category: .custom)
        print("Created new folder: \(name)")
    }
    
    private func organizeApps() {
        suggestFolderCreationBasedOnUsage()
        print("Organized apps based on usage patterns")
    }
    
    private func categorizeApps(_ apps: [String]) -> [String: [String]] {
        // This is a placeholder implementation. In a real app, you'd want to use more sophisticated categorization.
        var categories: [String: [String]] = [:]
        for app in apps {
            if let appName = folderManager.getAppName(for: app)?.lowercased() {
                if appName.contains("mail") || appName.contains("calendar") {
                    categories["Productivity", default: []].append(app)
                } else if appName.contains("game") {
                    categories["Games", default: []].append(app)
                } else if appName.contains("social") || appName.contains("chat") {
                    categories["Social", default: []].append(app)
                } else {
                    categories["Misc", default: []].append(app)
                }
            }
        }
        return categories
    }
    
    private func folderExists(with name: String) -> Bool {
        return folderManager.getFolderByName(name) != nil
    }
}