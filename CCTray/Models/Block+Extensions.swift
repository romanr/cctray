import Foundation
import SwiftUI

extension Block {
    func formatCostTitle(preferences: AppPreferences) -> AttributedString {
        let prefix = preferences.useTextForCost ? " COST " : " $"
        let formatString = "%.\(preferences.costDecimalPlaces)f"
        return createStyledTitle(text: "\(prefix)\(String(format: formatString, costUSD))")
    }
    
    func formatBurnRateTitle(preferences: AppPreferences) -> AttributedString {
        let status = burnRateStatus(preferences: preferences)
        return createStyledTitle(text: " \(status.emoji) \(status.text)")
    }
    
    func formatRemainingTimeTitle(preferences: AppPreferences) -> AttributedString {
        let remaining = remainingTimeString()
        let prefix = preferences.useTextForRemainingTime ? " TIME " : " ⏱️ "
        return createStyledTitle(text: "\(prefix)\(remaining)")
    }
    
    func formatProjectedCostTitle(preferences: AppPreferences) -> AttributedString {
        let prefix = preferences.useTextForProjectedCost ? " PROJ $" : " 📊 $"
        let formatString = "%.\(preferences.costDecimalPlaces)f"
        return createStyledTitle(text: "\(prefix)\(String(format: formatString, projection.totalCost))")
    }
    
    func formatApiCallsTitle(preferences: AppPreferences) -> AttributedString {
        let prefix = preferences.useTextForApiCalls ? " API " : " 🔄 "
        return createStyledTitle(text: "\(prefix)\(entries)")
    }
    
    func formatTokenLimitTitle(preferences: AppPreferences) -> AttributedString {
        guard let tokenLimitStatus = tokenLimitStatus else {
            let prefix = preferences.useTextForTokenLimit ? " TOK " : " 🚫 "
            return createStyledTitle(text: "\(prefix)N/A")
        }
        
        let percentage = String(format: "%.1f", tokenLimitStatus.percentUsed)
        let indicator = preferences.useTextForTokenLimit ? "TOK" : tokenLimitEmoji(for: tokenLimitStatus.percentUsed)
        return createStyledTitle(text: " \(indicator) \(percentage)%")
    }
    
    func formatTokenUsageTitle(preferences: AppPreferences) -> AttributedString {
        let prefix = preferences.useTextForTokenUsage ? " TOKENS " : " 🔢 "
        let formattedTokens = formatNumber(totalTokens)
        return createStyledTitle(text: "\(prefix)\(formattedTokens)")
    }
    
    private func createStyledTitle(text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Apply styling to the entire string
        attributedString.font = .system(size: 14, weight: .medium, design: .monospaced)
        
        return attributedString
    }
    
    private func burnRateStatus(preferences: AppPreferences) -> (emoji: String, text: String) {
        let emoji: String
        let text: String
        
        // Determine color based on thresholds
        switch burnRate.tokensPerMinute {
        case ..<preferences.lowBurnRateThreshold:
            emoji = preferences.useTextForBurnRate ? "BURN" : "🟢"
        case preferences.lowBurnRateThreshold..<preferences.highBurnRateThreshold:
            emoji = preferences.useTextForBurnRate ? "BURN" : "🟡"
        default:
            emoji = preferences.useTextForBurnRate ? "BURN" : "🔴"
        }
        
        // Format text based on user preference
        switch preferences.burnRateFormat {
        case .category:
            switch burnRate.tokensPerMinute {
            case ..<preferences.lowBurnRateThreshold:
                text = "LOW"
            case preferences.lowBurnRateThreshold..<preferences.highBurnRateThreshold:
                text = "MED"
            default:
                text = "HIGH"
            }
        case .numeric:
            text = "\(Int(burnRate.tokensPerMinute)) t/m"
        }
        
        return (emoji: emoji, text: text)
    }
    
    private func remainingTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let endTime = formatter.date(from: endTime),
              let actualEndTime = formatter.date(from: actualEndTime) else {
            return "N/A"
        }
        
