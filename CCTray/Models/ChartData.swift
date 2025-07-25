import Foundation
import SwiftUI

// MARK: - Chart Data Models

/// Represents a single data point for charting
struct ChartDataPoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let category: String
    
    init(timestamp: Date, value: Double, category: String = "default") {
        self.id = UUID()
        self.timestamp = timestamp
        self.value = value
        self.category = category
    }
}

/// Configuration for chart display
struct ChartConfiguration {
    let timeRange: ChartTimeRange
    let chartType: ChartType
    let colorScheme: ChartColorScheme
    let showTrendLine: Bool
    let showDataPoints: Bool
    let animated: Bool
    
    init(timeRange: ChartTimeRange = .session,
         chartType: ChartType = .line,
         colorScheme: ChartColorScheme = .adaptive,
         showTrendLine: Bool = true,
         showDataPoints: Bool = false,
         animated: Bool = true) {
        self.timeRange = timeRange
        self.chartType = chartType
        self.colorScheme = colorScheme
        self.showTrendLine = showTrendLine
        self.showDataPoints = showDataPoints
        self.animated = animated
    }
}

/// Time range options for charts
enum ChartTimeRange: String, CaseIterable, Identifiable {
    case fiveMinutes = "5m"
    case fifteenMinutes = "15m"
    case oneHour = "1h"
    case session = "session"
    case today = "today"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fiveMinutes: return "5 Minutes"
        case .fifteenMinutes: return "15 Minutes"
        case .oneHour: return "1 Hour"
        case .session: return "Session"
        case .today: return "Today"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .fiveMinutes: return 5 * 60
        case .fifteenMinutes: return 15 * 60
        case .oneHour: return 60 * 60
        case .session: return 0 // Dynamic based on session
        case .today: return 24 * 60 * 60
        }
    }
}

/// Chart type options
enum ChartType: String, CaseIterable, Identifiable {
    case line = "line"
    case bar = "bar"
    case area = "area"
    case sparkline = "sparkline"
    case gauge = "gauge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .line: return "Line"
        case .bar: return "Bar"
        case .area: return "Area"
        case .sparkline: return "Sparkline"
        case .gauge: return "Gauge"
        }
    }
}

/// Color scheme options for charts
enum ChartColorScheme: String, CaseIterable, Identifiable {
    case adaptive = "adaptive"
    case light = "light"
    case dark = "dark"
    case accent = "accent"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .adaptive: return "Adaptive"
        case .light: return "Light"
        case .dark: return "Dark"
        case .accent: return "Accent"
        }
    }
}

/// Trend direction for indicators
enum TrendDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    case unknown = "unknown"
    
    var symbol: String {
        switch self {
        case .up: return "↗️"
        case .down: return "↘️"
        case .stable: return "↔️"
        case .unknown: return "•"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .red
        case .down: return .green
        case .stable: return .blue
        case .unknown: return .gray
        }
    }
}

/// Metric type for charting
enum MetricType: String, CaseIterable, Identifiable {
    case cost = "cost"
    case burnRate = "burnRate"
    case tokenUsage = "tokenUsage"
    case apiCalls = "apiCalls"
    case projectedCost = "projectedCost"
    case tokenLimit = "tokenLimit"
    case remainingTime = "remainingTime"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cost: return "Cost"
        case .burnRate: return "Burn Rate"
        case .tokenUsage: return "Token Usage"
        case .apiCalls: return "API Calls"
        case .projectedCost: return "Projected Cost"
        case .tokenLimit: return "Token Limit"
        case .remainingTime: return "Remaining Time"
        }
    }
    
    var unit: String {
        switch self {
        case .cost, .projectedCost: return "USD"
        case .burnRate: return "$/hr"
        case .tokenUsage: return "tokens"
        case .apiCalls: return "calls"
        case .tokenLimit: return "%"
        case .remainingTime: return "time"
        }
    }
    
    var formatValue: (Double) -> String {
        switch self {
        case .cost, .projectedCost:
            return { String(format: "$%.2f", $0) }
        case .burnRate:
            return { String(format: "$%.2f/hr", $0) }
        case .tokenUsage:
            return { String(format: "%.0f", $0) }
        case .apiCalls:
            return { String(format: "%.0f", $0) }
        case .tokenLimit:
            return { String(format: "%.1f%%", $0) }
        case .remainingTime:
            return { minutes in
                if minutes >= 60 {
                    let hours = Int(minutes / 60)
                    let remainingMinutes = Int(minutes.truncatingRemainder(dividingBy: 60))
                    return "\(hours)h \(remainingMinutes)m"
                } else {
                    return "\(Int(minutes))m"
                }
            }
        }
    }
}

