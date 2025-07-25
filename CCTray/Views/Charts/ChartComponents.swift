import SwiftUI
import Charts

// MARK: - Base Chart Components

/// A reusable line chart component
struct LineChartView: View {
    let data: [ChartDataPoint]
    let configuration: ChartConfiguration
    let metric: MetricType
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value(metric.displayName, point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            
            if configuration.showDataPoints {
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value(metric.displayName, point.value)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
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
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
        .frame(height: 120)
    }
}

/// A reusable bar chart component
struct BarChartView: View {
    let data: [ChartDataPoint]
    let configuration: ChartConfiguration
    let metric: MetricType
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Time", point.timestamp),
                y: .value(metric.displayName, point.value)
            )
            .foregroundStyle(.blue.gradient)
            .cornerRadius(2)
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
        .frame(height: 120)
    }
}

/// A compact sparkline chart for inline display
struct SparklineChartView: View {
    let data: [ChartDataPoint]
    let metric: MetricType
    let color: Color
    
    init(data: [ChartDataPoint], metric: MetricType, color: Color = .blue) {
        self.data = data
        self.metric = metric
        self.color = color
    }
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value(metric.displayName, point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(.clear)
        }
        .frame(width: 60, height: 20)
    }
}

/// A gauge chart for progress visualization
struct GaugeChartView: View {
    let value: Double
    let maxValue: Double
    let metric: MetricType
    let color: Color
    
    private var percentage: Double {
        min(value / maxValue, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: percentage)
                
                // Center text
                VStack(spacing: 2) {
                    Text(metric.formatValue(value))
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(metric.unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
            
            Text(metric.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

/// A progress bar component for linear progress visualization
struct ProgressBarChartView: View {
    let value: Double
    let maxValue: Double
    let metric: MetricType
    let color: Color
    
    private var percentage: Double {
        min(max(value / maxValue, 0.0), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(metric.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(metric.formatValue(value))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.8), value: percentage)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Trend Indicator Components

/// A trend indicator showing direction and value
struct TrendIndicatorView: View {
    let direction: TrendDirection
    let value: Double
    let metric: MetricType
    let compact: Bool
    
    init(direction: TrendDirection, value: Double, metric: MetricType, compact: Bool = false) {
        self.direction = direction
        self.value = value
        self.metric = metric
        self.compact = compact
    }
    
    var body: some View {
        HStack(spacing: compact ? 2 : 4) {
            Text(direction.symbol)
                .font(.system(size: compact ? 10 : 12))
                .foregroundColor(direction.color)
            
            if !compact {
                Text(metric.formatValue(value))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, compact ? 2 : 4)
        .padding(.vertical, compact ? 1 : 2)
        .background(
            RoundedRectangle(cornerRadius: compact ? 2 : 4)
                .fill(direction.color.opacity(0.1))
        )
    }
}

// MARK: - Composite Chart Views

/// A combined chart view that can display multiple chart types
struct CompositeChartView: View {
    let data: [ChartDataPoint]
    let configuration: ChartConfiguration
    let metric: MetricType
    let showTrend: Bool
    
    @StateObject private var chartDataManager = ChartDataManager()
    
    init(data: [ChartDataPoint], configuration: ChartConfiguration, metric: MetricType, showTrend: Bool = true) {
        self.data = data
        self.configuration = configuration
        self.metric = metric
        self.showTrend = showTrend
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with trend indicator
            HStack {
                Text(metric.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showTrend && !data.isEmpty {
                    TrendIndicatorView(
                        direction: chartDataManager.getTrendDirection(for: metric, in: configuration.timeRange),
                        value: data.last?.value ?? 0,
                        metric: metric,
                        compact: true
                    )
                }
            }
            
            // Chart content
            chartContent
                .animation(.easeInOut(duration: configuration.animated ? 0.8 : 0), value: data.count)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.quaternaryLabelColor).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor).opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var chartContent: some View {
        switch configuration.chartType {
        case .line:
            LineChartView(data: data, configuration: configuration, metric: metric)
        case .bar:
            BarChartView(data: data, configuration: configuration, metric: metric)
        case .sparkline:
            SparklineChartView(data: data, metric: metric)
        case .area:
            AreaChartView(data: data, configuration: configuration, metric: metric)
        case .gauge:
            if let latestValue = data.last?.value {
                GaugeChartView(value: latestValue, maxValue: getMaxValue(), metric: metric, color: getMetricColor())
            }
        }
    }
    
    private func getMaxValue() -> Double {
        switch metric {
        case .tokenLimit:
            return 100.0
        case .cost, .projectedCost:
            return data.map { $0.value }.max() ?? 1.0
        case .burnRate:
            return data.map { $0.value }.max() ?? 10.0
        case .tokenUsage:
            return data.map { $0.value }.max() ?? 1000.0
        case .apiCalls:
            return data.map { $0.value }.max() ?? 50.0
        case .remainingTime:
            return data.map { $0.value }.max() ?? 60.0
        }
    }
    
    private func getMetricColor() -> Color {
        switch metric {
        case .cost, .projectedCost:
            return .green
        case .burnRate:
            return .orange
        case .tokenUsage:
            return .blue
        case .apiCalls:
            return .purple
        case .tokenLimit:
            return .red
        case .remainingTime:
            return .cyan
        }
    }
}

/// Area chart component
struct AreaChartView: View {
    let data: [ChartDataPoint]
    let configuration: ChartConfiguration
    let metric: MetricType
    
    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value(metric.displayName, point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue.gradient.opacity(0.3))
            
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value(metric.displayName, point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
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
        .frame(height: 120)
    }
}

// MARK: - Preview Support

#Preview {
    let sampleData = [
        ChartDataPoint(timestamp: Date().addingTimeInterval(-300), value: 0.15),
        ChartDataPoint(timestamp: Date().addingTimeInterval(-240), value: 0.22),
        ChartDataPoint(timestamp: Date().addingTimeInterval(-180), value: 0.18),
        ChartDataPoint(timestamp: Date().addingTimeInterval(-120), value: 0.35),
        ChartDataPoint(timestamp: Date().addingTimeInterval(-60), value: 0.28),
        ChartDataPoint(timestamp: Date(), value: 0.42)
    ]
    
    VStack(spacing: 16) {
        CompositeChartView(
            data: sampleData,
            configuration: ChartConfiguration(chartType: .line),
            metric: .cost
        )
        
        CompositeChartView(
            data: sampleData,
            configuration: ChartConfiguration(chartType: .bar),
            metric: .burnRate
        )
        
        HStack {
            SparklineChartView(data: sampleData, metric: .cost)
            GaugeChartView(value: 75, maxValue: 100, metric: .tokenLimit, color: .red)
        }
    }
    .padding()
    .background(Color(NSColor.controlBackgroundColor))
}