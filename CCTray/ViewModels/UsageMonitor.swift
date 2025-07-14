import Foundation
import SwiftUI

@MainActor
class UsageMonitor: ObservableObject {
    @Published var currentBlock: Block?
    @Published var displayState: DisplayMode = .cost
    @Published var isLoading = false
    @Published var error: String?
    @Published var isActive = false
    
    // Error recovery state
    private var consecutiveErrors = 0
    private var backoffDelay: TimeInterval = 1.0
    private let maxBackoffDelay: TimeInterval = 60.0
    
    private let commandExecutor = CommandExecutor()
    private var updateTimer: Timer?
    private var rotationTimer: Timer?
    private var displayModeIndex = 0
    
    private var preferences: AppPreferences?
    
    func configure(with preferences: AppPreferences) {
        self.preferences = preferences
        startMonitoring()
    }
    
    func startMonitoring() {
        guard let preferences = preferences else { return }
        
        stopMonitoring()
        
        // Start update timer - only if no errors or using backoff
        updateTimer = Timer.scheduledTimer(withTimeInterval: preferences.updateInterval, repeats: true) { _ in
            // Skip update if we're in backoff mode (consecutive errors > 1)
            guard self.consecutiveErrors <= 1 else {
                print("Skipping update due to error backoff (errors: \(self.consecutiveErrors))")
                return
            }
            
            Task {
                await self.updateUsageData()
            }
        }
        
        // Start rotation timer (only rotates display, doesn't affect data fetching)
        rotationTimer = Timer.scheduledTimer(withTimeInterval: preferences.rotationInterval, repeats: true) { _ in
            Task { @MainActor in
                self.rotateDisplayState()
            }
        }
        
        // Initial update
        Task {
            await updateUsageData()
        }
        
        isActive = true
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        rotationTimer?.invalidate()
        rotationTimer = nil
        isActive = false
        
        // Reset error recovery state when stopping
        consecutiveErrors = 0
        backoffDelay = 1.0
    }
    
    private func updateUsageData() async {
        guard let preferences = preferences else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await commandExecutor.getCCUsageData(commandPath: preferences.ccusageCommandPath, scriptPath: preferences.ccusageScriptPath)
            currentBlock = response.blocks.first(where: { $0.isActive })
            
            // Reset error recovery state on success
            consecutiveErrors = 0
            backoffDelay = 1.0
            error = nil
            
        } catch {
            consecutiveErrors += 1
            self.error = error.localizedDescription
            print("Error fetching usage data: \(error)")
            
            // Implement exponential backoff
            if consecutiveErrors > 1 {
                backoffDelay = min(backoffDelay * 2, maxBackoffDelay)
                print("Consecutive errors: \(consecutiveErrors), next backoff delay: \(backoffDelay)s")
                
                // Schedule delayed retry instead of immediate next update
                DispatchQueue.main.asyncAfter(deadline: .now() + backoffDelay) {
                    // Only retry if still active and have preferences
                    if self.isActive && self.preferences != nil {
                        Task {
                            await self.updateUsageData()
                        }
                    }
                }
                return // Skip normal timer cycle
            }
        }
        
        isLoading = false
    }
    
    private func rotateDisplayState() {
        guard let preferences = preferences else { return }
        
        let enabledModes = preferences.enabledDisplayModes
        guard !enabledModes.isEmpty else { return }
        
        displayModeIndex = (displayModeIndex + 1) % enabledModes.count
        displayState = enabledModes[displayModeIndex]
    }
    
    func getCurrentTitle() -> AttributedString {
        print("getCurrentTitle called - isLoading: \(isLoading), error: \(error ?? "none"), currentBlock: \(currentBlock?.id ?? "none")")
        
        guard let block = currentBlock else {
            if error != nil {
                return createStyledFallback(" ❌")
            } else if isLoading {
                return createStyledFallback(" ...")
            } else {
                return createStyledFallback(" 💤")
            }
        }
        
        guard let preferences = preferences else {
            return createStyledFallback(" $\(String(format: "%.2f", block.costUSD))")
        }
        
        switch displayState {
        case .cost:
            return block.formatCostTitle()
        case .burnRate:
            return block.formatBurnRateTitle(preferences: preferences)
        case .remainingTime:
            return block.formatRemainingTimeTitle()
        }
    }
    
    func getDetailedInfo() -> [String] {
        guard let block = currentBlock else {
            if let error = error {
                return ["❌ Error: \(error)"]
            } else if isLoading {
                return ["⏳ Loading..."]
            } else {
                return ["💤 No active session"]
            }
        }
        
        return block.formatDetailedInfo()
    }
    
    func refreshData() {
        Task {
            await updateUsageData()
        }
    }
    
    private func createStyledFallback(_ text: String) -> AttributedString {
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
    
    // Cleanup is handled by stopMonitoring() call when needed
}