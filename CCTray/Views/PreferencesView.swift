import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .environmentObject(preferences)
                .environmentObject(notificationManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
            
            DisplayPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "eye")
                    Text("Display")
                }
            
            AdvancedPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "terminal")
                    Text("Advanced")
                }
            
            AboutPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
        }
        .frame(minWidth: 520, idealWidth: 540, maxWidth: 600, minHeight: 520, idealHeight: 540, maxHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct GeneralPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    @EnvironmentObject var notificationManager: NotificationManager
    
    // State for collapsible sections
    @State private var tokenNotificationsExpanded = false
    @State private var sessionNotificationsExpanded = false
    @State private var tokenNotificationTab = 0
    @State private var showingLegend = false
    
    // State for token limit validation
    @State private var tokenLimitValidationMessage: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // All sections in vertical stack with consistent spacing
            
            // Claude Plan Selection
            VerticalPreferenceSection("Claude Plan", subtitle: "Select your actual Claude plan for accurate burn rate thresholds") {
                ClaudePlanSelector(
                    selectedPlan: $preferences.selectedClaudePlan,
                    customLowThreshold: $preferences.customLowBurnRateThreshold,
                    customHighThreshold: $preferences.customHighBurnRateThreshold,
                    lowThreshold: preferences.lowBurnRateThreshold,
                    highThreshold: preferences.highBurnRateThreshold
                )
            }
            
            // Usage Metrics
            VerticalPreferenceSection("Usage Metrics", subtitle: "Choose which metrics to display in the menu bar") {
                IconPreferenceToggle("Show Cost", description: "Current session cost in USD", iconType: .cost, isOn: $preferences.showCost)
                IconPreferenceToggle("Show Burn Rate", description: "Token consumption rate with indicators", iconType: .burnRate, isOn: $preferences.showBurnRate)
                IconPreferenceToggle("Show Remaining Time", description: "Estimated time remaining in session", iconType: .remainingTime, isOn: $preferences.showRemainingTime)
                IconPreferenceToggle("Show Projected Cost", description: "Projected total session cost", iconType: .projectedCost, isOn: $preferences.showProjectedCost)
                IconPreferenceToggle("Show Token Limit", description: "Token usage against personal limit", iconType: .tokenLimit, isOn: $preferences.showTokenLimit)
            }
            
            // Legend
            VerticalPreferenceSection("Legend", subtitle: "View explanations of all usage metrics and their icons") {
                PreferenceButton(
                    "Show Legend",
                    description: "Display a comprehensive guide to all usage metrics, icons, and indicators",
                    style: .plain
                ) {
                    showingLegend = true
                }
            }
            
            // Update Settings
            VerticalPreferenceSection("Update Settings") {
                PreferenceTimeSlider(
                    "Update Interval:",
                    value: $preferences.updateInterval,
                    range: 1...30,
                    step: 5,
                    unit: "seconds",
                    sliderWidth: 100
                )
            }
            
            // Session Data
            VerticalPreferenceSection("Session Data", subtitle: "Additional session tracking metrics") {
                IconPreferenceToggle("Show API Calls", description: "Number of API calls in current session", iconType: .apiCalls, isOn: $preferences.showApiCalls)
                IconPreferenceToggle("Show Sessions Started Today", description: "Count of Claude sessions started today", iconType: .sessionsToday, isOn: $preferences.showSessionsToday)
            }
            
            // Startup
            VerticalPreferenceSection("Startup") {
                PreferenceToggle("Launch at Login", isOn: $preferences.launchAtLogin)
            }
            
            // Token Limit
            VerticalPreferenceSection("Token Limit") {
                PreferenceToggle("Enable Token Limit Monitoring", 
                               description: "Monitor token usage against your personal limit",
                               isOn: $preferences.tokenLimitEnabled)
                
                if preferences.tokenLimitEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        PreferenceRow("Token Limit:") {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Enter limit or 0 for unlimited", text: Binding(
                                    get: { formatTokenLimitForDisplay(preferences.tokenLimitValue) },
                                    set: { newValue in
                                        let (result, message) = parseTokenLimitWithValidation(newValue)
                                        preferences.tokenLimitValue = result
                                        tokenLimitValidationMessage = message
                                        
                                        // Clear validation message after 4 seconds if there's a message
                                        if message != nil {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                                tokenLimitValidationMessage = nil
                                            }
                                        }
                                    }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 150)
                                
                                Text("Use 0 for unlimited or enter a number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let validationMessage = tokenLimitValidationMessage {
                                    Text(validationMessage)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        
                        PreferenceSlider(
                            "Warning Threshold:",
                            description: "Get warned when reaching this percentage of your limit",
                            value: $preferences.tokenLimitWarningThreshold,
                            range: 50...95,
                            step: 5,
                            formatter: { "\(Int($0))%" }
                        )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                }
            }
            
            // Full-width collapsible sections for complex features
            CollapsiblePreferenceSection(
                "Token Limit Notifications",
                subtitle: "Get notified when approaching your token limit",
                isExpanded: $tokenNotificationsExpanded
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    // Main toggle
                    PreferenceToggle(
                        "Enable Token Limit Notifications",
                        description: "Get notified when approaching your token limit",
                        isOn: $preferences.tokenLimitNotificationsEnabled
                    )
                    
                    if preferences.tokenLimitNotificationsEnabled {
                        // Organized content using specialized components
                        VStack(alignment: .leading, spacing: 16) {
                            // Threshold Configuration
                            NotificationThresholdGroup(
                                warningThreshold: $preferences.tokenLimitNotificationWarningThreshold,
                                urgentThreshold: $preferences.tokenLimitUrgentThreshold,
                                criticalThreshold: $preferences.tokenLimitCriticalThreshold
                            )
                            
                            // Priority Configuration
                            NotificationPriorityGroup(
                                warningPriority: $preferences.warningNotificationPriority,
                                urgentPriority: $preferences.urgentNotificationPriority,
                                criticalPriority: $preferences.criticalNotificationPriority
                            )
                            
                            // Additional Settings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Settings")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ModernSoundToggle(
                                        "Play Sound",
                                        description: "Choose notification sound",
                                        selectedSound: $preferences.tokenNotificationSound
                                    )
                                    
                                    PreferenceSlider(
                                        "Daily Limit:",
                                        description: "Maximum notifications per day",
                                        value: Binding(
                                            get: { Double(preferences.maxTokenNotificationsPerDay) },
                                            set: { preferences.maxTokenNotificationsPerDay = Int($0) }
                                        ),
                                        range: 1...10,
                                        step: 1,
                                        formatter: { "\(Int($0))" }
                                    )
                                    
                                    PreferenceToggle(
                                        "Enable Quiet Hours",
                                        description: "Disable notifications during specific hours",
                                        isOn: $preferences.tokenNotificationQuietHoursEnabled
                                    )
                                    
                                    if preferences.tokenNotificationQuietHoursEnabled {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Start:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                DatePicker("", selection: Binding(
                                                    get: {
                                                        Calendar.current.date(bySettingHour: preferences.tokenNotificationQuietStartHour, minute: 0, second: 0, of: Date()) ?? Date()
                                                    },
                                                    set: { newDate in
                                                        preferences.tokenNotificationQuietStartHour = Calendar.current.component(.hour, from: newDate)
                                                    }
                                                ), displayedComponents: .hourAndMinute)
                                                .datePickerStyle(CompactDatePickerStyle())
                                                .frame(width: 80)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("End:")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                DatePicker("", selection: Binding(
                                                    get: {
                                                        Calendar.current.date(bySettingHour: preferences.tokenNotificationQuietEndHour, minute: 0, second: 0, of: Date()) ?? Date()
                                                    },
                                                    set: { newDate in
                                                        preferences.tokenNotificationQuietEndHour = Calendar.current.component(.hour, from: newDate)
                                                    }
                                                ), displayedComponents: .hourAndMinute)
                                                .datePickerStyle(CompactDatePickerStyle())
                                                .frame(width: 80)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.leading, 16)
                                        
                                        Text("Notifications will be silenced during these hours")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                    }
                }
            }
            
            // Session End Notifications as collapsible section
            CollapsiblePreferenceSection(
                "Session End Notifications", 
                subtitle: "Get notified before your Claude session ends",
                isExpanded: $sessionNotificationsExpanded
            ) {
                NotificationPermissionView(
                    notificationManager: notificationManager,
                    enableNotifications: $preferences.enableSessionEndNotifications,
                    notificationMinutes: $preferences.sessionEndNotificationMinutes,
                    selectedSound: $preferences.sessionEndNotificationSound,
                    notificationPriority: $preferences.sessionEndNotificationPriority
                )
            }
        }
        .preferenceTabLayout()
        .sheet(isPresented: $showingLegend) {
            LegendView()
        }
    }
    
    // MARK: - Token Limit Formatting Helpers
    
    /// Formats a token limit value for display using native locale-aware formatting
    private func formatTokenLimitForDisplay(_ value: String) -> String {
        // Handle legacy "max" value by converting to "0"
        if value.lowercased() == "max" {
            return "0"
        }
        
        // Handle "0" for unlimited
        if value == "0" {
            return "0"
        }
        
        // Try to parse as number and format with locale-aware separators
        if let number = Int(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            formatter.locale = Locale.current
            // Use system locale for native formatting (commas in US, periods in Europe, etc.)
            return formatter.string(from: NSNumber(value: number)) ?? value
        }
        
        // If we can't parse as Int, try to clean up and reformat
        let cleanedValue = removeSeparators(from: value)
        
        if let number = Int(cleanedValue) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            formatter.locale = Locale.current
            return formatter.string(from: NSNumber(value: number)) ?? value
        }
        
        return value
    }
    
    // MARK: - Token Limit Parsing Helper Functions
    
    /// Removes all known separator characters from a string, returning cleaned digits
    private func removeSeparators(from input: String) -> String {
        return input.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "\t", with: "") // Tab character
            .replacingOccurrences(of: "\u{00A0}", with: "") // Non-breaking space
            .replacingOccurrences(of: "\u{202F}", with: "") // Narrow no-break space
            .replacingOccurrences(of: "\u{2009}", with: "") // Thin space
    }
    
    /// Validates European-style number formatting (e.g., "85.000.000")
    private func isValidEuropeanFormat(_ input: String) -> Bool {
        let components = input.components(separatedBy: ".")
        
        // Must have at least 2 components (e.g., "1.000")
        guard components.count >= 2 else { return false }
        
        // For 2 components (e.g., "1.000"), allow if second part is exactly 3 digits
        if components.count == 2 {
            // Check if it looks like European thousands (1.000, 10.000, 100.000)
            // vs decimal (1.5, 12.34)
            if components[1].count == 3 && components[1].allSatisfy(\.isNumber) &&
               components[0].count >= 1 && components[0].count <= 3 && 
               components[0].allSatisfy(\.isNumber) {
                return true
            }
            return false
        }
        
        // For 3+ components (e.g., "1.000.000"), validate each group
        for i in 1..<components.count {
            // Each group should be exactly 3 digits (except first)
            if components[i].count != 3 || !components[i].allSatisfy(\.isNumber) {
                return false
            }
        }
        // First component should be 1-3 digits
        if components[0].count == 0 || components[0].count > 3 || !components[0].allSatisfy(\.isNumber) {
            return false
        }
        
        return true
    }
    
    /// Attempts to parse input using NumberFormatter with multiple locales
    private func parseUsingNumberFormatter(_ input: String) -> (value: Int?, isValid: Bool) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0 // Reject decimals
        
        // Try multiple locales to handle various number formats
        let locales = [
            Locale.current,
            Locale(identifier: "en_US"),
            Locale(identifier: "en_GB"),
            Locale(identifier: "de_DE"),
            Locale(identifier: "fr_FR")
        ]
        
        for locale in locales {
            formatter.locale = locale
            if let number = formatter.number(from: input) {
                return (number.intValue, true)
            }
        }
        
        return (nil, false)
    }
    
    /// Validates that a token limit value is within acceptable bounds
    private func validateTokenLimitBounds(_ value: Int) -> (isValid: Bool, errorMessage: String?) {
        if value < 0 {
            return (false, "Negative numbers are not allowed")
        }
        
        if value > 1_000_000_000 {
            return (false, "Token limit cannot exceed 1 billion tokens")
        }
        
        return (true, nil)
    }

    /// Parses a token limit input from user, removing locale-aware separators and handling "0" for unlimited
    private func parseTokenLimitFromInput(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle "0" for unlimited
        if trimmed == "0" {
            return "0"
        }
        
        // Handle legacy "max" keywords
        if trimmed.lowercased() == "max" {
            return "0"
        }
        
        // Reject negative numbers
        if trimmed.hasPrefix("-") {
            print("DEBUG: parseTokenLimitFromInput - rejected negative number: '\(input)'")
            return "0"
        }
        
        // Check for decimal points - these should be rejected, not parsed
        if trimmed.contains(".") {
            // Check if it's a valid European-style format (e.g., "85.000.000")
            if trimmed.components(separatedBy: ".").count > 2 {
                if !isValidEuropeanFormat(trimmed) {
                    print("DEBUG: parseTokenLimitFromInput - rejected invalid format: '\(input)'")
                    return "0"
                }
                // Continue processing as European format
            } else {
                // Single decimal point - this is a decimal number, reject it
                print("DEBUG: parseTokenLimitFromInput - rejected decimal number: '\(input)'")
                return "0"
            }
        }
        
        // Remove separators for direct digit extraction
        let digitsOnly = removeSeparators(from: trimmed)
        
        // Validate it's only digits and reasonable size
        if let number = Int(digitsOnly), !digitsOnly.isEmpty, number >= 0 {
            let (isValid, _) = validateTokenLimitBounds(number)
            if !isValid {
                print("DEBUG: parseTokenLimitFromInput - rejected too large: '\(input)' (\(number) tokens)")
                return "0"
            }
            
            print("DEBUG: parseTokenLimitFromInput - input: '\(input)', parsed: '\(digitsOnly)'")
            return digitsOnly
        }
        
        // Fallback: Try to parse using NumberFormatter to handle locale-aware input
        let (value, isValid) = parseUsingNumberFormatter(trimmed)
        
        if isValid, let intValue = value {
            let (boundsValid, _) = validateTokenLimitBounds(intValue)
            if !boundsValid {
                if intValue < 0 {
                    print("DEBUG: parseTokenLimitFromInput - locale fallback rejected negative number: '\(input)' (\(intValue) tokens)")
                } else {
                    print("DEBUG: parseTokenLimitFromInput - locale fallback rejected too large: '\(input)' (\(intValue) tokens)")
                }
                return "0"
            }
            
            let result = String(intValue)
            print("DEBUG: parseTokenLimitFromInput - locale fallback - input: '\(input)', parsed: '\(result)'")
            return result
        }
        
        // Final fallback: return "0" if we can't parse anything valid
        print("DEBUG: parseTokenLimitFromInput - failed to parse - input: '\(input)', returning '0'")
        return "0"
    }
    
    /// Enhanced parsing function that returns both the parsed result and a user-friendly validation message
    private func parseTokenLimitWithValidation(_ input: String) -> (result: String, message: String?) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle "0" for unlimited
        if trimmed == "0" {
            return ("0", nil)
        }
        
        // Handle empty input
        if trimmed.isEmpty {
            return ("0", nil)
        }
        
        // Handle legacy "max" keywords
        if trimmed.lowercased() == "max" {
            return ("0", "Legacy 'max' converted to unlimited (0)")
        }
        
        // Reject negative numbers
        if trimmed.hasPrefix("-") {
            return ("0", "Negative numbers are not allowed")
        }
        
        // Check for decimal points - these should be rejected, not parsed
        if trimmed.contains(".") {
            // Check if it's a valid European-style format (e.g., "85.000.000")
            if trimmed.components(separatedBy: ".").count > 2 {
                if !isValidEuropeanFormat(trimmed) {
                    return ("0", "Invalid number format")
                }
                // Continue processing as European format
            } else {
                // Single decimal point - this is a decimal number, reject it
                return ("0", "Decimal numbers are not allowed - use whole numbers only")
            }
        }
        
        // Remove separators for direct digit extraction
        let digitsOnly = removeSeparators(from: trimmed)
        
        // Validate it's only digits and reasonable size
        if let number = Int(digitsOnly), !digitsOnly.isEmpty, number >= 0 {
            let (isValid, errorMessage) = validateTokenLimitBounds(number)
            if !isValid {
                return ("0", errorMessage)
            }
            
            return (digitsOnly, nil)
        }
        
        // Fallback: Try to parse using NumberFormatter to handle locale-aware input
        let (value, isValid) = parseUsingNumberFormatter(trimmed)
        
        if isValid, let intValue = value {
            let (boundsValid, errorMessage) = validateTokenLimitBounds(intValue)
            if !boundsValid {
                return ("0", errorMessage)
            }
            
            return (String(intValue), nil)
        }
        
        // Final fallback: return "0" if we can't parse anything valid
        return ("0", "Invalid number format - please enter a valid number")
    }
}

