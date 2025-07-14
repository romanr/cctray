//
//  CCTrayApp.swift
//  CCTray
//
//  Created by Robert Goniszewski on 11/07/2025.
//

import SwiftUI

@main
struct CCTrayApp: App {
    @StateObject private var usageMonitor = UsageMonitor()
    @StateObject private var preferences = AppPreferences()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(usageMonitor)
                .environmentObject(preferences)
        } label: {
            MenuBarIconView()
                .environmentObject(usageMonitor)
                .environmentObject(preferences)
        }
        
        Settings {
            PreferencesView()
                .environmentObject(preferences)
        }
    }
}
