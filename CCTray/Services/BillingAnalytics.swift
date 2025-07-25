import Foundation
import SwiftUI

class BillingAnalytics: ObservableObject {
    @Published var fiveHourWindows: [FiveHourWindow] = []
    @Published var currentWindow: FiveHourWindow?
    @Published var dailyUsage: [String: DailyUsage] = [:]
    @Published var planOptimizationSuggestions: [PlanOptimizationSuggestion] = []
    
    private let preferences: AppPreferences
    private let billingPlanManager: BillingPlanManager
    
    init(preferences: AppPreferences, billingPlanManager: BillingPlanManager) {
        self.preferences = preferences
        self.billingPlanManager = billingPlanManager
        loadStoredData()
    }
    
    // MARK: - 5-Hour Window Tracking
    
    func startNewFiveHourWindow(sessionId: String) {
        let now = Date()
        let windowEnd = now.addingTimeInterval(5 * 60 * 60) // 5 hours from now
        
        let newWindow = FiveHourWindow(
            id: UUID(),
            startTime: now,
            endTime: windowEnd,
            sessions: [sessionId],
            totalCost: 0.0,
            totalTokens: 0,
            totalPrompts: 1,
            planType: preferences.selectedClaudePlan
        )
        
        currentWindow = newWindow
        fiveHourWindows.append(newWindow)
        saveStoredData()
    }
    
    func updateCurrentWindow(with usageData: Block) {
        guard var window = currentWindow else { return }
        
        // Update window with new usage data
        window.totalCost = usageData.costUSD
        window.totalTokens = usageData.totalTokens
        window.lastUpdated = Date()
        
        // Update the current window in the array
        if let index = fiveHourWindows.firstIndex(where: { $0.id == window.id }) {
            fiveHourWindows[index] = window
        }
        
        currentWindow = window
        saveStoredData()
    }
    
    func checkWindowExpiration() {
        guard let window = currentWindow else { return }
        
        if Date() > window.endTime {
            // Window has expired
            finalizeWindow(window)
            currentWindow = nil
        }
    }
    
    private func finalizeWindow(_ window: FiveHourWindow) {
        // Generate usage report for the completed window
        let _ = generateWindowReport(window) // Report generated but not used yet
        
        // Update daily usage statistics
        updateDailyUsage(with: window)
        
        // Generate optimization suggestions
        generateOptimizationSuggestions(for: window)
        
        saveStoredData()
    }
    
    // MARK: - Usage Analytics
    
    func generateWindowReport(_ window: FiveHourWindow) -> WindowUsageReport {
        let efficiency = calculateEfficiency(for: window)
        let valueReceived = calculateValueReceived(for: window)
        
        return WindowUsageReport(
            windowId: window.id,
            duration: window.endTime.timeIntervalSince(window.startTime),
            totalCost: window.totalCost,
            totalTokens: window.totalTokens,
            promptCount: window.totalPrompts,
            efficiency: efficiency,
            valueReceived: valueReceived,
            planType: window.planType
        )
    }
    
    func calculateEfficiency(for window: FiveHourWindow) -> UsageEfficiency {
        let tokensPerPrompt = window.totalTokens / max(window.totalPrompts, 1)
        let costPerPrompt = window.totalCost / Double(max(window.totalPrompts, 1))
        
        let efficiencyScore: Double
        switch window.planType {
        case .pro:
            efficiencyScore = min(Double(window.totalPrompts) / 40.0, 1.0) // Out of 40 prompts max
        case .max5x:
            efficiencyScore = min(Double(window.totalPrompts) / 200.0, 1.0) // Out of 200 prompts max
        case .max20x:
            efficiencyScore = min(Double(window.totalPrompts) / 800.0, 1.0) // Out of 800 prompts max
        case .apiBased:
            efficiencyScore = window.totalCost < 10.0 ? 1.0 : 0.5 // Good if under $10
        case .custom:
            efficiencyScore = 0.5 // Neutral for custom plans
        }
        
        return UsageEfficiency(
            tokensPerPrompt: tokensPerPrompt,
            costPerPrompt: costPerPrompt,
            efficiencyScore: efficiencyScore
        )
    }
    
