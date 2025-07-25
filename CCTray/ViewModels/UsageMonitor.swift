import Foundation
import SwiftUI

extension DateFormatter {
    static let iso8601Monitor: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

@MainActor
class UsageMonitor: ObservableObject {
    @Published var currentBlock: Block?
    @Published var displayState: DisplayMode = .cost
    @Published var isLoading = false
    @Published var error: String?
    @Published var isActive = false
    @Published var secondsUntilNextRefresh = 0
    
    // Icon state properties
    @Published var iconState: IconState = .normal
    @Published var showProgressIndicator = false
    @Published var progressPercent: Double = 0.0
    @Published var shouldPulse = false
    @Published var pulsePhase: Double = 0.0
    
    // Session tracking
    @Published var sessionsToday = 0
    private var lastActiveBlockId: String?
    private var hasInitializedSessionCount = false
    
    // Session transition detection
    private var wasSessionActive = false
    private var sessionTransitionInProgress = false
    private var lastSessionTransitionTime: Date?
    
    // Diagnostic logging
    private var diagnosticMode = false
    private var errorHistory: [(timestamp: Date, category: ErrorCategory, message: String)] = []
    private let maxErrorHistory = 50
    
    // Token limit notification tracking
    private var lastTokenLimitNotificationThresholds: [String: Double] = [:]
    private var dailyTokenNotificationCounts: [String: Int] = [:]
    private var lastTokenLimitCrossingTimestamps: [String: Date] = [:]
    private var lastTokenLimitNotificationDate: String?
    private var hasInitializedTokenNotificationTracking = false
    
    // Error recovery state
    enum ErrorCategory {
        case jsonParsing
        case commandExecution
        case permission
        case network
        case unknown
        
        var rawValue: String {
            switch self {
            case .jsonParsing: return "jsonParsing"
            case .commandExecution: return "commandExecution"
            case .permission: return "permission"
            case .network: return "network"
            case .unknown: return "unknown"
            }
        }
    }
    
    private var consecutiveErrors = 0
    private var backoffDelay: TimeInterval = 1.0
    private let maxBackoffDelay: TimeInterval = 60.0
    private var lastErrorCategory: ErrorCategory?
    
    private let commandExecutor = CommandExecutor()
    private var updateTimer: Timer?
    private var rotationTimer: Timer?
    private var countdownTimer: Timer?
    private var displayModeIndex = 0
    
    private var preferences: AppPreferences?
    private var notificationManager: NotificationManager?
    private var pulseTimer: Timer?
    private var billingPlanManager: BillingPlanManager?
    
    // Chart data management
    @Published var chartDataManager = ChartDataManager()
    private var lastDataCollectionTime: Date?
    
    func configure(with preferences: AppPreferences, notificationManager: NotificationManager) {
        self.preferences = preferences
        self.notificationManager = notificationManager
        self.billingPlanManager = BillingPlanManager(preferences: preferences)
        startMonitoring()
    }
    
    func startMonitoring() {
        guard let preferences = self.preferences else { return }
        
        stopMonitoring()
        
        // Initialize session state, including a one-time reset if needed.
        initializeSessionState()
        
        // Initialize countdown
        secondsUntilNextRefresh = Int(preferences.updateInterval)
        
        // Update timer is now handled by the countdown timer below
        
        // Start countdown timer (updates every second)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.updateCountdown()
            }
        }
        
        // Start rotation timer (only rotates display, doesn't affect data fetching)
        rotationTimer = Timer.scheduledTimer(withTimeInterval: preferences.rotationInterval, repeats: true) { _ in
            Task { @MainActor in
                self.rotateDisplayState()
            }
        }
        
        // Initial update
        Task {
            await updateUsageData()
        }
        
        isActive = true
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        rotationTimer?.invalidate()
        rotationTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil
        isActive = false
        resetCountdown()
        
        // Cancel any pending notifications
        if let notificationManager = self.notificationManager {
            Task {
                await notificationManager.cancelSessionEndNotifications()
                await notificationManager.cancelTokenLimitNotifications()
            }
        }
        
        // Reset error recovery state when stopping
        consecutiveErrors = 0
        backoffDelay = 1.0
        lastErrorCategory = nil
        
        // Reset session transition state
        wasSessionActive = false
        sessionTransitionInProgress = false
        lastSessionTransitionTime = nil
        
