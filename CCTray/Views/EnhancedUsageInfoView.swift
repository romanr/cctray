import SwiftUI

/// Enhanced version of UsageInfoView with progress bars and visual indicators
struct EnhancedUsageInfoView: View {
    let info: [String]
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Text-based information (existing)
            if !preferences.enableProgressBars {
                ForEach(0..<info.count, id: \.self) { index in
                    InfoRowView(text: info[index])
                }
            } else {
                // Enhanced version with progress bars and visual indicators
                enhancedMetricsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.quaternaryLabelColor).opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var enhancedMetricsView: some View {
        if let block = usageMonitor.currentBlock {
            VStack(alignment: .leading, spacing: 6) {
                // Billing Plan Context Section
                billingPlanContextView
                
                // Cost with progress bar
                if preferences.showCost {
                    enhancedMetricRow(
                        title: "Cost",
                        value: block.formatCostValue(preferences: preferences),
                        progress: getCostProgress(block: block),
                        color: getCostColor(block: block),
                        metric: .cost
                    )
                }
                
                // Burn Rate with progress bar
                if preferences.showBurnRate {
                    enhancedMetricRow(
                        title: "Burn Rate",
                        value: block.formatBurnRateValue(preferences: preferences),
                        progress: getBurnRateProgress(block: block),
                        color: getBurnRateColor(block: block),
                        metric: .burnRate
                    )
                }
                
                // Token Usage with progress bar
                if preferences.showTokenLimit, let tokenLimit = block.tokenLimitStatus {
                    enhancedMetricRow(
                        title: "Token Limit",
                        value: "\(Int(tokenLimit.percentUsed))%",
                        progress: tokenLimit.percentUsed / 100.0,
                        color: getTokenLimitColor(percentage: tokenLimit.percentUsed),
                        metric: .tokenLimit
                    )
                }
                
                // Token Usage Breakdown
                if preferences.showTokenUsage {
                    enhancedMetricRow(
                        title: "Token Usage",
                        value: "Total: \(formatTokenCount(block.tokenCounts.outputTokens+block.tokenCounts.inputTokens))",
                        progress: getTokenUsageProgress(block: block),
                        color: getTokenUsageColor(block: block),
                        metric: .tokenUsage
                    )
                }
                
                // API Calls with visual indicator
                if preferences.showApiCalls {
                    enhancedMetricRow(
                        title: "API Calls",
                        value: "\(formatTokenCount(block.entries))",
                        progress: getApiCallsProgress(block: block),
                        color: ClaudeColors.primary,
                        metric: .apiCalls
                    )
                }
                
                // Projected Cost with progress bar
                if preferences.showProjectedCost {
                    enhancedMetricRow(
                        title: "Projected Cost",
                        value: block.formatProjectedCostValue(preferences: preferences),
                        progress: getProjectedCostProgress(block: block),
                        color: getProjectedCostColor(block: block),
                        metric: .projectedCost
                    )
                }
                
                // Remaining Time with visual indicator
                if preferences.showRemainingTime {
                    enhancedMetricRow(
                        title: "Remaining Time",
                        value: block.formatRemainingTimeValue(preferences: preferences),
                        progress: getRemainingTimeProgress(block: block),
                        color: getRemainingTimeColor(block: block),
                        metric: .remainingTime
                    )
                }
                
                // Sessions Today
                if preferences.showSessionsToday {
                    enhancedMetricRow(
                        title: "Sessions Today",
                        value: "\(formatTokenCount(usageMonitor.sessionsToday))",
                        progress: getSessionsProgress(),
                        color: ClaudeColors.primary,
                        metric: .sessionsToday
                    )
                }
            }
        } else {
            // Fallback to text-based display when no active block
            ForEach(0..<info.count, id: \.self) { index in
                InfoRowView(text: info[index])
            }
        }
    }
    
    @ViewBuilder
    private func enhancedMetricRow(
        title: String,
        value: String,
        progress: Double,
        color: Color,
        metric: MetricType
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ClaudeColors.secondary)
                
                Spacer()
                
