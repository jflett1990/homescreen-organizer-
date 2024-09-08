import SwiftUI
import CoreML
import NaturalLanguage
import AppIntents

@main
struct HomeScreenOrganizerApp: App {
    @StateObject private var folderManager = FolderManager.shared
    @StateObject private var appSuggestionModel = AppSuggestionModel.shared
    @StateObject private var contextAwareSuggestions = ContextAwareSuggestions.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(folderManager)
                .environmentObject(appSuggestionModel)
                .environmentObject(contextAwareSuggestions)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var folderManager: FolderManager
    @EnvironmentObject var appSuggestionModel: AppSuggestionModel
    @EnvironmentObject var contextAwareSuggestions: ContextAwareSuggestions
    @State private var showingPrivacyInfo = false
    @State private var searchText = ""
    @State private var showingVoiceCommandSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredFolders) { folder in
                    NavigationLink(destination: FolderDetailView(folder: folder)) {
                        Label(folder.name, systemImage: FolderCustomization.shared.getSystemImageName(for: folder.name))
                    }
                }
            }
            .navigationTitle("Folders")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        contextAwareSuggestions.suggestFolderCreationBasedOnUsage()
                    }) {
                        Label("Suggest Folders", systemImage: "wand.and.stars")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingVoiceCommandSheet = true
                    }) {
                        Label("Voice Command", systemImage: "mic")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Privacy") {
                        showingPrivacyInfo = true
                    }
                }
            }
            .sheet(isPresented: $showingPrivacyInfo) {
                PrivacyInfo()
            }
            .sheet(isPresented: $showingVoiceCommandSheet) {
                VoiceCommandView(contextAwareSuggestions: contextAwareSuggestions)
            }
        }
    }
    
    var filteredFolders: [Folder] {
        if searchText.isEmpty {
            return folderManager.folders
        } else {
            return folderManager.folders.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct FolderDetailView: View {
    @EnvironmentObject var folderManager: FolderManager
    let folder: Folder
    
    var body: some View {
        List {
            ForEach(folder.apps, id: \.self) { app in
                Label(folderManager.getAppName(for: app) ?? app, systemImage: "app")
            }
            .onDelete(perform: deleteApps)
        }
        .navigationTitle(folder.name)
        .toolbar {
            EditButton()
        }
    }
    
    private func deleteApps(at offsets: IndexSet) {
        offsets.forEach { index in
            let app = folder.apps[index]
            folderManager.removeApp(bundleIdentifier: app, from: folder.id)
        }
    }
}

struct VoiceCommandView: View {
    @ObservedObject var contextAwareSuggestions: ContextAwareSuggestions
    @State private var voiceCommand = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Voice Command")) {
                    TextField("Enter voice command", text: $voiceCommand)
                }
                
                Button("Process Command") {
                    contextAwareSuggestions.processUserCommand(voiceCommand)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("Voice Command")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - App Intents

struct CreateFolderIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Folder"
    
    @Parameter(title: "Folder Name")
    var folderName: String
    
    @Parameter(title: "Folder Category")
    var category: FolderCategory
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create a folder named \(\.$folderName) in the \(\.$category) category")
    }
    
    func perform() async throws -> some IntentResult {
        FolderManager.shared.createFolder(name: folderName, category: category)
        return .result()
    }
}

struct AddAppToFolderIntent: AppIntent {
    static var title: LocalizedStringResource = "Add App to Folder"
    
    @Parameter(title: "App Name")
    var appName: String
    
    @Parameter(title: "Folder Name")
    var folderName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$appName) to the \(\.$folderName) folder")
    }
    
    func perform() async throws -> some IntentResult {
        if let folder = FolderManager.shared.getFolderByName(folderName),
           let bundleIdentifier = FolderManager.shared.getBundleIdentifier(for: appName) {
            FolderManager.shared.addApp(bundleIdentifier: bundleIdentifier, to: folder.id)
            return .result()
        } else {
            throw $error("Could not find folder or app")
        }
    }
}

struct OrganizeAppsIntent: AppIntent {
    static var title: LocalizedStringResource = "Organize Apps"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Organize apps based on usage patterns")
    }
    
    func perform() async throws -> some IntentResult {
        ContextAwareSuggestions.shared.suggestFolderCreationBasedOnUsage()
        return .result()
    }
}