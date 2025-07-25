import SwiftUI
import Charts

/// A comprehensive dashboard window for data visualization
struct ChartDashboardView: View {
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeRange: ChartTimeRange = .session
    @State private var selectedMetrics: Set<MetricType> = [.cost, .burnRate, .tokenUsage]
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with controls
                headerView
                
                Divider()
                
                // Main chart area
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Current session summary
                        if let block = usageMonitor.currentBlock {
                            currentSessionSummary(block: block)
                        }
                        
                        // Chart grid
                        chartGrid
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .navigationTitle("Usage Analytics Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            dashboardSettingsView
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            // Time range selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(ChartTimeRange.allCases) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Metric toggles
            HStack {
                Text("Metrics:")
                    .font(.headline)
                
                ForEach(MetricType.allCases) { metric in
                    Button(action: {
                        if selectedMetrics.contains(metric) {
                            selectedMetrics.remove(metric)
                        } else {
                            selectedMetrics.insert(metric)
                        }
                    }) {
                        Label(metric.displayName, systemImage: selectedMetrics.contains(metric) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMetrics.contains(metric) ? ClaudeColors.primary : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
    
    @ViewBuilder
    private func currentSessionSummary(block: Block) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Session")
                .font(.headline)
                .foregroundColor(ClaudeColors.primary)
            
            HStack(spacing: 20) {
                // Cost summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", block.costUSD))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ClaudeColors.primary)
                }
                
                // Burn rate summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Burn Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f t/m", block.burnRate.tokensPerMinute))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ClaudeColors.primary)
                }
                
                // Token usage summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tokens Used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f", Double(block.totalTokens)))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ClaudeColors.primary)
                }
                
                // Projected cost summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected Cost")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.2f", block.projection.totalCost))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(ClaudeColors.primary)
                }
                
                Spacer()
            }
            
            // Progress indicators
            if let tokenLimit = block.tokenLimitStatus {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token Limit Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: tokenLimit.percentUsed / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: getTokenLimitColor(percentage: tokenLimit.percentUsed)))
                        .frame(height: 8)
                    
                    Text("\(String(format: "%.1f", tokenLimit.percentUsed))% of \(tokenLimit.limit) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.quaternaryLabelColor).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var chartGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(selectedMetrics), id: \.self) { metric in
                chartCard(for: metric)
            }
        }
    }
    
    @ViewBuilder
    private func chartCard(for metric: MetricType) -> some View {
        let chartData = usageMonitor.getChartData(for: metric, in: selectedTimeRange)
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.displayName)
                        .font(.headline)
                        .foregroundColor(ClaudeColors.primary)
                    
                    if let latestValue = chartData.last?.value {
                        Text(metric.formatValue(latestValue))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Trend indicator
                TrendIndicatorView(
                    direction: usageMonitor.getTrendDirection(for: metric, in: selectedTimeRange),
                    value: chartData.last?.value ?? 0,
                    metric: metric
                )
            }
            
            // Chart
            if !chartData.isEmpty {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(metric.displayName, point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(getMetricColor(for: metric))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value(metric.displayName, point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(getMetricColor(for: metric).opacity(0.1))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
            } else {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Chart data will appear as you use Claude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var dashboardSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Dashboard Settings")
                .font(.headline)
            
            GroupBox("Chart Configuration") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Default Time Range:")
                        Spacer()
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(ChartTimeRange.allCases) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: 150)
                    }
                    
                    Toggle("Show Animations", isOn: .constant(preferences.showChartAnimations))
                        .disabled(true) // Read-only view of preference
                    
                    Toggle("Show Data Points", isOn: .constant(preferences.showChartDataPoints))
                        .disabled(true) // Read-only view of preference
                    
                    Toggle("Show Trend Lines", isOn: .constant(preferences.showChartTrendLines))
                        .disabled(true) // Read-only view of preference
                }
            }
            
            GroupBox("Data Management") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Data Retention:")
                        Spacer()
                        Text("\(preferences.chartDataRetentionDays) days")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Old Data") {
                        usageMonitor.clearOldChartData(olderThan: preferences.chartDataRetentionDays)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Close") {
                    showingSettings = false
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Helper Methods
    
    private func getMetricColor(for metric: MetricType) -> Color {
        switch metric {
        case .cost, .projectedCost:
            return ClaudeColors.chartPrimary
        case .burnRate:
            return ClaudeColors.primary
        case .tokenUsage:
            return ClaudeColors.chartSecondary
        case .apiCalls:
            return ClaudeColors.secondary
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
            return ClaudeColors.warning
        } else if percentage >= 60 {
            return .yellow
        } else {
            return .green
        }
    }
}

#Preview {
    ChartDashboardView()
        .environmentObject(UsageMonitor())
        .environmentObject(AppPreferences())
}