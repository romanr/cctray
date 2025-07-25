import Foundation
import SwiftUI
import UserNotifications

class AppPreferences: ObservableObject {
    // Update intervals
    @AppStorage("updateInterval") var updateInterval: Double = 5.0
    @AppStorage("rotationInterval") var rotationInterval: Double = 5.0
    
    // Display toggles
    @AppStorage("showCost") var showCost: Bool = true
    @AppStorage("showBurnRate") var showBurnRate: Bool = true
    @AppStorage("showRemainingTime") var showRemainingTime: Bool = true
    @AppStorage("showProjectedCost") var showProjectedCost: Bool = false
    @AppStorage("showApiCalls") var showApiCalls: Bool = false
    @AppStorage("showSessionsToday") var showSessionsToday: Bool = false
    @AppStorage("showTokenLimit") var showTokenLimit: Bool = false
    @AppStorage("showTokenUsage") var showTokenUsage: Bool = false
    
    // Claude plan selection
    @AppStorage("selectedClaudePlan") var selectedClaudePlan: ClaudePlan = .pro
    
    // Burn rate thresholds (used only for custom plan)
    @AppStorage("customLowBurnRateThreshold") var customLowBurnRateThreshold: Double = 300.0
    @AppStorage("customHighBurnRateThreshold") var customHighBurnRateThreshold: Double = 700.0
    
    // Custom plan per-token costs (used only for custom plan)
    @AppStorage("customInputTokenCost") var customInputTokenCost: Double = 3.0 // per 1M tokens
    @AppStorage("customOutputTokenCost") var customOutputTokenCost: Double = 15.0 // per 1M tokens
    @AppStorage("customMonthlySpendLimit") var customMonthlySpendLimit: Double = 0.0 // 0 = unlimited
    
    // Display format
    @AppStorage("costDecimalPlaces") var costDecimalPlaces: Int = 2
    @AppStorage("burnRateFormat") var burnRateFormat: BurnRateFormat = .category
    
    // Text replacement preferences
    @AppStorage("useTextForCost") var useTextForCost: Bool = false
    @AppStorage("useTextForBurnRate") var useTextForBurnRate: Bool = false
    @AppStorage("useTextForRemainingTime") var useTextForRemainingTime: Bool = false
    @AppStorage("useTextForProjectedCost") var useTextForProjectedCost: Bool = false
    @AppStorage("useTextForApiCalls") var useTextForApiCalls: Bool = false
    @AppStorage("useTextForSessionsToday") var useTextForSessionsToday: Bool = false
    @AppStorage("useTextForTokenLimit") var useTextForTokenLimit: Bool = false
    @AppStorage("useTextForTokenUsage") var useTextForTokenUsage: Bool = false
    
    // Command path
    @AppStorage("ccusageCommandPath") var ccusageCommandPath: String = "node"
    @AppStorage("ccusageScriptPath") var ccusageScriptPath: String = "~/.nvm/versions/node/v20.11.0/lib/node_modules/ccusage/dist/index.js"
    
    // Launch at login
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    
    // Session end notifications
    @AppStorage("enableSessionEndNotifications") var enableSessionEndNotifications: Bool = false
    @AppStorage("sessionEndNotificationMinutes") var sessionEndNotificationMinutes: Int = 10
    @AppStorage("sessionEndNotificationSound") var sessionEndNotificationSound: String = "default"
    @AppStorage("sessionEndNotificationPriority") var sessionEndNotificationPriority: String = "active"
    
    // Token limit preferences
    @AppStorage("tokenLimitEnabled") var tokenLimitEnabled: Bool = false
    @AppStorage("tokenLimitValue") var tokenLimitValue: String = "0"
    @AppStorage("tokenLimitWarningThreshold") var tokenLimitWarningThreshold: Double = 80.0
    
    // Token limit notification preferences
    @AppStorage("tokenLimitNotificationsEnabled") var tokenLimitNotificationsEnabled: Bool = false
    @AppStorage("tokenLimitNotificationWarningThreshold") var tokenLimitNotificationWarningThreshold: Double = 75.0
    @AppStorage("tokenLimitUrgentThreshold") var tokenLimitUrgentThreshold: Double = 85.0
    @AppStorage("tokenLimitCriticalThreshold") var tokenLimitCriticalThreshold: Double = 95.0
    
