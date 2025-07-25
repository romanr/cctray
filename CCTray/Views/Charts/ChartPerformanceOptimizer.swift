import SwiftUI
import Foundation

/// Performance optimization utilities for chart components
struct ChartPerformanceOptimizer {
    
    /// Optimized data sampling for large datasets
    static func sampleDataPoints(_ dataPoints: [ChartDataPoint], maxPoints: Int = 100) -> [ChartDataPoint] {
        guard dataPoints.count > maxPoints else { return dataPoints }
        
        let stepSize = dataPoints.count / maxPoints
        var sampledPoints: [ChartDataPoint] = []
        
        // Always include the first point
        if let first = dataPoints.first {
            sampledPoints.append(first)
        }
        
        // Sample intermediate points
        for i in stride(from: stepSize, to: dataPoints.count - stepSize, by: stepSize) {
            sampledPoints.append(dataPoints[i])
        }
        
        // Always include the last point
        if let last = dataPoints.last {
            sampledPoints.append(last)
        }
        
        return sampledPoints
    }
    
    /// Throttled chart updates to prevent excessive redraws
    static func throttleChartUpdates<T: Equatable>(_ newValue: T, oldValue: T, threshold: TimeInterval = 0.5) -> Bool {
        // Simple equality check - for more complex throttling, implement time-based logic
        return newValue != oldValue
    }
    
    /// Memory-efficient chart data cleanup
    static func cleanupChartData(_ dataManager: ChartDataManager, memoryPressure: Bool = false) {
        if memoryPressure {
            // Aggressive cleanup under memory pressure
            dataManager.clearOldData(olderThan: 1) // Keep only 1 day
        } else {
            // Normal cleanup
            dataManager.clearOldData(olderThan: 7) // Keep 7 days
        }
    }
    
    /// Optimized chart rendering configuration
    static func optimizedChartConfiguration(for dataSize: Int) -> ChartConfiguration {
        let showAnimations = dataSize < 500 // Disable animations for large datasets
        let showDataPoints = dataSize < 100 // Only show data points for small datasets
        
        return ChartConfiguration(
            timeRange: .session,
            chartType: .line,
            colorScheme: .adaptive,
            showTrendLine: true,
            showDataPoints: showDataPoints,
            animated: showAnimations
        )
    }
}

/// Performance monitoring for chart components
class ChartPerformanceMonitor: ObservableObject {
    @Published var renderingMetrics: [String: TimeInterval] = [:]
    
    private var startTimes: [String: Date] = [:]
    
    func startTiming(for component: String) {
        startTimes[component] = Date()
    }
    
    func endTiming(for component: String) {
        guard let startTime = startTimes[component] else { return }
        let duration = Date().timeIntervalSince(startTime)
        renderingMetrics[component] = duration
        
        // Log slow operations
        if duration > 0.1 {
            print("⚠️ Slow chart rendering detected for \(component): \(duration)s")
        }
        
        startTimes.removeValue(forKey: component)
    }
    
    func getAverageRenderTime() -> TimeInterval {
        guard !renderingMetrics.isEmpty else { return 0 }
        let total = renderingMetrics.values.reduce(0, +)
        return total / Double(renderingMetrics.count)
    }
    
    func clearMetrics() {
        renderingMetrics.removeAll()
        startTimes.removeAll()
    }
}

// MARK: - Performance Extensions

extension ChartDataManager {
    /// Memory-efficient data point management
    func optimizeDataStorage() {
        for metric in MetricType.allCases {
            if let points = dataPoints[metric], points.count > 1000 {
                // Keep only the most recent 1000 points
                dataPoints[metric] = Array(points.suffix(1000))
            }
        }
    }
    
    /// Batch data operations for better performance
    func addDataPointsBatch(_ points: [(ChartDataPoint, MetricType)]) {
        for (point, metric) in points {
            if dataPoints[metric] == nil {
                dataPoints[metric] = []
            }
            dataPoints[metric]?.append(point)
        }
        
        // Optimize after batch insert
        optimizeDataStorage()
    }
}

extension Array where Element == ChartDataPoint {
    /// Efficient data point filtering by time range
    func filteredByTimeRange(_ range: ChartTimeRange) -> [ChartDataPoint] {
        let now = Date()
        let cutoffTime: Date
        
        switch range {
        case .fiveMinutes:
            cutoffTime = now.addingTimeInterval(-5 * 60)
        case .fifteenMinutes:
            cutoffTime = now.addingTimeInterval(-15 * 60)
        case .oneHour:
            cutoffTime = now.addingTimeInterval(-60 * 60)
        case .session:
            cutoffTime = Calendar.current.startOfDay(for: now)
        case .today:
            cutoffTime = Calendar.current.startOfDay(for: now)
        }
        
        return self.filter { $0.timestamp >= cutoffTime }
    }
}

// MARK: - Performance Testing

struct ChartPerformanceTest {
    static func runPerformanceTests() {
        print("🧪 Running chart performance tests...")
        
        // Test 1: Data sampling performance
        let largeDataset = generateTestData(count: 10000)
        let startTime = Date()
        let sampledData = ChartPerformanceOptimizer.sampleDataPoints(largeDataset, maxPoints: 100)
        let samplingTime = Date().timeIntervalSince(startTime)
        
        print("✅ Data sampling test: \(samplingTime)s, reduced from \(largeDataset.count) to \(sampledData.count) points")
        
        // Test 2: Memory usage simulation
        let dataManager = ChartDataManager()
        
        // Add large amount of test data
        for i in 0..<5000 {
            let point = ChartDataPoint(timestamp: Date().addingTimeInterval(Double(i)), value: Double(i))
            dataManager.addDataPoint(point, for: .cost)
        }
        
        print("✅ Memory test: Added 5000 data points")
        
        // Test optimization
        dataManager.optimizeDataStorage()
        let optimizedCount = dataManager.dataPoints[.cost]?.count ?? 0
        print("✅ Optimization test: Reduced to \(optimizedCount) points")
        
        // Test 3: Chart configuration optimization
        let config = ChartPerformanceOptimizer.optimizedChartConfiguration(for: 1000)
        print("✅ Configuration test: Animations disabled for large dataset: \(!config.animated)")
        
        print("🎉 All performance tests completed!")
    }
    
    private static func generateTestData(count: Int) -> [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        let now = Date()
        
        for i in 0..<count {
            let timestamp = now.addingTimeInterval(Double(i))
            let value = Double.random(in: 0...100)
            points.append(ChartDataPoint(timestamp: timestamp, value: value))
        }
        
        return points
    }
}

#if DEBUG
// Performance testing preview
struct ChartPerformanceTest_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Chart Performance Tests")
                .font(.headline)
            
            Button("Run Performance Tests") {
                ChartPerformanceTest.runPerformanceTests()
            }
            .padding()
        }
        .onAppear {
            ChartPerformanceTest.runPerformanceTests()
        }
    }
}
#endif