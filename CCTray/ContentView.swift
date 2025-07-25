//
//  ContentView.swift
//  CCTray
//
//  Created by Robert Goniszewski on 11/07/2025.
//

import SwiftUI

enum FocusableMenuItems: CaseIterable {
    case refresh
    case terminal
    case output
    case legend
    case dashboard
    case preferences
    case quit
}

enum FocusDirection {
    case up
    case down
}

struct ContentView: View {
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    @Environment(\.openWindow) private var openWindow
    @FocusState private var focusedItem: FocusableMenuItems?
    
    private var refreshButtonText: String {
        let result: String
        if usageMonitor.isLoading {
            result = "Refreshing..."
        } else if usageMonitor.secondsUntilNextRefresh > 0 {
            result = "Refresh now (\(usageMonitor.secondsUntilNextRefresh)s)"
        } else {
            result = "Refresh now"
        }
        print("DEBUG: refreshButtonText computed: '\(result)' (secondsUntilNextRefresh=\(usageMonitor.secondsUntilNextRefresh), isLoading=\(usageMonitor.isLoading))")
        return result
    }
    
    private var notificationsEnabled: Bool {
        preferences.enableSessionEndNotifications || preferences.tokenLimitNotificationsEnabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("CCTray")
                    .font(.headline)
                    .foregroundColor(ClaudeColors.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Native menu divider
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Usage information
            VStack(alignment: .leading, spacing: 0) {
                if preferences.enableProgressBars || preferences.enableTrendIndicators || preferences.enableSparklines {
                    EnhancedUsageInfoView(info: usageMonitor.getDetailedInfo())
                } else {
                    UsageInfoView(info: usageMonitor.getDetailedInfo())
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Usage information")
            .accessibilityHint("Current Claude Code usage metrics including cost, burn rate, and session details")
            
            // Native menu divider
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Menu actions
            VStack(alignment: .leading, spacing: 2) {
                Button(action: {
                    if !usageMonitor.isLoading {
                        usageMonitor.refreshData()
                    }
                }) {
                    ZStack(alignment: .leading) {
                        // Hidden reference text for consistent width
                        Text("Refresh now (00s)")
                            .font(.system(size: 13, design: .monospaced))
                            .hidden()
                        
                        // Actual visible text
                        Text(refreshButtonText)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentTransition(.identity)
                            .foregroundColor(usageMonitor.isLoading ? .secondary : ClaudeColors.primary)
                            .opacity(usageMonitor.isLoading ? 0.6 : 1.0)
                    }
                    .frame(minWidth: 140, alignment: .leading)
                }
                .menuItemStyle(disabled: usageMonitor.isLoading)
                .focused($focusedItem, equals: .refresh)
                .accessibilityLabel(usageMonitor.isLoading ? "Refreshing usage data" : "Refresh usage data now")
                .accessibilityHint(usageMonitor.isLoading ? "Data is currently being refreshed" : "Tap to refresh Claude Code usage data")
                .keyboardShortcut("r", modifiers: [.command])
                .animation(.none, value: refreshButtonText)
                .transaction { transaction in
                    transaction.animation = .none
                    transaction.disablesAnimations = true
                }
                .drawingGroup()
                
                Button("Open ccusage in Terminal") {
                    openCCUsageInTerminal()
                }
                .menuItemStyle()
                .focused($focusedItem, equals: .terminal)
                .accessibilityLabel("Open ccusage in Terminal")
                .accessibilityHint("Opens a Terminal window running the ccusage command")
                .keyboardShortcut("t", modifiers: [.command])
                
                Button("Show ccusage Output") {
                    openCCUsageWindow()
                }
                .menuItemStyle()
                .focused($focusedItem, equals: .output)
                .accessibilityLabel("Show ccusage output window")
                .accessibilityHint("Opens a window displaying the raw ccusage command output")
                .keyboardShortcut("o", modifiers: [.command])
                
                Button("Show Legend") {
                    openWindow(id: "legend")
                }
                .menuItemStyle()
                .focused($focusedItem, equals: .legend)
                .accessibilityLabel("Show legend window")
                .accessibilityHint("Opens a window explaining the symbols and colors used in the app")
                .keyboardShortcut("l", modifiers: [.command])
                
                if preferences.enableChartDashboard {
                    Button("Usage Analytics") {
                        openWindow(id: "chart-dashboard")
                    }
                    .menuItemStyle()
                    .focused($focusedItem, equals: .dashboard)
                    .accessibilityLabel("Show usage analytics dashboard")
                    .accessibilityHint("Opens a comprehensive analytics dashboard with charts and trends")
                    .keyboardShortcut("d", modifiers: [.command])
                }
                
                // Quick Actions Divider
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Actions")
                        .font(.caption)
                        .foregroundColor(ClaudeColors.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 2)
                    
                    Button("Copy Usage Data") {
                        copyUsageDataToClipboard()
                    }
                    .menuItemStyle()
                    .accessibilityLabel("Copy usage data to clipboard")
                    .accessibilityHint("Copies current usage metrics to the clipboard")
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    
                    Button(notificationsEnabled ? "Disable Notifications" : "Enable Notifications") {
                        toggleNotifications()
                    }
                    .menuItemStyle()
                    .accessibilityLabel(notificationsEnabled ? "Disable notifications" : "Enable notifications")
                    .accessibilityHint("Toggles notification settings")
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                }
                .padding(.bottom, 4)
                
                // Main Actions Divider
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                
                SettingsLink {
                    Text("Preferences...")
                }
                .menuItemStyle()
                .focused($focusedItem, equals: .preferences)
                .accessibilityLabel("Open preferences")
                .accessibilityHint("Opens the preferences window to customize app settings")
                .keyboardShortcut(",", modifiers: [.command])
                
                Button("Quit CCTray") {
                    NSApplication.shared.terminate(nil)
                }
                .menuItemStyle()
                .focused($focusedItem, equals: .quit)
                .accessibilityLabel("Quit CCTray")
                .accessibilityHint("Exits the CCTray application")
                .keyboardShortcut("q", modifiers: [.command])
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(minWidth: 300, maxWidth: 400)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: ClaudeColors.primary.opacity(0.1), radius: 6, x: 0, y: 2)
        .onKeyPress(.upArrow) {
            moveFocus(direction: .up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveFocus(direction: .down)
            return .handled
        }
        .onKeyPress(.return) {
            activateFocusedItem()
            return .handled
        }
        .onKeyPress(.space) {
            activateFocusedItem()
            return .handled
        }
        .onKeyPress(.escape) {
            // Close the menu by removing focus
            focusedItem = nil
            return .handled
        }
        .onAppear {
            // Set initial focus to refresh button
            focusedItem = .refresh
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("CCTray menu")
        .accessibilityHint("Use arrow keys to navigate, Return or Space to activate, Escape to close")
    }
    
    private func openCCUsageInTerminal() {
        // Build the command to run in Terminal with proper escaping
        let command: String
        if !preferences.ccusageScriptPath.isEmpty {
            // Use Node.js with script path - escape both paths
            let escapedCommandPath = shellEscape(preferences.ccusageCommandPath)
            let escapedScriptPath = shellEscape(preferences.ccusageScriptPath)
            command = "\(escapedCommandPath) \(escapedScriptPath) blocks --live"
        } else {
            // Use direct command - escape the command path
            let escapedCommandPath = shellEscape(preferences.ccusageCommandPath)
            command = "\(escapedCommandPath) blocks --live"
        }
        
        print("Terminal command to execute: \(command)")
        
        // Create AppleScript to open Terminal and run the command
        // Escape the command string for AppleScript
        let escapedCommand = command.replacingOccurrences(of: "\\", with: "\\\\")
                                   .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "Terminal"
            activate
            do script "\(escapedCommand)"
        end tell
        """
        
        print("AppleScript to execute: \(script)")
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            
            if let error = error {
                print("AppleScript error: \(error)")
                
                // Check if this is an authorization error
                if let errorNumber = error["NSAppleScriptErrorNumber"] as? Int, errorNumber == -1743 {
                    // Show authorization-specific error message
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Terminal Access Permission Required"
                        alert.informativeText = """
                        CCTray needs permission to control Terminal to run the ccusage command.
                        
                        To grant permission:
                        1. Open System Settings (or System Preferences)
                        2. Go to Privacy & Security → Automation
                        3. Find CCTray and check the box for Terminal
                        
                        Then try the "Open ccusage in Terminal" option again.
                        """
                        alert.alertStyle = .informational
                        alert.addButton(withTitle: "Open System Settings")
                        alert.addButton(withTitle: "Cancel")
                        
                        let response = alert.runModal()
                        if response == .alertFirstButtonReturn {
                            // Open System Settings to Privacy & Security
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
                        }
                    }
                } else {
                    // Show generic error for other issues
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Failed to open Terminal"
                        alert.informativeText = "Error: \(error)"
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    private func shellEscape(_ string: String) -> String {
        // Escape shell special characters by wrapping in single quotes
        // and escaping any single quotes within the string
        let escaped = string.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
    
    private func openCCUsageWindow() {
        // Open the ccusage output window using SwiftUI's openWindow
        openWindow(id: "ccusage-output")
    }
    
    // MARK: - Focus Management
    
    private func moveFocus(direction: FocusDirection) {
        guard let currentFocus = focusedItem else {
            focusedItem = .refresh
            return
        }
        
        let allItems = FocusableMenuItems.allCases
        guard let currentIndex = allItems.firstIndex(of: currentFocus) else { return }
        
        switch direction {
        case .up:
            let newIndex = currentIndex > 0 ? currentIndex - 1 : allItems.count - 1
            focusedItem = allItems[newIndex]
        case .down:
            let newIndex = currentIndex < allItems.count - 1 ? currentIndex + 1 : 0
            focusedItem = allItems[newIndex]
        }
    }
    
    private func activateFocusedItem() {
        guard let focused = focusedItem else { return }
        
        switch focused {
        case .refresh:
            if !usageMonitor.isLoading {
                usageMonitor.refreshData()
            }
        case .terminal:
            openCCUsageInTerminal()
        case .output:
            openCCUsageWindow()
        case .legend:
            openWindow(id: "legend")
        case .dashboard:
            openWindow(id: "chart-dashboard")
        case .preferences:
            // SettingsLink doesn't support programmatic activation easily
            // We could add a workaround here if needed
            break
        case .quit:
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Quick Actions
    
    private func copyUsageDataToClipboard() {
        let usageData = formatUsageDataForClipboard()
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(usageData, forType: .string)
    }
    
    private func formatUsageDataForClipboard() -> String {
        let info = usageMonitor.getDetailedInfo()
        var formattedData = "CCTray Usage Data\n"
        formattedData += "================\n"
        formattedData += "Timestamp: \(formatTimestamp(Date()))\n\n"
        
        for line in info {
            if !line.isEmpty {
                formattedData += "\(line)\n"
            }
        }
        
        return formattedData
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func toggleNotifications() {
        if notificationsEnabled {
            // Disable all notifications
            preferences.enableSessionEndNotifications = false
            preferences.tokenLimitNotificationsEnabled = false
        } else {
            // Enable session end notifications as the primary notification type
            preferences.enableSessionEndNotifications = true
        }
    }
}

struct UsageInfoView: View {
    let info: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<info.count, id: \.self) { index in
                InfoRowView(text: info[index])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.quaternaryLabelColor).opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
}

struct InfoRowView: View {
    let text: String
    
    var body: some View {
        if text.isEmpty {
            Divider()
                .padding(.vertical, 2)
        } else {
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(NSColor.secondaryLabelColor))
                .opacity(0.8)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UsageMonitor())
        .environmentObject(AppPreferences())
}