struct DisplayPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferenceSection("Cost Display") {
                PreferencePicker(
                    "Decimal Places:",
                    selection: $preferences.costDecimalPlaces,
                    options: [
                        (0, "0"),
                        (1, "1"),
                        (2, "2"),
                        (3, "3")
                    ],
                    style: .segmented
                )
            }
            
            PreferenceSection("Burn Rate Display") {
                PreferencePicker(
                    "Format:",
                    selection: $preferences.burnRateFormat,
                    options: BurnRateFormat.allCases.map { ($0, $0.title) },
                    style: .segmented
                )
                
                PreferenceRow("Preview:") {
                    Text(preferences.burnRateFormat.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            PreferenceSection("Burn Rate Thresholds") {
                ClaudePlanSelector(
                    selectedPlan: $preferences.selectedClaudePlan,
                    customLowThreshold: $preferences.customLowBurnRateThreshold,
                    customHighThreshold: $preferences.customHighBurnRateThreshold,
                    lowThreshold: preferences.lowBurnRateThreshold,
                    highThreshold: preferences.highBurnRateThreshold
                )
            }
            
            PreferenceSection("Display Settings") {
                PreferenceTimeSlider(
                    "Rotation Speed:",
                    value: $preferences.rotationInterval,
                    range: 1...30,
                    step: 5,
                    unit: "seconds",
                    sliderWidth: 120
                )
            }
            
            PreferenceSection("Icon Display", subtitle: "Replace icons with text labels in the menu bar") {
                PreferenceToggle("Use \"COST\" instead of \"$\"", isOn: $preferences.useTextForCost)
                PreferenceToggle("Use \"BURN\" instead of burn rate icons", isOn: $preferences.useTextForBurnRate)
                PreferenceToggle("Use \"TIME\" instead of \"⏱️\"", isOn: $preferences.useTextForRemainingTime)
                PreferenceToggle("Use \"PROJ\" instead of \"📊\"", isOn: $preferences.useTextForProjectedCost)
                PreferenceToggle("Use \"API\" instead of \"🔄\"", isOn: $preferences.useTextForApiCalls)
                PreferenceToggle("Use \"SESS\" instead of \"S:\"", isOn: $preferences.useTextForSessionsToday)
                PreferenceToggle("Use \"TOK\" instead of token limit icons", isOn: $preferences.useTextForTokenLimit)
            }
            
            PreferenceSection("Menu Bar Icon Enhancements", subtitle: "Enhanced visual indicators for the menu bar icon") {
                PreferenceToggle("Enable color-coded icon states", isOn: $preferences.enableColorCodedIcons)
                    .help("Shows green (normal), yellow (warning), or red (critical) icon colors based on usage thresholds")
                
                PreferenceToggle("Show progress indicator", isOn: $preferences.enableProgressIndicator)
                    .help("Display progress indication showing token usage percentage")
                
                if preferences.enableProgressIndicator {
                    PreferencePicker(
                        "Progress Style:",
                        selection: $preferences.progressIndicatorStyle,
                        options: ProgressIndicatorStyle.allCases.map { ($0, $0.title) },
                        style: .segmented
                    )
                    .help(preferences.progressIndicatorStyle.description)
                    .padding(.leading, 16)
                    
                    if preferences.progressIndicatorStyle == .bottomRightDot {
                        PreferencePicker(
                            "Dot Position:",
                            selection: $preferences.dotIndicatorPosition,
                            options: DotPosition.allCases.map { ($0, $0.title) },
                            style: .segmented
                        )
                        .help("Choose where to position the status dot on the icon")
                        .padding(.leading, 16)
                    }
                }
                
                PreferenceToggle("Enable pulsing animation", isOn: $preferences.enablePulseAnimation)
                    .help("Icon pulses when approaching usage limits to draw attention")
            }
        }
        .preferenceTabLayout()
    }
}

