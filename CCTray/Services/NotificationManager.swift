import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var permissionRequested = false
    @Published var isNotificationSystemAvailable = true
    
    private let center = UNUserNotificationCenter.current()
    private var scheduledNotifications: Set<String> = []
    
    // Token limit notification cooldown tracking
    private var lastTokenNotificationTime: [String: Date] = [:]
    private let tokenNotificationCooldownMinutes: [String: Int] = [
        NotificationID.tokenLimitWarning: 30,
        NotificationID.tokenLimitUrgent: 15,
        NotificationID.tokenLimitCritical: 10,
        NotificationID.tokenLimitExceeded: 5
    ]
    
    // Snooze and disable state management
    private var snoozedNotifications: [String: Date] = [:]
    private var disabledNotificationTypes: Set<String> = []
    private var disabledForTodayTimestamp: Date?
    @Published var isTokenLimitNotificationDisabledToday: Bool = false
    
    // UserDefaults keys for persistence
    private enum UserDefaultsKeys {
        static let snoozedNotifications = "cctray.notifications.snoozed"
        static let disabledNotificationTypes = "cctray.notifications.disabled"
        static let disabledForTodayTimestamp = "cctray.notifications.disabledTodayTimestamp"
    }
    
    // Notification identifiers
    private enum NotificationID {
        static let sessionEnd = "cctray.session.end"
        static let sessionEndPrefix = "cctray.session.end."
        static let tokenLimitWarning = "cctray.token.limit.warning"
        static let tokenLimitUrgent = "cctray.token.limit.urgent"
        static let tokenLimitCritical = "cctray.token.limit.critical"
        static let tokenLimitExceeded = "cctray.token.limit.exceeded"
    }
    
    init() {
        // Load persisted state
        loadPersistedState()
        
        Task {
            await updateAuthorizationStatus()
            await setupNotificationCategories()
        }
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async {
        guard authorizationStatus == .notDetermined else { return }
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
            await updateAuthorizationStatus()
            permissionRequested = true
        } catch let error as NSError {
            print("Notification permission request failed: \(error)")
            
            // Handle specific error cases
            if error.domain == "UNErrorDomain" && error.code == 1 {
                print("Notifications are not allowed for this application. This may be due to:")
                print("1. System-level restrictions on menu bar apps")
                print("2. Parental controls or enterprise policies")
                print("3. Privacy settings that need to be adjusted manually")
                print("User should check System Preferences > Notifications")
                
                // Mark the notification system as potentially unavailable
                isNotificationSystemAvailable = false
            }
            
            await updateAuthorizationStatus()
            permissionRequested = true
        }
    }
    
    func updateAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    var hasPermission: Bool {
        authorizationStatus == .authorized
    }
    
    // MARK: - Notification Categories
    
    private func setupNotificationCategories() async {
        // Create actions for token limit notifications
        let viewUsageAction = UNNotificationAction(
            identifier: "VIEW_USAGE",
            title: "View Usage",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze",
            options: []
        )
        
        let disableTodayAction = UNNotificationAction(
            identifier: "DISABLE_TODAY",
            title: "Disable Today",
            options: []
        )
        
        // Create categories for different token limit notification types
        let tokenLimitWarningCategory = UNNotificationCategory(
            identifier: "token-limit-warning",
            actions: [viewUsageAction, snoozeAction, disableTodayAction],
            intentIdentifiers: [],
            options: []
        )
        
        let tokenLimitUrgentCategory = UNNotificationCategory(
            identifier: "token-limit-urgent",
            actions: [viewUsageAction, snoozeAction, disableTodayAction],
            intentIdentifiers: [],
            options: []
        )
        
        let tokenLimitCriticalCategory = UNNotificationCategory(
            identifier: "token-limit-critical",
            actions: [viewUsageAction, snoozeAction, disableTodayAction],
            intentIdentifiers: [],
            options: []
        )
        
        let tokenLimitExceededCategory = UNNotificationCategory(
            identifier: "token-limit-exceeded",
            actions: [viewUsageAction, disableTodayAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Create category for session end notifications
        let sessionEndCategory = UNNotificationCategory(
            identifier: "session-end",
            actions: [viewUsageAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Set all categories
        let categories: Set<UNNotificationCategory> = [
            tokenLimitWarningCategory,
            tokenLimitUrgentCategory,
            tokenLimitCriticalCategory,
            tokenLimitExceededCategory,
            sessionEndCategory
        ]
        
        center.setNotificationCategories(categories)
    }
    
    // MARK: - Session End Notifications
    
    func scheduleSessionEndNotification(
        for block: Block,
        notificationMinutes: Int,
        soundName: String = "default",
        interruptionLevel: UNNotificationInterruptionLevel = .active
    ) async {
        guard hasPermission else { return }
        
        // Calculate remaining time
        guard let remainingSeconds = calculateRemainingSeconds(for: block) else {
            print("Could not calculate remaining time for session end notification")
            return
        }
        
        // Check if we should schedule notification
        let notificationThresholdSeconds = TimeInterval(notificationMinutes * 60)
        let bufferSeconds: TimeInterval = 10 // Account for refresh intervals
        
        // Schedule notification if we're within threshold but not too close
        if remainingSeconds <= notificationThresholdSeconds + bufferSeconds &&
           remainingSeconds > bufferSeconds {
            
            let notificationId = "\(NotificationID.sessionEndPrefix)\(block.id)"
            
            // Skip if already scheduled for this session
            if scheduledNotifications.contains(notificationId) {
                return
            }
            
            // Calculate when to trigger the notification
            let triggerSeconds = max(remainingSeconds - notificationThresholdSeconds, 1)
            
            let content = UNMutableNotificationContent()
            content.title = "Claude Code Session Ending"
            content.body = "Your session will end in ~\(notificationMinutes) minutes"
            content.categoryIdentifier = "session-end"
            content.interruptionLevel = interruptionLevel
            
            if let sound = SoundManager.createNotificationSound(from: soundName) {
                content.sound = sound
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerSeconds,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: notificationId,
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
                scheduledNotifications.insert(notificationId)
                print("Scheduled session end notification for \(block.id) in \(triggerSeconds) seconds")
            } catch {
                print("Failed to schedule session end notification: \(error)")
            }
        }
    }
    
    // MARK: - Token Limit Notifications
    
    func scheduleTokenLimitNotification(
        thresholdPercentage: Double,
        currentUsage: Int,
        tokenLimit: Int,
        interruptionLevel: UNNotificationInterruptionLevel = .active,
        soundName: String = "default"
    ) async {
        guard hasPermission else { return }
        
        // Check if token limit notifications are disabled for today
        if isTokenLimitNotificationDisabledToday {
            print("Token limit notifications are disabled for today")
            return
        }
        
        let percentUsed = (Double(currentUsage) / Double(tokenLimit)) * 100
        let remainingTokens = tokenLimit - currentUsage
        
        // Determine notification type based on threshold
        let notificationId: String
        let title: String
        let categoryIdentifier: String
        
        switch thresholdPercentage {
        case 0..<75:
            notificationId = NotificationID.tokenLimitWarning
            title = "Token Usage Warning"
            categoryIdentifier = "token-limit-warning"
        case 75..<90:
            notificationId = NotificationID.tokenLimitUrgent
            title = "Token Usage Urgent"
            categoryIdentifier = "token-limit-urgent"
        case 90..<100:
            notificationId = NotificationID.tokenLimitCritical
            title = "Token Usage Critical"
            categoryIdentifier = "token-limit-critical"
        default:
            notificationId = NotificationID.tokenLimitExceeded
            title = "Token Limit Exceeded"
            categoryIdentifier = "token-limit-exceeded"
        }
        
        // Check if notification is snoozed
        if isNotificationSnoozed(notificationId) {
            print("Token limit notification \(notificationId) is snoozed")
            return
        }
        
        // Check cooldown period
        if let lastNotificationTime = lastTokenNotificationTime[notificationId],
           let cooldownMinutes = tokenNotificationCooldownMinutes[notificationId] {
            let timeSinceLastNotification = Date().timeIntervalSince(lastNotificationTime)
            let cooldownSeconds = TimeInterval(cooldownMinutes * 60)
            
            if timeSinceLastNotification < cooldownSeconds {
                print("Token limit notification \(notificationId) is in cooldown period")
                return
            }
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = createTokenLimitNotificationBody(
            percentUsed: percentUsed,
            remainingTokens: remainingTokens,
            thresholdPercentage: thresholdPercentage
        )
        content.categoryIdentifier = categoryIdentifier
        content.interruptionLevel = interruptionLevel
        
        if let sound = SoundManager.createNotificationSound(from: soundName) {
            content.sound = sound
        }
        
        // Add notification actions
        content.userInfo = [
            "type": "token-limit",
            "threshold": thresholdPercentage,
            "currentUsage": currentUsage,
            "tokenLimit": tokenLimit
        ]
        
        // Schedule notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            lastTokenNotificationTime[notificationId] = Date()
            scheduledNotifications.insert(notificationId)
            print("Scheduled token limit notification: \(notificationId) for \(percentUsed)% usage")
        } catch {
            print("Failed to schedule token limit notification: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func cancelSessionEndNotifications() async {
        // Cancel all session end notifications
        let pendingRequests = await center.pendingNotificationRequests()
        let sessionEndRequests = pendingRequests.filter({ 
            $0.identifier.hasPrefix(NotificationID.sessionEndPrefix) 
        })
        
        let identifiers = sessionEndRequests.map({ $0.identifier })
        if !identifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            scheduledNotifications = scheduledNotifications.filter({ !identifiers.contains($0) })
            print("Cancelled \(identifiers.count) session end notifications")
        }
    }
    
    func cancelNotificationForSession(_ blockId: String) async {
        let notificationId = "\(NotificationID.sessionEndPrefix)\(blockId)"
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        scheduledNotifications.remove(notificationId)
        print("Cancelled notification for session \(blockId)")
    }
    
    func cancelTokenLimitNotifications() async {
        let tokenLimitNotificationIds = [
            NotificationID.tokenLimitWarning,
            NotificationID.tokenLimitUrgent,
            NotificationID.tokenLimitCritical,
            NotificationID.tokenLimitExceeded
        ]
        
        center.removePendingNotificationRequests(withIdentifiers: tokenLimitNotificationIds)
        
        for notificationId in tokenLimitNotificationIds {
            scheduledNotifications.remove(notificationId)
        }
        
        print("Cancelled all token limit notifications")
    }
    
    func cancelSpecificTokenLimitNotification(_ notificationId: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        scheduledNotifications.remove(notificationId)
        print("Cancelled token limit notification: \(notificationId)")
    }
    
    func snoozeTokenLimitNotification(_ notificationId: String, minutes: Int = 15) async {
        // Cancel the current notification
        await cancelSpecificTokenLimitNotification(notificationId)
        
        // Add to snoozed notifications
        let snoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        snoozedNotifications[notificationId] = snoozeUntil
        
        // Also update the cooldown time to extend the snooze period
        lastTokenNotificationTime[notificationId] = snoozeUntil
        
        // Persist state
        savePersistedState()
        
        print("Snoozed token limit notification \(notificationId) for \(minutes) minutes")
    }
    
    func disableTokenLimitNotificationsForToday() async {
        // Cancel all pending token limit notifications
        await cancelTokenLimitNotifications()
        
        // Set disabled for today timestamp
        disabledForTodayTimestamp = Date()
        isTokenLimitNotificationDisabledToday = true
        
        // Persist state
        savePersistedState()
        
        print("Disabled token limit notifications for today")
    }
    
    func resetTokenLimitNotificationCooldowns() {
        lastTokenNotificationTime.removeAll()
        print("Reset all token limit notification cooldowns")
    }
    
    // MARK: - Snooze and Disable State Management
    
    private func isNotificationSnoozed(_ notificationId: String) -> Bool {
        guard let snoozeUntil = snoozedNotifications[notificationId] else { return false }
        
        if Date() >= snoozeUntil {
            // Snooze has expired, remove it
            snoozedNotifications.removeValue(forKey: notificationId)
            savePersistedState()
            return false
        }
        
        return true
    }
    
    private func updateDisabledForTodayState() {
        guard let timestamp = disabledForTodayTimestamp else {
            isTokenLimitNotificationDisabledToday = false
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if the disabled timestamp is from today
        if calendar.isDate(timestamp, inSameDayAs: today) {
            isTokenLimitNotificationDisabledToday = true
        } else {
            // It's a new day, clear the disabled state
            isTokenLimitNotificationDisabledToday = false
            disabledForTodayTimestamp = nil
            savePersistedState()
        }
    }
    
    private func loadPersistedState() {
        let defaults = UserDefaults.standard
        
        // Load snoozed notifications
        if let snoozedData = defaults.object(forKey: UserDefaultsKeys.snoozedNotifications) as? Data {
            if let snoozed = try? JSONDecoder().decode([String: Date].self, from: snoozedData) {
                snoozedNotifications = snoozed
                // Clean up expired snoozes
                let now = Date()
                snoozedNotifications = snoozedNotifications.filter { $0.value > now }
            }
        }
        
        // Load disabled for today timestamp
        if let timestamp = defaults.object(forKey: UserDefaultsKeys.disabledForTodayTimestamp) as? Date {
            disabledForTodayTimestamp = timestamp
        }
        
        // Update disabled state based on timestamp
        updateDisabledForTodayState()
    }
    
    private func savePersistedState() {
        let defaults = UserDefaults.standard
        
        // Save snoozed notifications
        if let snoozedData = try? JSONEncoder().encode(snoozedNotifications) {
            defaults.set(snoozedData, forKey: UserDefaultsKeys.snoozedNotifications)
        }
        
        // Save disabled for today timestamp
        if let timestamp = disabledForTodayTimestamp {
            defaults.set(timestamp, forKey: UserDefaultsKeys.disabledForTodayTimestamp)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.disabledForTodayTimestamp)
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateRemainingSeconds(for block: Block) -> TimeInterval? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let endTime = formatter.date(from: block.endTime),
              let actualEndTime = formatter.date(from: block.actualEndTime) else {
            return nil
        }
        
        let remaining = endTime.timeIntervalSince(actualEndTime)
        return remaining > 0 ? remaining : nil
    }
    
    private func createTokenLimitNotificationBody(
        percentUsed: Double,
        remainingTokens: Int,
        thresholdPercentage: Double
    ) -> String {
        let percentString = String(format: "%.1f", percentUsed)
        let remainingString = NumberFormatter.localizedString(
            from: NSNumber(value: remainingTokens),
            number: .decimal
        )
        
        if thresholdPercentage >= 100 {
            return "You have used \(percentString)% of your token limit. Consider upgrading your plan or waiting for the limit to reset."
        } else {
            return "You have used \(percentString)% of your token limit with \(remainingString) tokens remaining."
        }
    }
    
    // MARK: - Debug Information
    
    func getPendingNotificationCount() async -> Int {
        let pendingRequests = await center.pendingNotificationRequests()
        return pendingRequests.count
    }
    
    func getScheduledSessionEndNotifications() async -> [String] {
        let pendingRequests = await center.pendingNotificationRequests()
        return pendingRequests
            .filter({ $0.identifier.hasPrefix(NotificationID.sessionEndPrefix) })
            .map({ $0.identifier })
    }
    
    func getScheduledTokenLimitNotifications() async -> [String] {
        let pendingRequests = await center.pendingNotificationRequests()
        let tokenLimitNotificationIds = [
            NotificationID.tokenLimitWarning,
            NotificationID.tokenLimitUrgent,
            NotificationID.tokenLimitCritical,
            NotificationID.tokenLimitExceeded
        ]
        
        return pendingRequests
            .filter({ tokenLimitNotificationIds.contains($0.identifier) })
            .map({ $0.identifier })
    }
    
    func getTokenLimitNotificationCooldowns() -> [String: Date] {
        return lastTokenNotificationTime
    }
    
    func checkAndUpdateDisabledState() {
        updateDisabledForTodayState()
    }
    
    func getSnoozedNotifications() -> [String: Date] {
        return snoozedNotifications
    }
    
    // MARK: - Plan-Specific Notifications
    
    func schedulePlanSpecificNotification(
        for plan: ClaudePlan,
        usageContext: UsageContext,
        block: Block?
    ) async {
        guard hasPermission else { return }
        
        switch plan {
        case .pro, .max5x, .max20x:
            await scheduleSubscriptionPlanNotification(plan: plan, usageContext: usageContext, block: block)
        case .apiBased:
            await scheduleAPIPlanNotification(usageContext: usageContext, block: block)
        case .custom:
            // No specific notifications for custom plans
            break
        }
    }
    
    private func scheduleSubscriptionPlanNotification(
        plan: ClaudePlan,
        usageContext: UsageContext,
        block: Block?
    ) async {
        let notificationId = "cctray.plan.subscription.\(plan.rawValue)"
        
        // Check if we've already sent this notification recently
        if let lastNotificationTime = lastTokenNotificationTime[notificationId],
           Date().timeIntervalSince(lastNotificationTime) < 60 * 60 { // 1 hour cooldown
            return
        }
        
        var title: String
        var body: String
        var category: String
        var interruptionLevel: UNNotificationInterruptionLevel = .active
        
        if let warning = usageContext.usageWarning {
            // Usage warning for subscription plans
            title = "⚡️ \(plan.title) Usage Alert"
            body = warning
            category = "plan-usage-warning"
            
            if warning.contains("limit") {
                interruptionLevel = .timeSensitive
            }
        } else if let valueMessage = usageContext.valueMessage {
            // Value demonstration for subscription plans
            title = "💎 \(plan.title) Value Update"
            body = valueMessage
            category = "plan-value-update"
            interruptionLevel = .passive
        } else {
            return // No notification needed
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.interruptionLevel = interruptionLevel
        content.sound = .default
        
        // Add user info for context
        content.userInfo = [
            "plan": plan.rawValue,
            "notificationType": "planSpecific"
        ]
        
        // Schedule for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            lastTokenNotificationTime[notificationId] = Date()
            print("✅ Scheduled plan-specific notification for \(plan.title)")
        } catch {
            print("❌ Failed to schedule plan-specific notification: \(error)")
        }
    }
    
    private func scheduleAPIPlanNotification(
        usageContext: UsageContext,
        block: Block?
    ) async {
        let notificationId = "cctray.plan.api.cost"
        
        // Check cooldown
        if let lastNotificationTime = lastTokenNotificationTime[notificationId],
           Date().timeIntervalSince(lastNotificationTime) < 30 * 60 { // 30 minutes cooldown
            return
        }
        
        guard let warning = usageContext.usageWarning else { return }
        
        let title = "💰 API Usage Alert"
        let body = warning
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "api-cost-warning"
        content.interruptionLevel = .active
        content.sound = .default
        
        content.userInfo = [
            "plan": "apiBased",
            "notificationType": "apiCost"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            lastTokenNotificationTime[notificationId] = Date()
            print("✅ Scheduled API cost notification")
        } catch {
            print("❌ Failed to schedule API cost notification: \(error)")
        }
    }
    
    func schedulePlanOptimizationNotification(
        suggestion: PlanOptimizationSuggestion
    ) async {
        guard hasPermission else { return }
        
        let notificationId = "cctray.plan.optimization.\(suggestion.type.rawValue)"
        
        // Check if we've sent this type of suggestion recently
        if let lastNotificationTime = lastTokenNotificationTime[notificationId],
           Date().timeIntervalSince(lastNotificationTime) < 24 * 60 * 60 { // 24 hours cooldown
            return
        }
        
        let title = "📊 Plan Optimization Suggestion"
        let body = suggestion.reason
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "plan-optimization"
        content.interruptionLevel = .passive
        content.sound = .default
        
        content.userInfo = [
            "suggestionType": suggestion.type.rawValue,
            "currentPlan": suggestion.currentPlan.rawValue,
            "suggestedPlan": suggestion.suggestedPlan.rawValue,
            "potentialSavings": suggestion.potentialSavings,
            "notificationType": "planOptimization"
        ]
        
        // Schedule for delivery in 5 minutes to avoid immediate interruption
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            lastTokenNotificationTime[notificationId] = Date()
            print("✅ Scheduled plan optimization notification")
        } catch {
            print("❌ Failed to schedule plan optimization notification: \(error)")
        }
    }
    
    func scheduleWindowCompletionNotification(
        report: WindowUsageReport
    ) async {
        guard hasPermission else { return }
        
        let notificationId = "cctray.window.completion.\(report.windowId)"
        
        var title: String
        var body: String
        
        if report.planType.isSubscriptionPlan {
            title = "⏰ 5-Hour Window Complete"
            body = "Used \(report.promptCount) prompts • Session value: $\(String(format: "%.2f", report.valueReceived.apiEquivalentCost))"
        } else {
            title = "⏰ Session Complete"
            body = "Total cost: $\(String(format: "%.2f", report.totalCost)) • \(report.promptCount) prompts"
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = "window-completion"
        content.interruptionLevel = .passive
        content.sound = .default
        
        content.userInfo = [
            "windowId": report.windowId.uuidString,
            "planType": report.planType.rawValue,
            "notificationType": "windowCompletion"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            print("✅ Scheduled window completion notification")
        } catch {
            print("❌ Failed to schedule window completion notification: \(error)")
        }
    }
}