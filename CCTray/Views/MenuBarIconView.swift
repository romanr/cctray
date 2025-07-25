import SwiftUI

struct MenuBarIconView: View {
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        // Show both the dynamic icon and rotating usage text
        HStack(spacing: 4) {
            // Main icon with optional mini-chart overlay
            ZStack {
                // Dynamic PNG-based icon with enhanced features (if enabled) or fallback to static icon
                if preferences.enableColorCodedIcons || preferences.enableProgressIndicator {
                if usageMonitor.shouldPulse && preferences.enablePulseAnimation {
                    let iconImage = preferences.progressIndicatorStyle == .bottomRightDot ?
                        IconCreator.createPNGBasedPulsingIconWithDotIndicator(
                            state: usageMonitor.iconState,
                            progressPercent: usageMonitor.progressPercent,
                            showProgress: usageMonitor.showProgressIndicator,
                            pulsePhase: usageMonitor.pulsePhase,
                            dotPosition: preferences.dotIndicatorPosition
                        ) :
                        IconCreator.createPNGBasedPulsingIcon(
                            state: usageMonitor.iconState,
                            progressPercent: usageMonitor.progressPercent,
                            showProgress: usageMonitor.showProgressIndicator,
                            pulsePhase: usageMonitor.pulsePhase
                        )
                    
                    Image(nsImage: iconImage)
                        .animation(.easeInOut(duration: 0.1), value: usageMonitor.pulsePhase)
                } else {
                    let iconImage = preferences.progressIndicatorStyle == .bottomRightDot ?
                        IconCreator.createPNGBasedIconWithDotIndicator(
                            state: usageMonitor.iconState,
                            progressPercent: usageMonitor.progressPercent,
                            showProgress: usageMonitor.showProgressIndicator,
                            dotPosition: preferences.dotIndicatorPosition
                        ) :
                        IconCreator.createPNGBasedIcon(
                            state: usageMonitor.iconState,
                            progressPercent: usageMonitor.progressPercent,
                            showProgress: usageMonitor.showProgressIndicator
                        )
                    
                    Image(nsImage: iconImage)
                }
                } else {
                    // Fallback to static icon (original PNG)
                    Image("c")
                }
                
                // Mini-chart overlay (if enabled)
                if preferences.enableMiniCharts && usageMonitor.currentBlock != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            miniChartOverlay
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(usageMonitor.getCurrentTitle())
                
                // Billing plan context (if available)
                if let planInfo = usageMonitor.getBillingPlanInfo() {
                    Text(planInfo.title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }
                
                // Sparkline chart below the title (if enabled)
                if preferences.enableSparklines && usageMonitor.currentBlock != nil {
                    sparklineChart
                }
            }
            
            // Show countdown when refresh is imminent (≤ 10 seconds)
            if usageMonitor.secondsUntilNextRefresh > 0 && usageMonitor.secondsUntilNextRefresh <= 10 {
                Text("(\(usageMonitor.secondsUntilNextRefresh))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            print("MenuBarIconView appeared")
            usageMonitor.configure(with: preferences, notificationManager: notificationManager)
        }
        .onChange(of: preferences.updateInterval) {
            usageMonitor.configure(with: preferences, notificationManager: notificationManager)
        }
        .onChange(of: preferences.rotationInterval) {
            usageMonitor.configure(with: preferences, notificationManager: notificationManager)
        }
        .onChange(of: preferences.ccusageCommandPath) {
            usageMonitor.refreshData()
        }
    }
    
    // MARK: - Mini-Chart Components
    
    @ViewBuilder
    private var miniChartOverlay: some View {
        // Small progress indicator overlay on the icon
        if let block = usageMonitor.currentBlock, let tokenLimit = block.tokenLimitStatus {
            Circle()
                .fill(getTokenLimitColor(percentage: tokenLimit.percentUsed))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        } else if let planInfo = usageMonitor.getBillingPlanInfo(), planInfo.isSubscription {
            // Show subscription indicator for Max plans
            Circle()
                .fill(getSubscriptionPlanColor(planTitle: planInfo.title))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
    
    @ViewBuilder
    private var sparklineChart: some View {
        // Sparkline chart for the current display metric
        let currentMetric = getCurrentMetricType()
        let chartData = usageMonitor.getChartData(for: currentMetric, in: .fifteenMinutes)
        
        if !chartData.isEmpty {
            SparklineChartView(
                data: chartData,
                metric: currentMetric,
                color: getMetricColor(for: currentMetric)
            )
            .frame(height: 12)
            .opacity(0.8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMetricType() -> MetricType {
        switch usageMonitor.displayState {
        case .cost:
            return .cost
        case .burnRate:
            return .burnRate
        case .projectedCost:
            return .projectedCost
        case .apiCalls:
            return .apiCalls
        case .tokenLimit:
            return .tokenLimit
        case .tokenUsage:
            return .tokenUsage
        case .remainingTime:
            return .tokenUsage // Use tokenUsage as proxy for remaining time
        case .sessionsToday:
            return .apiCalls // Use apiCalls as proxy for sessions
        }
    }
    
    private func getMetricColor(for metric: MetricType) -> Color {
        switch metric {
        case .cost, .projectedCost:
            return ClaudeColors.secondary
        case .burnRate:
            return ClaudeColors.primary
        case .tokenUsage:
            return ClaudeColors.secondary
        case .apiCalls:
            return ClaudeColors.primary
        case .tokenLimit:
            return ClaudeColors.error
        case .remainingTime:
            return ClaudeColors.primary
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
    
    private func getSubscriptionPlanColor(planTitle: String) -> Color {
        switch planTitle {
        case "Pro Plan":
            return ClaudeColors.primary
        case "Max Plan 5x":
            return ClaudeColors.primary
        case "Max Plan 20x":
            return .pink
        default:
            return .gray
        }
    }
}