        // Reset token notification tracking initialization flag
        hasInitializedTokenNotificationTracking = false
    }
    
    private func categorizeError(_ error: Error) -> ErrorCategory {
        if let commandError = error as? CommandExecutor.CommandError {
            switch commandError {
            case .invalidJSON, .emptyJSON, .malformedJSON:
                return .jsonParsing
            case .commandNotFound, .executionFailed, .noOutput, .executionInProgress:
                return .commandExecution
            case .permissionDenied:
                return .permission
            case .timeout:
                return .network
            }
        }
        
        // Check error message for JSON-related errors
        let errorMessage = error.localizedDescription.lowercased()
        if errorMessage.contains("json") || errorMessage.contains("decode") || errorMessage.contains("parse") {
            return .jsonParsing
        }
        
        if errorMessage.contains("permission") || errorMessage.contains("denied") {
            return .permission
        }
        
        if errorMessage.contains("network") || errorMessage.contains("connection") || errorMessage.contains("timeout") {
            return .network
        }
        
        return .unknown
    }
    
    private func getBackoffDelay(for category: ErrorCategory, consecutiveErrors: Int) -> TimeInterval {
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval
        
        switch category {
        case .jsonParsing:
            // JSON parsing errors - shorter backoff since they might be temporary
            baseDelay = 2.0
            maxDelay = 30.0
        case .commandExecution:
            // Command execution errors - medium backoff
            baseDelay = 5.0
            maxDelay = 60.0
        case .permission:
            // Permission errors - longer backoff since they're likely persistent
            baseDelay = 10.0
            maxDelay = 120.0
        case .network:
            // Network errors - medium backoff
            baseDelay = 3.0
            maxDelay = 45.0
        case .unknown:
            // Unknown errors - default backoff
            baseDelay = 5.0
            maxDelay = 60.0
        }
        
        // Calculate exponential backoff with category-specific limits
        let delay = baseDelay * pow(2.0, Double(consecutiveErrors - 1))
        return min(delay, maxDelay)
    }
    
    // Diagnostic logging functions
    func enableDiagnosticMode() {
        diagnosticMode = true
        diagnosticLog("🔍 UsageMonitor diagnostic mode enabled")
        
        // Also enable diagnostic mode in CommandExecutor
        Task {
            await commandExecutor.enableDiagnosticMode()
        }
    }
    
    func disableDiagnosticMode() {
        diagnosticMode = false
        diagnosticLog("🔍 UsageMonitor diagnostic mode disabled")
        
        // Also disable diagnostic mode in CommandExecutor
        Task {
            await commandExecutor.disableDiagnosticMode()
        }
    }
    
    private func diagnosticLog(_ message: String) {
        if diagnosticMode {
            let timestamp = DateFormatter.iso8601Monitor.string(from: Date())
            print("[USAGE_MONITOR] \(timestamp): \(message)")
        }
    }
    
    private func recordError(category: ErrorCategory, message: String) {
        let entry = (timestamp: Date(), category: category, message: message)
        errorHistory.append(entry)
        
        // Keep only recent entries
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst()
        }
        
        diagnosticLog("❌ Error recorded: \(category) - \(message)")
    }
    
    func getErrorHistory() -> [(timestamp: Date, category: ErrorCategory, message: String)] {
        return errorHistory
    }
    
    func getDiagnosticSummary() -> String {
        let recentErrors = errorHistory.suffix(10)
        let errorSummary = recentErrors.map { "\($0.timestamp): \($0.category) - \($0.message)" }.joined(separator: "\n")
        
        return """
        === CCTray Diagnostic Summary ===
        Diagnostic Mode: \(diagnosticMode ? "ON" : "OFF")
        Consecutive Errors: \(consecutiveErrors)
        Last Error Category: \(lastErrorCategory?.rawValue ?? "none")
        Backoff Delay: \(backoffDelay)s
        Session Active: \(wasSessionActive)
        In Transition: \(sessionTransitionInProgress)
        
        Recent Errors:
        \(errorSummary.isEmpty ? "No recent errors" : errorSummary)
        """
    }
    
    private func validateSessionTransition(newBlock: Block?) async {
        let isCurrentlyActive = newBlock != nil
        
        // Detect session transition
        if wasSessionActive != isCurrentlyActive {
            sessionTransitionInProgress = true
            lastSessionTransitionTime = Date()
            
            if isCurrentlyActive {
                diagnosticLog("🔄 Session transition detected: Session started")
                await handleSessionStart()
            } else {
                diagnosticLog("🔄 Session transition detected: Session ended")
                await handleSessionEnd()
            }
            
            wasSessionActive = isCurrentlyActive
            sessionTransitionInProgress = false
        }
    }
    
    private func handleSessionStart() async {
        // Force cache invalidation to ensure fresh executable paths
        await commandExecutor.forceInvalidateCache()
        
        // Reset error recovery state for fresh start
        consecutiveErrors = 0
        backoffDelay = 1.0
        lastErrorCategory = nil
        error = nil
        
        print("✅ Session start handling complete - cache invalidated, errors cleared")
    }
    
    private func handleSessionEnd() async {
        // Less aggressive handling for session end
        // Just clear current errors, keep cache for faster restart
        if consecutiveErrors > 0 {
            consecutiveErrors = 0
            backoffDelay = 1.0
            lastErrorCategory = nil
            error = nil
            print("✅ Session end handling complete - errors cleared")
        }
    }
    
    private func isInSessionTransitionWindow() -> Bool {
        guard let transitionTime = lastSessionTransitionTime else { return false }
        return Date().timeIntervalSince(transitionTime) < 10.0 // 10 second window
    }
    
    private func updateUsageData() async {
        guard let preferences = self.preferences else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await commandExecutor.getCCUsageData(
                commandPath: preferences.ccusageCommandPath,
                scriptPath: preferences.ccusageScriptPath,
                tokenLimitEnabled: preferences.tokenLimitEnabled,
                tokenLimitValue: preferences.tokenLimitValue
            )
            let newBlock = response.blocks.first(where: { $0.isActive })
            
            // Validate session transitions before updating tracking
            await validateSessionTransition(newBlock: newBlock)
            
            // Track session changes
            await updateSessionTracking(newBlock: newBlock)
            
            currentBlock = newBlock
            
            // Collect chart data if enabled and sufficient time has passed
            await collectChartData(for: newBlock)
            
            // Update icon state based on new data
            updateIconState()
            
            // Initialize token notification tracking if needed
            if !hasInitializedTokenNotificationTracking {
                await initializeTokenNotificationTracking()
                hasInitializedTokenNotificationTracking = true
            }
            
            // Check and update notification disabled state (in case it's a new day)
            notificationManager?.checkAndUpdateDisabledState()
            
            // Monitor token limit thresholds and trigger notifications if needed
            await monitorTokenLimitThresholds(for: newBlock)
            
            // Schedule session end notifications if enabled
            await scheduleSessionEndNotifications(for: newBlock)
            
            // Reset error recovery state on success
            consecutiveErrors = 0
            backoffDelay = 1.0
            lastErrorCategory = nil
            error = nil
            
        } catch {
            let errorCategory = categorizeError(error)
            
            // Reset consecutive errors if error category changed
            if let lastCategory = lastErrorCategory, lastCategory != errorCategory {
                consecutiveErrors = 0
                print("Error category changed from \(lastCategory) to \(errorCategory), resetting consecutive errors")
            }
            
            consecutiveErrors += 1
            lastErrorCategory = errorCategory
            self.error = error.localizedDescription
            
            // Update icon state to reflect error condition
            updateIconState()
            
            // Record error for diagnostic purposes
            recordError(category: errorCategory, message: error.localizedDescription)
            
            diagnosticLog("❌ Error fetching usage data (category: \(errorCategory)): \(error)")
            
            // Be more lenient during session transitions
            let inTransitionWindow = isInSessionTransitionWindow()
            if inTransitionWindow {
                diagnosticLog("ℹ️ Error occurred during session transition window - reducing backoff")
            }
            
            // Implement category-specific backoff
            if consecutiveErrors > 1 {
                backoffDelay = getBackoffDelay(for: errorCategory, consecutiveErrors: consecutiveErrors)
                
                // Reduce backoff during session transitions
                if inTransitionWindow {
                    backoffDelay = min(backoffDelay, 5.0) // Cap at 5 seconds during transitions
                }
                
                print("Consecutive errors: \(consecutiveErrors), category: \(errorCategory), next backoff delay: \(backoffDelay)s")
                
                // Schedule delayed retry instead of immediate next update
                DispatchQueue.main.asyncAfter(deadline: .now() + backoffDelay) {
                    // Only retry if still active and have preferences
                    if self.isActive && self.preferences != nil {
                        Task {
                            await self.updateUsageData()
                        }
                    }
                }
                return // Skip normal timer cycle
            }
        }
        
        isLoading = false
        
        // Reset countdown after refresh completes
        if let preferences = self.preferences {
            secondsUntilNextRefresh = Int(preferences.updateInterval)
        }
    }
    
    private func updateCountdown() {
        // Always decrement countdown if > 0 (independent of loading state)
        guard secondsUntilNextRefresh > 0 else { 
            print("DEBUG: updateCountdown() called but secondsUntilNextRefresh is \(secondsUntilNextRefresh)")
            return 
        }
        
        let oldValue = secondsUntilNextRefresh
        secondsUntilNextRefresh -= 1
        print("DEBUG: Countdown updated: \(oldValue) -> \(secondsUntilNextRefresh)")
        
        // Trigger refresh when countdown reaches 0
        if secondsUntilNextRefresh == 0 {
            // Skip update if we're in backoff mode (consecutive errors > 1)
            guard consecutiveErrors <= 1 else {
                print("Skipping countdown refresh due to error backoff (errors: \(consecutiveErrors))")
                // Reset countdown for next attempt
                resetCountdown()
                return
            }
            
            Task {
                await updateUsageData()
            }
        }
    }
    
    private func resetCountdown() {
        guard let preferences = self.preferences else { return }
        secondsUntilNextRefresh = Int(preferences.updateInterval)
    }
    
    private func rotateDisplayState() {
        guard let preferences = self.preferences else { return }
        
        let enabledModes = preferences.enabledDisplayModes
        guard !enabledModes.isEmpty else { return }
        
        displayModeIndex = (displayModeIndex + 1) % enabledModes.count
        displayState = enabledModes[displayModeIndex]
    }
    
    func getCurrentTitle() -> AttributedString {
        print("getCurrentTitle called - isLoading: \(isLoading), error: \(error ?? "none"), currentBlock: \(currentBlock?.id ?? "none")")
        
        guard let block = currentBlock else {
            if error != nil {
                return createStyledFallback(" ❌")
            } else if isLoading {
                return createStyledFallback(" ...")
            } else {
                return createStyledFallback(" 💤")
            }
        }
        
        guard let preferences = self.preferences else {
            return createStyledFallback(" $\(String(format: "%.2f", block.costUSD))")
        }
        
        switch displayState {
        case .cost:
            return block.formatCostTitle(preferences: preferences)
        case .burnRate:
            return block.formatBurnRateTitle(preferences: preferences)
        case .remainingTime:
            return block.formatRemainingTimeTitle(preferences: preferences)
        case .projectedCost:
            return block.formatProjectedCostTitle(preferences: preferences)
        case .apiCalls:
            return block.formatApiCallsTitle(preferences: preferences)
        case .sessionsToday:
            return formatSessionsTodayTitle(preferences: preferences)
        case .tokenLimit:
            return block.formatTokenLimitTitle(preferences: preferences)
        case .tokenUsage:
            return block.formatTokenUsageTitle(preferences: preferences)
        }
    }
    
    func getDetailedInfo() -> [String] {
        guard let block = currentBlock else {
            if let error = error {
                return ["❌ Error: \(error)"]
            } else if isLoading {
                return ["⏳ Loading..."]
            } else {
                return ["💤 No active session"]
            }
        }
        
        var info = block.formatDetailedInfo(preferences: preferences!)
        // Add sessions started today to the detailed info
        info.append("📅 Sessions Started Today: \(sessionsToday)")
        return info
    }
    
    func refreshData() {
        Task {
            await updateUsageData()
        }
    }
    
    private func createStyledFallback(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply styling to the entire string
        attributedString.font = .system(size: 14, weight: .medium, design: .monospaced)
        
        return attributedString
    }
    
    private func updateSessionTracking(newBlock: Block?) async {
        if !hasInitializedSessionCount {
            initializeSessionState()
        }

        let newBlockId = newBlock?.id

        // Case 1: A new session has started.
        // This is true if there's a new block ID, and it's different from the last one we tracked.
        if let newBlockId = newBlockId, newBlockId != self.lastActiveBlockId {
            self.sessionsToday += 1
            self.lastActiveBlockId = newBlockId
            print("📅 New session detected. ID: \(newBlockId). Sessions today: \(self.sessionsToday)")
            saveSessionState()
        }
        // Case 2: A session has ended.
        // This is true if there's no new block, but we were previously tracking one.
        else if newBlockId == nil, self.lastActiveBlockId != nil {
            self.lastActiveBlockId = nil
            print("📅 Session ended.")
            saveSessionState() // Save the fact that there's no active block.
        }
    }

    private func initializeSessionState() {
        let today = getCurrentDateString()
        let storedDate = UserDefaults.standard.string(forKey: "lastSessionDate") ?? ""

        if storedDate == today {
            // Same day. Load the count and the last block ID we tracked.
            self.sessionsToday = UserDefaults.standard.integer(forKey: "sessionsToday")
            self.lastActiveBlockId = UserDefaults.standard.string(forKey: "lastActiveBlockId")
            if self.lastActiveBlockId?.isEmpty ?? true { self.lastActiveBlockId = nil }
            print("📅 Loaded session count for today: \(self.sessionsToday). Last tracked block: \(self.lastActiveBlockId ?? "none")")
        } else {
            // New day. Reset everything.
            self.sessionsToday = 0
            self.lastActiveBlockId = nil
            print("📅 New day, resetting session count.")
        }
        self.hasInitializedSessionCount = true
    }

    private func saveSessionState() {
        let today = getCurrentDateString()
        UserDefaults.standard.set(today, forKey: "lastSessionDate")
        UserDefaults.standard.set(self.sessionsToday, forKey: "sessionsToday")
        UserDefaults.standard.set(self.lastActiveBlockId, forKey: "lastActiveBlockId")
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    func formatSessionsTodayTitle(preferences: AppPreferences) -> AttributedString {
        let prefix = preferences.useTextForSessionsToday ? " SESS " : " S: "
        return createStyledFallback("\(prefix)\(sessionsToday)")
    }
    
    // MARK: - Token Limit Threshold Monitoring
    
    private func initializeTokenNotificationTracking() async {
        let today = getCurrentDateString()
        let storedDate = UserDefaults.standard.string(forKey: "lastTokenNotificationDate") ?? ""
        
        if storedDate == today {
            // Same day, load existing tracking data
            if let data = UserDefaults.standard.data(forKey: "dailyTokenNotificationCounts"),
               let counts = try? JSONDecoder().decode([String: Int].self, from: data) {
                dailyTokenNotificationCounts = counts
            }
            
            if let data = UserDefaults.standard.data(forKey: "lastTokenLimitNotificationThresholds"),
               let thresholds = try? JSONDecoder().decode([String: Double].self, from: data) {
                lastTokenLimitNotificationThresholds = thresholds
            }
            
            if let data = UserDefaults.standard.data(forKey: "lastTokenLimitCrossingTimestamps"),
               let timestamps = try? JSONDecoder().decode([String: Date].self, from: data) {
                lastTokenLimitCrossingTimestamps = timestamps
            }
            
            print("🔔 Initialized token notification tracking for today")
        } else {
            // New day, reset all tracking data
            await resetDailyTokenNotificationCounters()
            print("🔔 New day detected, reset token notification tracking")
        }
        
        lastTokenLimitNotificationDate = today
    }
    
    private func monitorTokenLimitThresholds(for block: Block?) async {
        guard let preferences = self.preferences,
              let notificationManager = self.notificationManager,
              preferences.tokenLimitNotificationsEnabled,
              let block = block,
              let tokenLimitStatus = block.tokenLimitStatus else {
            return
        }
        
        // Skip if token limit notifications are disabled for today
        if notificationManager.isTokenLimitNotificationDisabledToday {
            return
        }
        
        // Skip if in quiet hours
        if preferences.isInQuietHours() {
            return
        }
        
        let currentPercentage = tokenLimitStatus.percentUsed
        let thresholds = [
            ("warning", preferences.tokenLimitNotificationWarningThreshold),
            ("urgent", preferences.tokenLimitUrgentThreshold),
            ("critical", preferences.tokenLimitCriticalThreshold),
            ("exceeded", 100.0)
        ]
        
        for (thresholdType, thresholdValue) in thresholds {
            // Skip disabled thresholds (0% = disabled)
            if thresholdValue > 0 && currentPercentage >= thresholdValue {
                if await shouldTriggerNotification(for: thresholdType, percentage: currentPercentage, threshold: thresholdValue) {
                    // Determine appropriate interruption level
                    let interruptionLevel = preferences.getInterruptionLevel(for: currentPercentage)
                    
                    // Schedule the notification
                    await notificationManager.scheduleTokenLimitNotification(
                        thresholdPercentage: thresholdValue,
                        currentUsage: tokenLimitStatus.projectedUsage,
                        tokenLimit: tokenLimitStatus.limit,
                        interruptionLevel: interruptionLevel,
                        soundName: preferences.tokenNotificationSound
                    )
                    
                    // Update tracking state
                    await updateTokenNotificationTrackingState(for: thresholdType, percentage: currentPercentage, threshold: thresholdValue)
                }
            }
        }
    }
    
    private func shouldTriggerNotification(for thresholdType: String, percentage: Double, threshold: Double) async -> Bool {
        // Check if we've already sent a notification for this threshold today
        let dailyCount = dailyTokenNotificationCounts[thresholdType] ?? 0
        let maxDaily = preferences?.maxTokenNotificationsPerDay ?? 6
        
        if dailyCount >= maxDaily {
            return false
        }
        
        // Check if we've crossed this threshold recently (avoid duplicate notifications)
        let lastNotifiedThreshold = lastTokenLimitNotificationThresholds[thresholdType] ?? 0.0
        let thresholdTolerance = 1.0 // 1% tolerance to avoid repeated notifications
        
        if abs(percentage - lastNotifiedThreshold) < thresholdTolerance {
            return false
        }
        
        // Check if we're actually crossing the threshold (not just hovering around it)
        if percentage < threshold {
            return false
        }
        
        // Check if we've recently crossed this threshold (cooldown period)
        if let lastCrossingTime = lastTokenLimitCrossingTimestamps[thresholdType] {
            let timeSinceLastCrossing = Date().timeIntervalSince(lastCrossingTime)
            let cooldownMinutes = getCooldownMinutes(for: thresholdType)
            
            if timeSinceLastCrossing < TimeInterval(cooldownMinutes * 60) {
                return false
            }
        }
        
        return true
    }
    
    private func updateTokenNotificationTrackingState(for thresholdType: String, percentage: Double, threshold: Double) async {
        // Update daily count
        dailyTokenNotificationCounts[thresholdType] = (dailyTokenNotificationCounts[thresholdType] ?? 0) + 1
        
        // Update last notification threshold
        lastTokenLimitNotificationThresholds[thresholdType] = percentage
        
        // Update crossing timestamp
        lastTokenLimitCrossingTimestamps[thresholdType] = Date()
        
        // Persist to UserDefaults
        await saveTokenNotificationTrackingData()
    }
    
    private func resetDailyTokenNotificationCounters() async {
        dailyTokenNotificationCounts.removeAll()
        lastTokenLimitNotificationThresholds.removeAll()
        lastTokenLimitCrossingTimestamps.removeAll()
        
        // Clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: "dailyTokenNotificationCounts")
        UserDefaults.standard.removeObject(forKey: "lastTokenLimitNotificationThresholds")
        UserDefaults.standard.removeObject(forKey: "lastTokenLimitCrossingTimestamps")
        UserDefaults.standard.set(getCurrentDateString(), forKey: "lastTokenNotificationDate")
    }
    
    private func saveTokenNotificationTrackingData() async {
        let today = getCurrentDateString()
        UserDefaults.standard.set(today, forKey: "lastTokenNotificationDate")
        
        // Save daily counts
        if let data = try? JSONEncoder().encode(dailyTokenNotificationCounts) {
            UserDefaults.standard.set(data, forKey: "dailyTokenNotificationCounts")
        }
        
        // Save last notification thresholds
        if let data = try? JSONEncoder().encode(lastTokenLimitNotificationThresholds) {
            UserDefaults.standard.set(data, forKey: "lastTokenLimitNotificationThresholds")
        }
        
        // Save crossing timestamps
        if let data = try? JSONEncoder().encode(lastTokenLimitCrossingTimestamps) {
            UserDefaults.standard.set(data, forKey: "lastTokenLimitCrossingTimestamps")
        }
    }
    
    private func getCooldownMinutes(for thresholdType: String) -> Int {
        switch thresholdType {
        case "warning":
            return 30
        case "urgent":
            return 15
        case "critical":
            return 10
        case "exceeded":
            return 5
        default:
            return 30
        }
    }
    
    // MARK: - Icon State Management
    
    /// Updates the icon state based on current usage data
    private func updateIconState() {
        guard let preferences = self.preferences else { return }
        
        // Reset pulse state
        shouldPulse = false
        pulseTimer?.invalidate()
        pulseTimer = nil
        
        // Check for error state first
        if error != nil {
            iconState = .error
            showProgressIndicator = false
            progressPercent = 0.0
            return
        }
        
        guard let block = currentBlock else {
            iconState = .normal
            showProgressIndicator = false
            progressPercent = 0.0
            return
        }
        
        // Calculate progress percentage from token limit if available
        if let tokenLimit = block.tokenLimitStatus, preferences.enableProgressIndicator {
            showProgressIndicator = true
            progressPercent = tokenLimit.percentUsed / 100.0
        } else {
            showProgressIndicator = false
            progressPercent = 0.0
        }
        
        // Determine icon state based on thresholds
        let newIconState = preferences.enableColorCodedIcons ? calculateIconState(for: block, preferences: preferences) : .normal
        
        // Start pulsing if state changed to warning or critical and animation is enabled
        if preferences.enablePulseAnimation && newIconState != iconState && (newIconState == .warning || newIconState == .critical) {
            shouldPulse = true
            startPulseAnimation()
        } else if !preferences.enablePulseAnimation {
            shouldPulse = false
        }
        
        iconState = newIconState
    }
    
    /// Calculates the appropriate icon state based on usage thresholds
    private func calculateIconState(for block: Block, preferences: AppPreferences) -> IconState {
        // Check token limit thresholds if available
        if let tokenLimit = block.tokenLimitStatus {
            let percentage = tokenLimit.percentUsed
            
            if preferences.tokenLimitCriticalThreshold > 0 && percentage >= preferences.tokenLimitCriticalThreshold {
                return .critical
            } else if preferences.tokenLimitUrgentThreshold > 0 && percentage >= preferences.tokenLimitUrgentThreshold {
                return .critical
            } else if preferences.tokenLimitNotificationWarningThreshold > 0 && percentage >= preferences.tokenLimitNotificationWarningThreshold {
                return .warning
            }
        }
        
        // Check burn rate thresholds - high burn rate indicates approaching limits
        let burnRatePerHour = block.burnRate.costPerHour
        if burnRatePerHour > 10.0 {  // High burn rate threshold
            return .warning
        }
        
        return .normal
    }
    
    /// Starts the pulsing animation for warning/critical states
    private func startPulseAnimation() {
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.shouldPulse {
                    self.pulsePhase += 0.2
                    if self.pulsePhase >= 2 * Double.pi {
                        self.pulsePhase = 0
                    }
                } else {
                    self.pulseTimer?.invalidate()
                    self.pulseTimer = nil
                }
            }
        }
    }
    
    // MARK: - Session End Notifications
    
    private func scheduleSessionEndNotifications(for block: Block?) async {
        guard let preferences = self.preferences,
              let notificationManager = self.notificationManager,
              preferences.enableSessionEndNotifications else {
            return
        }
        
        if let block = block {
            // Schedule notification for this active session
            await notificationManager.scheduleSessionEndNotification(
                for: block,
                notificationMinutes: preferences.sessionEndNotificationMinutes,
                soundName: preferences.sessionEndNotificationSound,
                interruptionLevel: preferences.notificationInterruptionLevel(for: preferences.sessionEndNotificationPriority)
            )
        } else {
            // No active session, cancel any existing notifications
            await notificationManager.cancelSessionEndNotifications()
        }
    }
    
    // MARK: - Public Token Notification Management
    
    /// Manually reset daily token notification counters (useful for testing or user preference)
    func resetTokenNotificationCounters() {
        Task {
            await resetDailyTokenNotificationCounters()
        }
    }
    
    /// Get current daily notification counts for debugging
    func getTokenNotificationCounts() -> [String: Int] {
        return dailyTokenNotificationCounts
    }
    
    // MARK: - Chart Data Collection
    
    /// Collect chart data points from the current block
    private func collectChartData(for block: Block?) async {
        guard let preferences = self.preferences,
              preferences.enableChartDataCollection else { return }
        
        let now = Date()
        
        // Only collect data if enough time has passed since last collection
        if let lastCollection = lastDataCollectionTime,
           now.timeIntervalSince(lastCollection) < 10.0 { // Collect every 10 seconds minimum
            return
        }
        
        lastDataCollectionTime = now
        
        // If we have an active block, collect its data
        if let block = block {
            // Cost data
            let costPoint = ChartDataPoint(timestamp: now, value: block.costUSD)
            chartDataManager.addDataPoint(costPoint, for: .cost)
            
            // Burn rate data
            let burnRatePoint = ChartDataPoint(timestamp: now, value: block.burnRate.costPerHour)
            chartDataManager.addDataPoint(burnRatePoint, for: .burnRate)
            
            // Token usage data
            let tokenPoint = ChartDataPoint(timestamp: now, value: Double(block.totalTokens))
            chartDataManager.addDataPoint(tokenPoint, for: .tokenUsage)
            
            // API calls data
            let apiCallsPoint = ChartDataPoint(timestamp: now, value: Double(block.entries))
            chartDataManager.addDataPoint(apiCallsPoint, for: .apiCalls)
            
            // Projected cost data
            let projectedCostPoint = ChartDataPoint(timestamp: now, value: block.projection.totalCost)
            chartDataManager.addDataPoint(projectedCostPoint, for: .projectedCost)
            
            // Token limit data (if available)
            if let tokenLimit = block.tokenLimitStatus {
                let tokenLimitPoint = ChartDataPoint(timestamp: now, value: tokenLimit.percentUsed)
                chartDataManager.addDataPoint(tokenLimitPoint, for: .tokenLimit)
            }
            
            diagnosticLog("📊 Chart data collected for all metrics")
        }
    }
    
    /// Get chart data for a specific metric and time range
    func getChartData(for metric: MetricType, in timeRange: ChartTimeRange) -> [ChartDataPoint] {
        return chartDataManager.getDataPoints(for: metric, in: timeRange)
    }
    
    /// Get trend direction for a metric
    func getTrendDirection(for metric: MetricType, in timeRange: ChartTimeRange) -> TrendDirection {
        return chartDataManager.getTrendDirection(for: metric, in: timeRange)
    }
    
    /// Get latest value for a metric
    func getLatestValue(for metric: MetricType) -> Double? {
        return chartDataManager.getLatestValue(for: metric)
    }
    
    /// Clear chart data older than specified days
    func clearOldChartData(olderThan days: Int) {
        chartDataManager.clearOldData(olderThan: days)
    }
    
    // MARK: - Billing Plan Integration
    
    /// Get plan-aware cost context for display
    func getPlanAwareCostContext() -> CostContext? {
        guard let currentBlock = currentBlock,
              let preferences = preferences else { return nil }
        
        let response = CCUsageResponse(blocks: [currentBlock])
        return response.getCostContext(for: preferences.selectedClaudePlan)
    }
    
    /// Get plan-aware burn rate context
    func getPlanAwareBurnRateContext() -> BurnRateContext? {
        guard let currentBlock = currentBlock,
              let preferences = preferences else { return nil }
        
        let response = CCUsageResponse(blocks: [currentBlock])
        return response.getBurnRateContext(for: preferences.selectedClaudePlan)
    }
    
    /// Get plan-aware projection context
    func getPlanAwareProjectionContext() -> ProjectionContext? {
        guard let currentBlock = currentBlock,
              let preferences = preferences else { return nil }
        
        let response = CCUsageResponse(blocks: [currentBlock])
        return response.getProjectionContext(for: preferences.selectedClaudePlan)
    }
    
    /// Get usage context from billing plan manager
    func getPlanAwareUsageContext() -> UsageContext? {
        guard let billingPlanManager = billingPlanManager,
              let currentBlock = currentBlock else { return nil }
        
        return billingPlanManager.getUsageContext(
            for: currentBlock.costUSD, 
            burnRate: currentBlock.burnRate.tokensPerMinute
        )
    }
    
    /// Get billing plan display information
    func getBillingPlanInfo() -> (title: String, description: String, isSubscription: Bool)? {
        guard let billingPlanManager = billingPlanManager else { return nil }
        
        return (
            title: billingPlanManager.planDisplayName,
            description: billingPlanManager.planDescription,
            isSubscription: billingPlanManager.isSubscriptionPlan
        )
    }
    
    /// Update session activity for billing plan tracking
    func updateBillingPlanActivity() {
        billingPlanManager?.updateSessionActivity()
    }
    
    // Cleanup is handled by stopMonitoring() call when needed
}