// MARK: - Historical Data Storage

/// Manages historical data for charting
class ChartDataManager: ObservableObject {
    @Published var dataPoints: [MetricType: [ChartDataPoint]] = [:]
    
    private let maxDataPoints = 1000
    private let saveInterval: TimeInterval = 30 // Save every 30 seconds
    private var saveTimer: Timer?
    
    init() {
        loadHistoricalData()
        startSaveTimer()
    }
    
    deinit {
        saveTimer?.invalidate()
        saveHistoricalData()
    }
    
    /// Add a new data point
    func addDataPoint(_ point: ChartDataPoint, for metric: MetricType) {
        DispatchQueue.main.async {
            if self.dataPoints[metric] == nil {
                self.dataPoints[metric] = []
            }
            
            self.dataPoints[metric]?.append(point)
            
            // Keep only recent data points
            if let count = self.dataPoints[metric]?.count, count > self.maxDataPoints {
                self.dataPoints[metric]?.removeFirst(count - self.maxDataPoints)
            }
        }
    }
    
    /// Get data points for a specific metric and time range
    func getDataPoints(for metric: MetricType, in timeRange: ChartTimeRange) -> [ChartDataPoint] {
        guard let points = dataPoints[metric] else { return [] }
        
        let now = Date()
        let cutoffTime: Date
        
        switch timeRange {
        case .session:
            // For session, return all points from today
            cutoffTime = Calendar.current.startOfDay(for: now)
        case .today:
            cutoffTime = Calendar.current.startOfDay(for: now)
        default:
            cutoffTime = now.addingTimeInterval(-timeRange.duration)
        }
        
        return points.filter { $0.timestamp >= cutoffTime }
    }
    
    /// Calculate trend direction for a metric
    func getTrendDirection(for metric: MetricType, in timeRange: ChartTimeRange) -> TrendDirection {
        let points = getDataPoints(for: metric, in: timeRange)
        guard points.count >= 2 else { return .unknown }
        
        let recentPoints = points.suffix(5) // Use last 5 points for trend
        let values = recentPoints.map { $0.value }
        
        guard values.count >= 2 else { return .unknown }
        
        let first = values.first!
        let last = values.last!
        let change = (last - first) / first
        
        if change > 0.05 { // 5% increase
            return .up
        } else if change < -0.05 { // 5% decrease
            return .down
        } else {
            return .stable
        }
    }
    
    /// Get latest value for a metric
    func getLatestValue(for metric: MetricType) -> Double? {
        return dataPoints[metric]?.last?.value
    }
    
    /// Clear all data
    func clearAllData() {
        dataPoints.removeAll()
        saveHistoricalData()
    }
    
    /// Clear data older than specified days
    func clearOldData(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        for metric in MetricType.allCases {
            if let points = dataPoints[metric] {
                dataPoints[metric] = points.filter { $0.timestamp >= cutoffDate }
            }
        }
        
        saveHistoricalData()
    }
    
    // MARK: - Persistence
    
    private func startSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { _ in
            self.saveHistoricalData()
        }
    }
    
    private func saveHistoricalData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        for metric in MetricType.allCases {
            if let points = dataPoints[metric], !points.isEmpty {
                do {
                    let data = try encoder.encode(points)
                    UserDefaults.standard.set(data, forKey: "chartData_\(metric.rawValue)")
                } catch {
                    print("Failed to save chart data for \(metric.rawValue): \(error)")
                }
            }
        }
    }
    
    private func loadHistoricalData() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for metric in MetricType.allCases {
            if let data = UserDefaults.standard.data(forKey: "chartData_\(metric.rawValue)") {
                do {
                    let points = try decoder.decode([ChartDataPoint].self, from: data)
                    dataPoints[metric] = points
                } catch {
                    print("Failed to load chart data for \(metric.rawValue): \(error)")
                }
            }
        }
    }
}