struct AdvancedPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferenceSection("Node.js Configuration") {
                PreferenceTextField(
                    "Node.js Command:",
                    description: "Use 'node' to auto-detect, or provide full path. Default works with Homebrew, nvm, and system installations.",
                    placeholder: "node command or full path",
                    text: $preferences.ccusageCommandPath
                )
                
                PreferenceTextField(
                    "ccusage Script:",
                    description: "Full path to the ccusage script. Default works with nvm installations.",
                    placeholder: "Path to ccusage script",
                    text: $preferences.ccusageScriptPath
                )
            }
            
            PreferenceSection("Reset") {
                PreferenceButton(
                    "Reset to Defaults",
                    description: "This will reset all preferences to their default values.",
                    style: .plain
                ) {
                    resetToDefaults()
                }
            }
        }
        .preferenceTabLayout()
    }
    
    private func resetToDefaults() {
        preferences.updateInterval = 5.0
        preferences.rotationInterval = 5.0
        preferences.showCost = true
        preferences.showBurnRate = true
        preferences.showRemainingTime = true
        preferences.showProjectedCost = false
        preferences.showApiCalls = false
        preferences.showSessionsToday = false
        preferences.showTokenLimit = false
        preferences.selectedClaudePlan = .pro
        preferences.customLowBurnRateThreshold = 300.0
        preferences.customHighBurnRateThreshold = 700.0
        preferences.customInputTokenCost = 3.0
        preferences.customOutputTokenCost = 15.0
        preferences.customMonthlySpendLimit = 0.0
        preferences.costDecimalPlaces = 2
        preferences.burnRateFormat = .category
        // Text replacement preferences
        preferences.useTextForCost = false
        preferences.useTextForBurnRate = false
        preferences.useTextForRemainingTime = false
        preferences.useTextForProjectedCost = false
        preferences.useTextForApiCalls = false
        preferences.useTextForSessionsToday = false
        preferences.useTextForTokenLimit = false
        preferences.ccusageCommandPath = "node"
        preferences.ccusageScriptPath = "~/.nvm/versions/node/v20.11.0/lib/node_modules/ccusage/dist/index.js"
        preferences.launchAtLogin = false
        preferences.enableSessionEndNotifications = false
        preferences.sessionEndNotificationMinutes = 10
        preferences.sessionEndNotificationSound = "default"
        preferences.sessionEndNotificationPriority = "active"
        preferences.tokenLimitEnabled = false
        preferences.tokenLimitValue = "0"
        preferences.tokenLimitWarningThreshold = 80.0
        // Token limit notification defaults
        preferences.tokenLimitNotificationsEnabled = false
        preferences.tokenLimitNotificationWarningThreshold = 75.0
        preferences.tokenLimitUrgentThreshold = 85.0
        preferences.tokenLimitCriticalThreshold = 95.0
        preferences.warningNotificationPriority = "active"
        preferences.urgentNotificationPriority = "active"
        preferences.criticalNotificationPriority = "timeSensitive"
        preferences.maxTokenNotificationsPerDay = 6
        preferences.tokenNotificationSound = "default"
        preferences.tokenNotificationQuietHoursEnabled = false
        preferences.tokenNotificationQuietStartHour = 22
        preferences.tokenNotificationQuietEndHour = 8
        // Icon enhancement defaults
        preferences.enableColorCodedIcons = true
        preferences.enableProgressIndicator = true
        preferences.enablePulseAnimation = true
        preferences.progressIndicatorStyle = .bottomRightDot
        preferences.dotIndicatorPosition = .bottomRight
    }
}

