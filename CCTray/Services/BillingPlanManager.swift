import Foundation
import SwiftUI

class BillingPlanManager: ObservableObject {
    @Published var selectedPlan: ClaudePlan
    @Published var fiveHourWindowStart: Date?
    @Published var promptsUsedInWindow: Int = 0
    
    private let preferences: AppPreferences
    
    init(preferences: AppPreferences) {
        self.preferences = preferences
        self.selectedPlan = preferences.selectedClaudePlan
        self.loadWindowData()
    }
    
    // MARK: - Plan Information
    
    var planDisplayName: String {
        selectedPlan.title
    }
    
    var planDescription: String {
        selectedPlan.description
    }
    
    var isSubscriptionPlan: Bool {
        selectedPlan.isSubscriptionPlan
    }
    
    var hasUsageLimit: Bool {
        selectedPlan.hasUsageLimit
    }
    
    // MARK: - Usage Tracking
    
    var remainingPromptsInWindow: Int? {
        guard let range = selectedPlan.promptsPerFiveHours else { return nil }
        return range.upperBound - promptsUsedInWindow
    }
    
    var usagePercentageInWindow: Double? {
        guard let range = selectedPlan.promptsPerFiveHours else { return nil }
        return Double(promptsUsedInWindow) / Double(range.upperBound) * 100
    }
    
    var timeUntilWindowReset: TimeInterval? {
        guard let windowStart = fiveHourWindowStart else { return nil }
        let windowEnd = windowStart.addingTimeInterval(5 * 60 * 60) // 5 hours
        let now = Date()
        return windowEnd.timeIntervalSince(now)
    }
    
    // MARK: - Cost Interpretation
    
    func interpretCost(_ cost: Double) -> CostInterpretation {
        switch selectedPlan {
        case .pro, .max5x, .max20x:
            return .subscription(
                theoreticalCost: cost,
                includedInPlan: true,
                planCost: monthlyCost
            )
        case .apiBased:
            return .payPerUse(actualCost: cost)
        case .custom:
            return .custom(displayCost: cost)
        }
    }
    
    var monthlyCost: Double {
        switch selectedPlan {
        case .pro:
            return 20.0
        case .max5x:
            return 100.0
        case .max20x:
            return 200.0
        case .apiBased, .custom:
            return 0.0
        }
    }
    
    // MARK: - Usage Context
    
    func getUsageContext(for cost: Double, burnRate: Double) -> UsageContext {
        let costInterpretation = interpretCost(cost)
        let burnRateLevel = getBurnRateLevel(burnRate)
        
        switch selectedPlan {
        case .pro, .max5x, .max20x:
            return UsageContext(
                planType: .subscription,
                costInterpretation: costInterpretation,
                burnRateLevel: burnRateLevel,
                usageWarning: getSubscriptionUsageWarning(),
                valueMessage: getValueMessage(for: cost)
            )
        case .apiBased:
            return UsageContext(
                planType: .payPerUse,
                costInterpretation: costInterpretation,
                burnRateLevel: burnRateLevel,
                usageWarning: getAPIUsageWarning(for: cost),
                valueMessage: nil
            )
        case .custom:
            return UsageContext(
                planType: .custom,
                costInterpretation: costInterpretation,
                burnRateLevel: burnRateLevel,
                usageWarning: nil,
                valueMessage: nil
            )
        }
    }
    
    // MARK: - Window Management
    
    func updateSessionActivity() {
        let now = Date()
        
        // Check if we need to start a new 5-hour window
        if fiveHourWindowStart == nil || 
           now.timeIntervalSince(fiveHourWindowStart!) > 5 * 60 * 60 {
            startNewWindow()
        }
        
        // Increment prompts used (assuming each session represents a prompt)
        promptsUsedInWindow += 1
        saveWindowData()
    }
    
    private func startNewWindow() {
        fiveHourWindowStart = Date()
        promptsUsedInWindow = 0
    }
    
    // MARK: - Private Helpers
    
    private func getBurnRateLevel(_ burnRate: Double) -> BurnRateLevel {
        if burnRate < preferences.lowBurnRateThreshold {
            return .low
        } else if burnRate < preferences.highBurnRateThreshold {
            return .medium
        } else {
            return .high
        }
    }
    
    private func getSubscriptionUsageWarning() -> String? {
        guard let usagePercentage = usagePercentageInWindow else { return nil }
        
        if usagePercentage >= 90 {
            return "⚠️ Approaching limit for this 5-hour window"
        } else if usagePercentage >= 75 {
            return "⚡️ High usage this window"
        }
        return nil
    }
    
    private func getAPIUsageWarning(for cost: Double) -> String? {
        if cost > 10.0 {
            return "💰 High API usage costs"
        } else if cost > 5.0 {
            return "📊 Monitor API costs"
        }
        return nil
    }
    
    private func getValueMessage(for cost: Double) -> String? {
        guard selectedPlan.isSubscriptionPlan else { return nil }
        
        let dailyValue = cost * 1.0 // Assuming this is per session
        let monthlyValue = dailyValue * 30
        
        if monthlyValue > monthlyCost {
            return "Monthly cost: $\(String(format: "%.2f", monthlyValue)) (saving \(String(format: "%.2f", 100 * (1 - monthlyCost/monthlyValue)))%)!"
        }
        return nil
    }
    
    // MARK: - Persistence
    
    private func loadWindowData() {
        let defaults = UserDefaults.standard
        if let windowStartData = defaults.object(forKey: "fiveHourWindowStart") as? Date {
            fiveHourWindowStart = windowStartData
        }
        promptsUsedInWindow = defaults.integer(forKey: "promptsUsedInWindow")
    }
    
    private func saveWindowData() {
        let defaults = UserDefaults.standard
        defaults.set(fiveHourWindowStart, forKey: "fiveHourWindowStart")
        defaults.set(promptsUsedInWindow, forKey: "promptsUsedInWindow")
    }
}

// MARK: - Supporting Types

enum CostInterpretation {
    case subscription(theoreticalCost: Double, includedInPlan: Bool, planCost: Double)
    case payPerUse(actualCost: Double)
    case custom(displayCost: Double)
}

enum BurnRateLevel {
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}

enum PlanType {
    case subscription
    case payPerUse
    case custom
}

struct UsageContext {
    let planType: PlanType
    let costInterpretation: CostInterpretation
    let burnRateLevel: BurnRateLevel
    let usageWarning: String?
    let valueMessage: String?
}