    // Icon enhancement preferences
    @AppStorage("enableColorCodedIcons") var enableColorCodedIcons: Bool = true
    @AppStorage("enableProgressIndicator") var enableProgressIndicator: Bool = true
    @AppStorage("enablePulseAnimation") var enablePulseAnimation: Bool = true
    @AppStorage("progressIndicatorStyle") var progressIndicatorStyle: ProgressIndicatorStyle = .bottomRightDot
    @AppStorage("dotIndicatorPosition") var dotIndicatorPosition: DotPosition = .bottomRight
    @AppStorage("warningNotificationPriority") var warningNotificationPriority: String = "active"
    @AppStorage("urgentNotificationPriority") var urgentNotificationPriority: String = "active"
    @AppStorage("criticalNotificationPriority") var criticalNotificationPriority: String = "timeSensitive"
    @AppStorage("maxTokenNotificationsPerDay") var maxTokenNotificationsPerDay: Int = 6
    @AppStorage("tokenNotificationSound") var tokenNotificationSound: String = "default"
    @AppStorage("tokenNotificationQuietHoursEnabled") var tokenNotificationQuietHoursEnabled: Bool = false
    @AppStorage("tokenNotificationQuietStartHour") var tokenNotificationQuietStartHour: Int = 22
    @AppStorage("tokenNotificationQuietEndHour") var tokenNotificationQuietEndHour: Int = 8
    
    // Chart and visualization preferences
    @AppStorage("enableChartDataCollection") var enableChartDataCollection: Bool = true
    @AppStorage("enableProgressBars") var enableProgressBars: Bool = true
    @AppStorage("enableTrendIndicators") var enableTrendIndicators: Bool = true
    @AppStorage("enableMiniCharts") var enableMiniCharts: Bool = false
    @AppStorage("enableSparklines") var enableSparklines: Bool = false
    @AppStorage("chartTimeRange") var chartTimeRange: String = "session"
    @AppStorage("chartType") var chartType: String = "line"
    @AppStorage("chartColorScheme") var chartColorScheme: String = "adaptive"
    @AppStorage("showChartAnimations") var showChartAnimations: Bool = true
    @AppStorage("showChartDataPoints") var showChartDataPoints: Bool = false
    @AppStorage("showChartTrendLines") var showChartTrendLines: Bool = true
    @AppStorage("enableChartDashboard") var enableChartDashboard: Bool = false
    @AppStorage("chartDataRetentionDays") var chartDataRetentionDays: Int = 7
    
    // Computed properties
    var enabledDisplayModes: [DisplayMode] {
        var modes: [DisplayMode] = []
        if showCost { modes.append(.cost) }
        if showBurnRate { modes.append(.burnRate) }
        if showRemainingTime { modes.append(.remainingTime) }
        if showProjectedCost { modes.append(.projectedCost) }
        if showApiCalls { modes.append(.apiCalls) }
        if showSessionsToday { modes.append(.sessionsToday) }
        if showTokenLimit { modes.append(.tokenLimit) }
        if showTokenUsage { modes.append(.tokenUsage) }
        return modes.isEmpty ? [.cost] : modes // Always show at least cost
    }
    
    // Computed thresholds based on selected plan
    var lowBurnRateThreshold: Double {
        switch selectedClaudePlan {
        case .custom:
            return customLowBurnRateThreshold
        default:
            return selectedClaudePlan.defaultLowThreshold
        }
    }
    
    var highBurnRateThreshold: Double {
        switch selectedClaudePlan {
        case .custom:
            return customHighBurnRateThreshold
        default:
            return selectedClaudePlan.defaultHighThreshold
        }
    }
    
    // Chart computed properties
    var chartTimeRangeEnum: ChartTimeRange {
        ChartTimeRange(rawValue: chartTimeRange) ?? .session
    }
    
    var chartTypeEnum: ChartType {
        ChartType(rawValue: chartType) ?? .line
    }
    
