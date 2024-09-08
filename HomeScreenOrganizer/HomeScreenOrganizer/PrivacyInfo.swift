import SwiftUI

struct PrivacyInfo: View {
    var body: some View {
        List {
            Section(header: Text("Data Collection")) {
                Text("This app does not collect any personal data. All folder and app organization information is stored locally on your device.")
            }
            
            Section(header: Text("Data Usage")) {
                Text("The app uses on-device machine learning to suggest app categorization and organization. No data is sent to external servers.")
            }
            
            Section(header: Text("Third-Party Services")) {
                Text("This app does not use any third-party services or SDKs.")
            }
            
            Section(header: Text("Permissions")) {
                Text("Home Screen Organization: Required to organize your apps and create folders.")
                Text("Siri & Shortcuts: Optional, used for voice commands to organize apps.")
            }
        }
        .navigationTitle("Privacy Information")
    }
}

struct PrivacyInfo_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyInfo()
    }
}