    func calculateValueReceived(for window: FiveHourWindow) -> ValueReceived {
        let apiEquivalentCost = window.totalCost // ccusage shows API equivalent cost
        let actualCost: Double
        
        switch window.planType {
        case .pro:
            actualCost = 20.0 / 30.0 // Daily portion of monthly cost
        case .max5x:
            actualCost = 100.0 / 30.0 // Daily portion of monthly cost
        case .max20x:
            actualCost = 200.0 / 30.0 // Daily portion of monthly cost
        case .apiBased:
            actualCost = apiEquivalentCost // Same as API cost
        case .custom:
            actualCost = 0.0 // Unknown
        }
        
        let savings = window.planType.isSubscriptionPlan ? max(apiEquivalentCost - actualCost, 0.0) : 0.0
        let valueRatio = actualCost > 0 ? apiEquivalentCost / actualCost : 0.0
        
        return ValueReceived(
            apiEquivalentCost: apiEquivalentCost,
            actualCost: actualCost,
            savings: savings,
            valueRatio: valueRatio
        )
    }
    
    // MARK: - Daily Usage Tracking
    
    private func updateDailyUsage(with window: FiveHourWindow) {
        let dateKey = dateFormatter.string(from: window.startTime)
        
        if var dailyUsage = dailyUsage[dateKey] {
            dailyUsage.totalCost += window.totalCost
            dailyUsage.totalTokens += window.totalTokens
            dailyUsage.totalPrompts += window.totalPrompts
            dailyUsage.windowCount += 1
            self.dailyUsage[dateKey] = dailyUsage
        } else {
            dailyUsage[dateKey] = DailyUsage(
                date: window.startTime,
                totalCost: window.totalCost,
                totalTokens: window.totalTokens,
                totalPrompts: window.totalPrompts,
                windowCount: 1,
                planType: window.planType
            )
        }
    }
    
    // MARK: - Optimization Suggestions
    
    private func generateOptimizationSuggestions(for window: FiveHourWindow) {
        let efficiency = calculateEfficiency(for: window)
        let valueReceived = calculateValueReceived(for: window)
        
        var suggestions: [PlanOptimizationSuggestion] = []
        
        // Check if user should upgrade/downgrade plan
        if window.planType == .pro && efficiency.efficiencyScore > 0.8 {
            suggestions.append(PlanOptimizationSuggestion(
                type: .upgrade,
                currentPlan: .pro,
                suggestedPlan: .max5x,
                reason: "You're using \(Int(efficiency.efficiencyScore * 100))% of your Pro plan capacity. Consider upgrading to Max 5x for higher limits.",
                potentialSavings: 0.0
            ))
        }
        
        if window.planType == .max5x && efficiency.efficiencyScore < 0.2 {
            suggestions.append(PlanOptimizationSuggestion(
                type: .downgrade,
                currentPlan: .max5x,
                suggestedPlan: .pro,
                reason: "You're only using \(Int(efficiency.efficiencyScore * 100))% of your Max 5x capacity. Consider downgrading to Pro to save $80/month.",
                potentialSavings: 80.0
            ))
        }
        
        if window.planType == .apiBased && valueReceived.apiEquivalentCost > 50.0 {
            suggestions.append(PlanOptimizationSuggestion(
                type: .upgrade,
                currentPlan: .apiBased,
                suggestedPlan: .max5x,
                reason: "Your API usage would cost $\(String(format: "%.2f", valueReceived.apiEquivalentCost)). Max 5x at $100/month could save money.",
                potentialSavings: max(valueReceived.apiEquivalentCost - 100.0, 0.0)
            ))
        }
        
        planOptimizationSuggestions.append(contentsOf: suggestions)
        
        // Keep only recent suggestions (last 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        planOptimizationSuggestions = planOptimizationSuggestions.filter { $0.timestamp > thirtyDaysAgo }
    }
    