    var chartColorSchemeEnum: ChartColorScheme {
        ChartColorScheme(rawValue: chartColorScheme) ?? .adaptive
    }
    
    var chartConfiguration: ChartConfiguration {
        ChartConfiguration(
            timeRange: chartTimeRangeEnum,
            chartType: chartTypeEnum,
            colorScheme: chartColorSchemeEnum,
            showTrendLine: showChartTrendLines,
            showDataPoints: showChartDataPoints,
            animated: showChartAnimations
        )
    }
    
    // MARK: - Backward Compatibility Properties
    
    /// Backward compatibility: Whether session end notification sound is enabled
    var notificationSound: Bool {
        get { SoundManager.isSoundEnabled(sessionEndNotificationSound) }
        set { 
            sessionEndNotificationSound = newValue ? "default" : ""
        }
    }
    
    /// Backward compatibility: Whether token notification sound is enabled
    var tokenNotificationSoundEnabled: Bool {
        get { SoundManager.isSoundEnabled(tokenNotificationSound) }
        set { 
            tokenNotificationSound = newValue ? "default" : ""
        }
    }
    
    // MARK: - Sound Helper Methods
    
    /// Gets the display name for session end notification sound
    var sessionEndNotificationSoundDisplayName: String {
        SoundManager.displayName(for: sessionEndNotificationSound)
    }
    
    /// Gets the display name for token notification sound
    var tokenNotificationSoundDisplayName: String {
        SoundManager.displayName(for: tokenNotificationSound)
    }
    
    /// Migrates old boolean sound preferences to new string-based preferences
    func migrateSoundPreferences() {
        // Check if migration is needed by looking for old keys
        let defaults = UserDefaults.standard
        
        // Migrate session end notification sound
        if defaults.object(forKey: "notificationSound") != nil {
            let oldValue = defaults.bool(forKey: "notificationSound")
            sessionEndNotificationSound = SoundManager.migrateFromBooleanPreference(oldValue)
            defaults.removeObject(forKey: "notificationSound")
        }
        
        // Migrate token notification sound
        if defaults.object(forKey: "tokenNotificationSoundEnabled") != nil {
            let oldValue = defaults.bool(forKey: "tokenNotificationSoundEnabled")
            tokenNotificationSound = SoundManager.migrateFromBooleanPreference(oldValue)
            defaults.removeObject(forKey: "tokenNotificationSoundEnabled")
        }
    }
    
    // MARK: - Token Limit Notification Helper Methods
    
    /// Converts string priority to UNNotificationInterruptionLevel
    func notificationInterruptionLevel(for priority: String) -> UNNotificationInterruptionLevel {
        switch priority.lowercased() {
        case "passive":
            return .passive
        case "active":
            return .active
        case "timesensitive":
            return .timeSensitive
        case "critical":
            return .critical
        default:
            return .active
        }
    }
    
    /// Checks if current time is within quiet hours
    func isInQuietHours() -> Bool {
        guard tokenNotificationQuietHoursEnabled else { return false }
        
        let now = Calendar.current.component(.hour, from: Date())
        let startHour = tokenNotificationQuietStartHour
        let endHour = tokenNotificationQuietEndHour
        
        if startHour < endHour {
            // Same day (e.g., 9 AM to 5 PM)
            return now >= startHour && now < endHour
        } else {
            // Crosses midnight (e.g., 10 PM to 8 AM)
            return now >= startHour || now < endHour
        }
    }
    
    /// Gets appropriate interruption level for a given threshold percentage
    func getInterruptionLevel(for usagePercentage: Double) -> UNNotificationInterruptionLevel {
        if tokenLimitCriticalThreshold > 0 && usagePercentage >= tokenLimitCriticalThreshold {
            return notificationInterruptionLevel(for: criticalNotificationPriority)
        } else if tokenLimitUrgentThreshold > 0 && usagePercentage >= tokenLimitUrgentThreshold {
            return notificationInterruptionLevel(for: urgentNotificationPriority)
        } else if tokenLimitNotificationWarningThreshold > 0 && usagePercentage >= tokenLimitNotificationWarningThreshold {
            return notificationInterruptionLevel(for: warningNotificationPriority)
        } else {
            return .active
        }
    }
    
