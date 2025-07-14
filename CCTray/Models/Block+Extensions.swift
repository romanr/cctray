import Foundation
import SwiftUI

extension Block {
    func formatCostTitle() -> AttributedString {
        createStyledTitle(text: " $\(String(format: "%.2f", costUSD))")
    }
    
    func formatBurnRateTitle(preferences: AppPreferences) -> AttributedString {
        let status = burnRateStatus(preferences: preferences)
        return createStyledTitle(text: " \(status.emoji) \(status.text)")
    }
    
    func formatRemainingTimeTitle() -> AttributedString {
        let remaining = remainingTimeString()
        return createStyledTitle(text: " ⏱️ \(remaining)")
    }
    
    private func createStyledTitle(text: String) -> AttributedString {
        var attributedString = AttributedString("C" + text)
        
        // First, apply default styling to the entire string
        attributedString.font = .system(size: 14, weight: .medium, design: .monospaced)
        
        // Then, style the "C" character in bright orange
        if let range = attributedString.range(of: "C") {
            attributedString[range].foregroundColor = ClaudeColors.brightOrange
            attributedString[range].font = .system(size: 14, weight: .bold, design: .monospaced) // Make it bold too
        }
        
        return attributedString
    }
    
    private func burnRateStatus(preferences: AppPreferences) -> (emoji: String, text: String) {
        switch burnRate.tokensPerMinute {
        case ..<preferences.lowBurnRateThreshold:
            return ("🟢", "LOW")
        case preferences.lowBurnRateThreshold..<preferences.highBurnRateThreshold:
            return ("🟡", "MED")
        default:
            return ("🔴", "HIGH")
        }
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
    
    func formatDetailedInfo() -> [String] {
        let remaining = remainingTimeString()
        let startTime = formatStartTime()
        let burnRateFormatted = formatBurnRateDetailed()
        
        return [
            "⏱️ Session: Started \(startTime) / Remaining \(remaining)",
            "",
            "💰 Current Cost: $\(String(format: "%.2f", costUSD))",
            "🔥 Burn Rate: \(burnRateFormatted) (\(Int(burnRate.tokensPerMinute)) token/min)",
            "📊 Tokens Used: \(formatNumber(totalTokens))",
            "",
            "📈 Projected Cost: $\(String(format: "%.2f", projection.totalCost))",
            "🎯 API Calls: \(formatNumber(entries))"
        ]
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
    
    private func formatBurnRateDetailed() -> String {
        switch burnRate.tokensPerMinute {
        case ..<300:
            return "🟢 LOW"
        case 300..<700:
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
}