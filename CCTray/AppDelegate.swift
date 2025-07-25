//
//  AppDelegate.swift
//  CCTray
//
//  Created by Robert Goniszewski on 14/07/2025.
//

import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var aboutWindowController: NSWindowController?
    
    // References to app components for notification handling
    private var notificationManager: NotificationManager?
    private var preferences: AppPreferences?
    private var usageMonitor: UsageMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Override the default About menu item
        DispatchQueue.main.async {
            self.setupAboutMenu()
        }
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Configuration
    
    func configure(notificationManager: NotificationManager, preferences: AppPreferences, usageMonitor: UsageMonitor) {
        self.notificationManager = notificationManager
        self.preferences = preferences
        self.usageMonitor = usageMonitor
    }
    
    private func setupAboutMenu() {
        // Find the main menu's application menu
        guard let mainMenu = NSApplication.shared.mainMenu,
              let appMenu = mainMenu.items.first?.submenu else {
            return
        }
        
        // Find the About menu item
        for item in appMenu.items {
            if item.title.hasPrefix("About") {
                // Replace the action with our custom one
                item.target = self
                item.action = #selector(showAboutWindow)
                break
            }
        }
    }
    
    @objc private func showAboutWindow() {
        // If window already exists, just show it
        if let windowController = aboutWindowController {
            windowController.window?.makeKeyAndOrderFront(nil)
            windowController.window?.orderFrontRegardless()
            return
        }
        
        // Create our custom About window
        let aboutView = AboutWindowView()
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "About CCTray"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.center()
        
        // Make it behave like a standard About window
        window.hidesOnDeactivate = false
        window.level = .normal  // Changed from .floating to .normal for better behavior
        window.isMovableByWindowBackground = true
        
        // Set minimum and maximum size to prevent resizing
        window.minSize = NSSize(width: 400, height: 500)
        window.maxSize = NSSize(width: 400, height: 500)
        
        aboutWindowController = NSWindowController(window: window)
        aboutWindowController?.showWindow(nil)
        
        // Bring to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let notification = response.notification
        
        print("Notification action received: \(actionIdentifier)")
        
        switch actionIdentifier {
        case "VIEW_USAGE":
            handleViewUsageAction(notification: notification)
        case "SNOOZE":
            handleSnoozeAction(notification: notification)
        case "DISABLE_TODAY":
            handleDisableTodayAction(notification: notification)
        default:
            print("Unknown notification action: \(actionIdentifier)")
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow notifications to be shown even when app is active
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // MARK: - Notification Action Handlers
    
    private func handleViewUsageAction(notification: UNNotification) {
        print("Handling VIEW_USAGE action")
        
        // Bring app to front and refresh data
        DispatchQueue.main.async {
            // Refresh data to ensure latest info is shown
            self.usageMonitor?.refreshData()
            
            // Activate the app - this will make the menu bar icon visible
            // The user can then click it to view detailed usage information
            _ = self.findStatusBarButton()
        }
    }
    
    private func findStatusBarButton() -> NSStatusBarButton? {
        // For a menu bar app like CCTray, it's difficult to programmatically find the status bar button
        // since NSStatusBar.system.items is not available. As an alternative approach,
        // we'll simply activate the app which will make it visible to the user.
        // This is more reliable than trying to programmatically trigger the menu bar extra.
        
        // Just activate the app - the user can then click the menu bar icon
        NSApp.activate(ignoringOtherApps: true)
        return nil
    }
    
    private func handleSnoozeAction(notification: UNNotification) {
        print("Handling SNOOZE action")
        
        guard let notificationManager = self.notificationManager else {
            print("NotificationManager not available for snooze action")
            return
        }
        
        let notificationIdentifier = notification.request.identifier
        let snoozeMinutes = 15 // Default snooze duration
        
        Task {
            await notificationManager.snoozeTokenLimitNotification(notificationIdentifier, minutes: snoozeMinutes)
        }
    }
    
    private func handleDisableTodayAction(notification: UNNotification) {
        print("Handling DISABLE_TODAY action")
        
        guard let notificationManager = self.notificationManager else {
            print("NotificationManager not available for disable today action")
            return
        }
        
        Task {
            await notificationManager.disableTokenLimitNotificationsForToday()
        }
    }
}