    /// Determines notification category based on usage percentage
    func getNotificationCategory(for usagePercentage: Double) -> String {
        if tokenLimitCriticalThreshold > 0 && usagePercentage >= tokenLimitCriticalThreshold {
            return "critical"
        } else if tokenLimitUrgentThreshold > 0 && usagePercentage >= tokenLimitUrgentThreshold {
            return "urgent"
        } else if tokenLimitNotificationWarningThreshold > 0 && usagePercentage >= tokenLimitNotificationWarningThreshold {
            return "warning"
        } else {
            return "info"
        }
    }
}

enum DisplayMode: Int, CaseIterable {
    case cost = 0
    case burnRate = 1
    case remainingTime = 2
    case projectedCost = 3
    case apiCalls = 4
    case sessionsToday = 5
    case tokenLimit = 6
    case tokenUsage = 7
    
    var title: String {
        switch self {
        case .cost:
            return "Cost"
        case .burnRate:
            return "Burn Rate"
        case .remainingTime:
            return "Remaining Time"
        case .projectedCost:
            return "Projected Cost"
        case .apiCalls:
            return "API Calls"
        case .sessionsToday:
            return "Sessions Started Today"
        case .tokenLimit:
            return "Token Limit"
        case .tokenUsage:
            return "Token Usage"
        }
    }
}

enum BurnRateFormat: String, CaseIterable {
    case category = "category"
    case numeric = "numeric"
    
    var title: String {
        switch self {
        case .category:
            return "Category"
        case .numeric:
            return "Numeric"
        }
    }
    
    var description: String {
        switch self {
        case .category:
            return "🟡 MED"
        case .numeric:
            return "🟡 400t/m"
        }
    }
}

enum ClaudePlan: String, CaseIterable, Codable {
    case pro = "pro"
    case max5x = "max5x"
    case max20x = "max20x"
    case apiBased = "apiBased"
    case custom = "custom"
    
    var title: String {
        switch self {
        case .pro:
            return "Pro Plan"
        case .max5x:
            return "Max Plan 5x"
        case .max20x:
            return "Max Plan 20x"
        case .apiBased:
            return "API-Based"
        case .custom:
            return "Custom"
        }
    }
    
    var description: String {
        switch self {
        case .pro:
            return "$20/month • 10-40 prompts per 5 hours"
        case .max5x:
            return "$100/month • 50-200 prompts per 5 hours"
        case .max20x:
            return "$200/month • 200-800 prompts per 5 hours"
        case .apiBased:
            return "Pay-per-token • $3-15/MTok (Sonnet) • $15-75/MTok (Opus)"
        case .custom:
            return "Set your own custom thresholds"
        }
    }
    
    var isSubscriptionPlan: Bool {
        switch self {
        case .pro, .max5x, .max20x:
            return true
        case .apiBased, .custom:
            return false
        }
    }
    
    var hasUsageLimit: Bool {
        switch self {
        case .pro, .max5x, .max20x:
            return true
        case .apiBased, .custom:
            return false
        }
    }
    
    var promptsPerFiveHours: ClosedRange<Int>? {
        switch self {
        case .pro:
            return 10...40
        case .max5x:
            return 50...200
        case .max20x:
            return 200...800
        case .apiBased, .custom:
            return nil
        }
    }
    
    var defaultLowThreshold: Double {
        switch self {
        case .pro:
            return 200.0  // Conservative for Pro ($20/month)
        case .max5x:
            return 500.0  // Higher for Max 5x ($100/month)
        case .max20x:
            return 1000.0 // Highest for Max 20x ($200/month)
        case .apiBased:
            return 150.0  // More sensitive for pay-per-token
        case .custom:
            return 300.0  // Default fallback
        }
    }
    
    var defaultHighThreshold: Double {
        switch self {
        case .pro:
            return 400.0  // Conservative for Pro
        case .max5x:
            return 800.0  // Higher for Max 5x
        case .max20x:
            return 1500.0 // Highest for Max 20x
        case .apiBased:
            return 300.0  // More sensitive for pay-per-token
        case .custom:
            return 700.0  // Default fallback
        }
    }
}