    // MARK: - Data Persistence
    
    private func loadStoredData() {
        let defaults = UserDefaults.standard
        
        // Load 5-hour windows
        if let windowData = defaults.data(forKey: "fiveHourWindows"),
           let windows = try? JSONDecoder().decode([FiveHourWindow].self, from: windowData) {
            fiveHourWindows = windows
            currentWindow = windows.first { Date() <= $0.endTime }
        }
        
        // Load daily usage
        if let dailyData = defaults.data(forKey: "dailyUsage"),
           let usage = try? JSONDecoder().decode([String: DailyUsage].self, from: dailyData) {
            dailyUsage = usage
        }
        
        // Load suggestions
        if let suggestionsData = defaults.data(forKey: "planOptimizationSuggestions"),
           let suggestions = try? JSONDecoder().decode([PlanOptimizationSuggestion].self, from: suggestionsData) {
            planOptimizationSuggestions = suggestions
        }
    }
    
    private func saveStoredData() {
        let defaults = UserDefaults.standard
        
        // Save 5-hour windows
        if let windowData = try? JSONEncoder().encode(fiveHourWindows) {
            defaults.set(windowData, forKey: "fiveHourWindows")
        }
        
        // Save daily usage
        if let dailyData = try? JSONEncoder().encode(dailyUsage) {
            defaults.set(dailyData, forKey: "dailyUsage")
        }
        
        // Save suggestions
        if let suggestionsData = try? JSONEncoder().encode(planOptimizationSuggestions) {
            defaults.set(suggestionsData, forKey: "planOptimizationSuggestions")
        }
    }
    
    // MARK: - Utility
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func clearOldData() {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        // Remove old windows
        fiveHourWindows = fiveHourWindows.filter { $0.startTime > thirtyDaysAgo }
        
        // Remove old daily usage
        dailyUsage = dailyUsage.filter { _, usage in
            usage.date > thirtyDaysAgo
        }
        
        saveStoredData()
    }
}

// MARK: - Supporting Types

struct FiveHourWindow: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    var sessions: [String]
    var totalCost: Double
    var totalTokens: Int
    var totalPrompts: Int
    let planType: ClaudePlan
    var lastUpdated: Date = Date()
}

struct DailyUsage: Codable {
    let date: Date
    var totalCost: Double
    var totalTokens: Int
    var totalPrompts: Int
    var windowCount: Int
    let planType: ClaudePlan
}

struct WindowUsageReport: Codable {
    let windowId: UUID
    let duration: TimeInterval
    let totalCost: Double
    let totalTokens: Int
    let promptCount: Int
    let efficiency: UsageEfficiency
    let valueReceived: ValueReceived
    let planType: ClaudePlan
}

struct UsageEfficiency: Codable {
    let tokensPerPrompt: Int
    let costPerPrompt: Double
    let efficiencyScore: Double
}

struct ValueReceived: Codable {
    let apiEquivalentCost: Double
    let actualCost: Double
    let savings: Double
    let valueRatio: Double
}

struct PlanOptimizationSuggestion: Codable, Identifiable {
    let id: UUID
    let type: SuggestionType
    let currentPlan: ClaudePlan
    let suggestedPlan: ClaudePlan
    let reason: String
    let potentialSavings: Double
    let timestamp: Date
    
    init(type: SuggestionType, currentPlan: ClaudePlan, suggestedPlan: ClaudePlan, reason: String, potentialSavings: Double) {
        self.id = UUID()
        self.type = type
        self.currentPlan = currentPlan
        self.suggestedPlan = suggestedPlan
        self.reason = reason
        self.potentialSavings = potentialSavings
        self.timestamp = Date()
    }
}

enum SuggestionType: String, Codable {
    case upgrade = "upgrade"
    case downgrade = "downgrade"
    case switchPlan = "switch"
}