struct AboutPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferenceSection("App Information") {
                PreferenceRow("App Name:") {
                    Text("CCTray")
                }
                
                PreferenceRow("Version:") {
                    Text(appVersion)
                }
                
                PreferenceRow("Description:") {
                    Text("macOS menu bar app for Claude Code usage monitoring")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            PreferenceSection("Author") {
                PreferenceRow("Name:") {
                    Text(GitInfo.authorName)
                }
                
                PreferenceRow("GitHub:") {
                    Button(GitInfo.authorHandle) {
                        if let url = URL(string: "https://github.com/goniszewski") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(LinkButtonStyle())
                }
            }
            
            PreferenceSection("Repository") {
                PreferenceRow("Repository:") {
                    Button(GitInfo.repositoryDisplayURL) {
                        if let url = URL(string: GitInfo.repositoryURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                
                PreferenceRow("Latest Commit:") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(GitInfo.shortCommitHash)
                            .foregroundColor(.secondary)
                            .font(.system(.caption, design: .monospaced))
                        Text(GitInfo.formattedCommitDate)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            PreferenceSection("Copyright") {
                Text(appCopyright)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .preferenceTabLayout()
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var appCopyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "© 2025 Robert Goniszewski"
    }
}

struct LinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.accentColor)
            .underline()
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Preview removed for Swift Package compatibility
