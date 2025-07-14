import Foundation
import SwiftUI

class AppPreferences: ObservableObject {
    // Update intervals
    @AppStorage("updateInterval") var updateInterval: Double = 5.0
    @AppStorage("rotationInterval") var rotationInterval: Double = 5.0
    
    // Display toggles
    @AppStorage("showCost") var showCost: Bool = true
    @AppStorage("showBurnRate") var showBurnRate: Bool = true
    @AppStorage("showRemainingTime") var showRemainingTime: Bool = true
    
    // Burn rate thresholds
    @AppStorage("lowBurnRateThreshold") var lowBurnRateThreshold: Double = 300.0
    @AppStorage("highBurnRateThreshold") var highBurnRateThreshold: Double = 700.0
    
    // Display format
    @AppStorage("costDecimalPlaces") var costDecimalPlaces: Int = 2
    
    // Command path
    @AppStorage("ccusageCommandPath") var ccusageCommandPath: String = "node"
    @AppStorage("ccusageScriptPath") var ccusageScriptPath: String = "/Users/goniszewski/.nvm/versions/node/v20.11.0/lib/node_modules/ccusage/dist/index.js"
    
    // Launch at login
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    
    // Computed properties
    var enabledDisplayModes: [DisplayMode] {
        var modes: [DisplayMode] = []
        if showCost { modes.append(.cost) }
        if showBurnRate { modes.append(.burnRate) }
        if showRemainingTime { modes.append(.remainingTime) }
        return modes.isEmpty ? [.cost] : modes // Always show at least cost
    }
}

enum DisplayMode: Int, CaseIterable {
    case cost = 0
    case burnRate = 1
    case remainingTime = 2
    
    var title: String {
        switch self {
        case .cost:
            return "Cost"
        case .burnRate:
            return "Burn Rate"
        case .remainingTime:
            return "Remaining Time"
        }
    }
}