                HStack(spacing: 6) {
                    // Trend indicator
                    if preferences.enableTrendIndicators {
                        TrendIndicatorView(
                            direction: usageMonitor.getTrendDirection(for: metric, in: preferences.chartTimeRangeEnum),
                            value: usageMonitor.getLatestValue(for: metric) ?? 0,
                            metric: metric,
                            compact: true
                        )
                    }
                    
                    // Value
                    Text(value)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            
            // Progress bar - special handling for token usage
            if metric == .tokenUsage, let block = usageMonitor.currentBlock {
                tokenUsageStackedBar(for: block)
            } else {
                // Standard progress bar for other metrics
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(ClaudeColors.secondaryBackground)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                        
                        // Progress
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * min(max(progress, 0.0), 1.0), height: 3)
                            .cornerRadius(1.5)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 3)
            }
            
            // Sparkline chart (optional)
            if preferences.enableSparklines {
                let chartData = usageMonitor.getChartData(for: metric, in: .fifteenMinutes)
                if !chartData.isEmpty {
                    SparklineChartView(data: chartData, metric: metric, color: color)
                        .frame(height: 16)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Token Usage Stacked Bar Chart
    
    @ViewBuilder
    private func tokenUsageStackedBar(for block: Block) -> some View {
        let inputTokens = Double(block.tokenCounts.inputTokens)
        let outputTokens = Double(block.tokenCounts.outputTokens)
        let totalTokens = inputTokens + outputTokens
        
        if totalTokens > 0 {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Input tokens segment (left side)
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * (inputTokens / totalTokens), height: 6)
                    
                    // Output tokens segment (right side)
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * (outputTokens / totalTokens), height: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    // Subtle border
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
                .animation(.easeInOut(duration: 0.3), value: inputTokens)
                .animation(.easeInOut(duration: 0.3), value: outputTokens)
            }
            .frame(height: 6)
            
            // Token counts as small labels below the bar
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text("In: \(formatTokenCount(Int(inputTokens)))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Out: \(formatTokenCount(Int(outputTokens)))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)
        } else {
            // Empty state
            Rectangle()
                .fill(ClaudeColors.secondaryBackground)
                .frame(height: 6)
                .cornerRadius(3)
                .overlay(
                    Text("No tokens")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                )
        }
    }
    
    // MARK: - Progress Calculation Methods
    
    private func getCostProgress(block: Block) -> Double {
        // Progress based on projected cost vs current cost
        let current = block.costUSD
        let projected = block.projection.totalCost
        return projected > 0 ? min(current / projected, 1.0) : 0.0
    }
    
    private func getBurnRateProgress(block: Block) -> Double {
        // Progress based on burn rate thresholds
        let burnRate = block.burnRate.tokensPerMinute
        let maxThreshold = preferences.highBurnRateThreshold
        return min(burnRate / maxThreshold, 1.0)
    }
    
    private func getApiCallsProgress(block: Block) -> Double {
        // Progress based on typical session API calls (estimated max of 50)
        let maxCalls = 50.0
        return min(Double(block.entries) / maxCalls, 1.0)
    }
    
    private func getProjectedCostProgress(block: Block) -> Double {
        // Progress based on current vs projected cost
        let current = block.costUSD
        let projected = block.projection.totalCost
        return projected > 0 ? min(current / projected, 1.0) : 0.0
    }
    
    private func getRemainingTimeProgress(block: Block) -> Double {
        // Progress based on elapsed time vs total session time
        let remainingMinutes = Double(block.projection.remainingMinutes)
        let totalMinutes = remainingMinutes + getElapsedMinutes(block: block)
        return totalMinutes > 0 ? min(getElapsedMinutes(block: block) / totalMinutes, 1.0) : 0.0
    }
    
    private func getSessionsProgress() -> Double {
        // Progress based on typical daily sessions (estimated max of 10)
        let maxSessions = 10.0
        return min(Double(usageMonitor.sessionsToday) / maxSessions, 1.0)
    }
    
    private func getTokenUsageProgress(block: Block) -> Double {
        // Progress based on output/input ratio (higher ratio = more progress)
        let outputTokens = Double(block.tokenCounts.outputTokens)
        let inputTokens = Double(block.tokenCounts.inputTokens)
        
        if inputTokens == 0 {
            return outputTokens > 0 ? 1.0 : 0.0
        }
        
        let ratio = outputTokens / inputTokens
        // Normalize ratio to 0-1 range, assuming typical ratio is 0.5-2.0
        return min(ratio / 2.0, 1.0)
    }
    
    private func getElapsedMinutes(block: Block) -> Double {
        // Calculate elapsed time from block start time
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let startTime = formatter.date(from: block.startTime) {
            let elapsedSeconds = Date().timeIntervalSince(startTime)
            return elapsedSeconds / 60.0
        }
        return 0.0
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        switch count {
        case 1_000_000_000...:
            return String(format: "%.1fB", Double(count) / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", Double(count) / 1_000)
        default:
            return String(count)
        }
    }
    
    // MARK: - Color Calculation Methods
    
    private func getCostColor(block: Block) -> Color {
        let progress = getCostProgress(block: block)
        if progress > 0.8 {
            return .red
        } else if progress > 0.6 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getBurnRateColor(block: Block) -> Color {
        let burnRate = block.burnRate.tokensPerMinute
        if burnRate > preferences.highBurnRateThreshold {
            return .red
        } else if burnRate > preferences.lowBurnRateThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getTokenLimitColor(percentage: Double) -> Color {
        if percentage >= 95 {
            return .red
        } else if percentage >= 80 {
            return .orange
        } else if percentage >= 60 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func getProjectedCostColor(block: Block) -> Color {
        let projected = block.projection.totalCost
        if projected > 5.0 {
            return .red
        } else if projected > 2.0 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getRemainingTimeColor(block: Block) -> Color {
        let remainingMinutes = block.projection.remainingMinutes
        if remainingMinutes < 5 {
            return .red
        } else if remainingMinutes < 15 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getTokenUsageColor(block: Block) -> Color {
        let outputTokens = Double(block.tokenCounts.outputTokens)
        let inputTokens = Double(block.tokenCounts.inputTokens)
        
        if inputTokens == 0 {
            return .gray
        }
        
        let ratio = outputTokens / inputTokens
        // Color based on efficiency: higher output/input ratio = more efficient
        if ratio > 1.5 {
            return .green  // High efficiency
        } else if ratio > 0.8 {
            return .orange // Medium efficiency
        } else {
            return .red    // Low efficiency
        }
    }
    
    // MARK: - Billing Plan Context View
    
    @ViewBuilder
    private var billingPlanContextView: some View {
        if let planInfo = usageMonitor.getBillingPlanInfo() {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Billing Plan")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ClaudeColors.secondary)
                    
                    Spacer()
                    
                    Text(planInfo.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                // Plan-specific context
                if let costContext = usageMonitor.getPlanAwareCostContext() {
                    Text(costContext.contextMessage)
                        .font(.system(size: 10))
                        .foregroundColor(ClaudeColors.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Usage context for Max plans
                if planInfo.isSubscription, let usageContext = usageMonitor.getPlanAwareUsageContext() {
                    if let warning = usageContext.usageWarning {
                        HStack {
                            Text(warning)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                    
                    if let valueMessage = usageContext.valueMessage {
                        Text(valueMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.bottom, 4)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Block Extensions for Enhanced Formatting

extension Block {
    func formatCostValue(preferences: AppPreferences) -> String {
        return String(format: "$%.2f", costUSD)
    }
    
    func formatBurnRateValue(preferences: AppPreferences) -> String {
        if preferences.burnRateFormat == .category {
            return getBurnRateCategory(preferences: preferences)
        } else {
            return String(format: "%.0f t/m", burnRate.tokensPerMinute)
        }
    }
    
    func formatProjectedCostValue(preferences: AppPreferences) -> String {
        return String(format: "$%.2f", projection.totalCost)
    }
    
    func formatRemainingTimeValue(preferences: AppPreferences) -> String {
        let minutes = projection.remainingMinutes
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func getBurnRateCategory(preferences: AppPreferences) -> String {
        let rate = burnRate.tokensPerMinute
        if rate > preferences.highBurnRateThreshold {
            return "HIGH"
        } else if rate > preferences.lowBurnRateThreshold {
            return "MED"
        } else {
            return "LOW"
        }
    }
}

// MARK: - Backward Compatibility MetricType Extension

extension MetricType {
    static var sessionsToday: MetricType {
        return .apiCalls // Reuse apiCalls for sessions tracking
    }
}

#Preview {
    EnhancedUsageInfoView(info: ["Sample info"])
        .environmentObject(UsageMonitor())
        .environmentObject(AppPreferences())
        .frame(width: 300)
        .padding()
}
