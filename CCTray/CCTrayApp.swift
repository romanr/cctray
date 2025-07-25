//
//  CCTrayApp.swift
//  CCTray
//
//  Created by Robert Goniszewski on 11/07/2025.
//

import SwiftUI

@main
struct CCTrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var usageMonitor = UsageMonitor()
    @StateObject private var preferences = AppPreferences()
    @StateObject private var notificationManager = NotificationManager()
    
    init() {
        // Configure the app delegate with required dependencies
        // This needs to be done after the StateObjects are initialized
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(usageMonitor)
                .environmentObject(preferences)
                .onAppear {
                    // Migrate sound preferences from boolean to string format
                    preferences.migrateSoundPreferences()
                    
                    // Configure app delegate with dependencies
                    appDelegate.configure(
                        notificationManager: notificationManager,
                        preferences: preferences,
                        usageMonitor: usageMonitor
                    )
                    
                    // Configure usage monitor with dependencies
                    usageMonitor.configure(with: preferences, notificationManager: notificationManager)
                }
        } label: {
            MenuBarIconView()
                .environmentObject(usageMonitor)
                .environmentObject(preferences)
                .environmentObject(notificationManager)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            PreferencesView()
                .environmentObject(preferences)
                .environmentObject(notificationManager)
        }
        
        Window("ccusage Output", id: "ccusage-output") {
            CCUsageOutputView()
                .environmentObject(preferences)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Window("Legend", id: "legend") {
            LegendView()
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
        Window("Usage Analytics", id: "chart-dashboard") {
            ChartDashboardView()
                .environmentObject(usageMonitor)
                .environmentObject(preferences)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
        
    }
}
