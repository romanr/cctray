import SwiftUI

struct MenuBarIconView: View {
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        // Show the rotating title with styled orange "C"
        Text(usageMonitor.getCurrentTitle())
        .onAppear {
            print("MenuBarIconView appeared")
            usageMonitor.configure(with: preferences)
        }
        .onChange(of: preferences.updateInterval) { _ in
            usageMonitor.configure(with: preferences)
        }
        .onChange(of: preferences.rotationInterval) { _ in
            usageMonitor.configure(with: preferences)
        }
        .onChange(of: preferences.ccusageCommandPath) { _ in
            usageMonitor.refreshData()
        }
    }
}