        let remaining = endTime.timeIntervalSince(actualEndTime)
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    func formatDetailedInfo(preferences: AppPreferences) -> [String] {
        let remaining = remainingTimeString()
        let startTime = formatStartTime()
        let burnRateFormatted = formatBurnRateDetailed(preferences: preferences)
        
        var info = [
            "⏱️ Session: Started \(startTime) / Remaining \(remaining)",
            "",
            "💰 Current Cost: $\(String(format: "%.2f", costUSD))",
            "🔥 Burn Rate: \(burnRateFormatted) (\(Int(burnRate.tokensPerMinute)) token/min)",
            "📊 Tokens Used: \(formatNumber(totalTokens))",
            "",
            "📈 Projected Cost: $\(String(format: "%.2f", projection.totalCost))",
            "🎯 API Calls: \(formatNumber(entries))"
        ]
        
        // Add token limit information if available
        if let tokenLimitStatus = tokenLimitStatus {
            info.append("")
            info.append("🎯 Token Limit: \(formatNumber(tokenLimitStatus.projectedUsage))/\(formatNumber(tokenLimitStatus.limit)) (\(Int(tokenLimitStatus.percentUsed))%)")
        }
        
        return info
    }
    
    private func formatStartTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let startDate = formatter.date(from: startTime) else {
            return "N/A"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: startDate)
    }
    
    private func formatBurnRateDetailed(preferences: AppPreferences) -> String {
        switch burnRate.tokensPerMinute {
        case ..<preferences.lowBurnRateThreshold:
            return "🟢 LOW"
        case preferences.lowBurnRateThreshold..<preferences.highBurnRateThreshold:
            return "🟡 MODERATE"
        default:
            return "🔴 HIGH"
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        switch num {
        case 1_000_000...:
            return String(format: "%.1fM", Double(num) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fk", Double(num) / 1_000)
        default:
            return String(num)
        }
    }
    
    private func tokenLimitEmoji(for percentage: Double) -> String {
        switch percentage {
        case ..<50:
            return "🟢"
        case 50..<80:
            return "🟡"
        case 80..<95:
            return "🟠"
        default:
            return "🔴"
        }
    }
    
    // MARK: - Token Limit Notification Methods
    
    func formatTokenLimitNotificationTitle(for percentage: Double) -> String {
        let rounded = Int(percentage.rounded())
        
        switch percentage {
        case ..<75:
            return "Token Usage: \(rounded)% used"
        case 75..<85:
            return "Token Usage: \(rounded)% used"
        case 85..<95:
            return "Token Limit Warning: \(rounded)% used"
        default:
            return "Critical: \(rounded)% tokens used"
        }
    }
    
    func formatTokenLimitNotificationBody(for percentage: Double, remaining: Int, resetTime: String?) -> String {
        let remainingFormatted = formatNumber(remaining)
        
        var body: String
        
        switch percentage {
        case ..<75:
            body = "(\(remainingFormatted) remaining)"
        case 75..<85:
            body = "(\(remainingFormatted) remaining)"
        case 85..<95:
            body = "Consider reducing usage. \(remainingFormatted) tokens remaining."
        default:
            body = "Only \(remainingFormatted) remaining!"
        }
        
        // Add reset time for high usage scenarios
        if percentage >= 85, let resetTime = resetTime {
            body += " Resets at \(resetTime)."
        }
        
        return body
    }
    
    func getTokenLimitNotificationSeverity(for percentage: Double) -> String {
        switch percentage {
        case ..<75:
            return "info"
        case 75..<85:
            return "warning"
        case 85..<95:
            return "high"
        default:
            return "critical"
        }
    }
    
    // MARK: - Helper Methods for Token Limit Notifications
    
    func calculateRemainingTokens() -> Int {
        guard let tokenLimitStatus = tokenLimitStatus else {
            return 0
        }
        
        return max(0, tokenLimitStatus.limit - tokenLimitStatus.projectedUsage)
    }
    
    func formatResetTime() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        guard let endDate = formatter.date(from: endTime) else {
            return nil
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: endDate)
    }
    
    func getNotificationCategory(for percentage: Double) -> String {
        switch percentage {
        case ..<75:
            return "token_usage"
        case 75..<85:
            return "token_warning"
        case 85..<95:
            return "token_high"
        default:
            return "token_critical"
        }
    }
}