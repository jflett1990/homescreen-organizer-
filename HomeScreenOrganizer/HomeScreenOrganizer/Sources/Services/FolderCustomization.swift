import Foundation
import SwiftUI

class FolderCustomization {
    static let shared = FolderCustomization()
    
    private init() {}
    
    func createCustomIcon(for folderName: String) -> Image {
        // TODO: Implement Genmoji or Image Playground APIs when available in iOS 18
        // For now, we'll use a placeholder implementation
        let systemName = getSystemImageName(for: folderName)
        return Image(systemName: systemName)
    }
    
    private func getSystemImageName(for folderName: String) -> String {
        // This is a simple implementation. In a real app, you'd want a more sophisticated mapping.
        let lowercaseName = folderName.lowercased()
        switch lowercaseName {
        case _ where lowercaseName.contains("work"):
            return "briefcase"
        case _ where lowercaseName.contains("game"):
            return "gamecontroller"
        case _ where lowercaseName.contains("social"):
            return "person.2"
        case _ where lowercaseName.contains("photo"):
            return "photo"
        case _ where lowercaseName.contains("music"):
            return "music.note"
        default:
            return "folder"
        }
    }
}

struct AppUsageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AppUsageWidget", provider: AppUsageWidgetProvider()) { entry in
            AppUsageWidgetView(entry: entry)
        }
        .configurationDisplayName("App Usage Insights")
        .description("View your most-used apps and suggested folders.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AppUsageWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> AppUsageWidgetEntry {
        AppUsageWidgetEntry(date: Date(), mostUsedApps: ["App 1", "App 2", "App 3"])
    }

    func getSnapshot(in context: Context, completion: @escaping (AppUsageWidgetEntry) -> ()) {
        let entry = AppUsageWidgetEntry(date: Date(), mostUsedApps: AppUsageAnalytics.shared.getFrequentlyUsedApps(threshold: 3))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AppUsageWidgetEntry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let entry = AppUsageWidgetEntry(date: currentDate, mostUsedApps: AppUsageAnalytics.shared.getFrequentlyUsedApps(threshold: 3))
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct AppUsageWidgetEntry: TimelineEntry {
    let date: Date
    let mostUsedApps: [String]
}

struct AppUsageWidgetView: View {
    var entry: AppUsageWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Most Used Apps")
                .font(.headline)
            ForEach(entry.mostUsedApps, id: \.self) { app in
                Text(app)
            }
        }
    }
}