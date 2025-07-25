import Foundation

struct CCUsageResponse: Codable {
    let blocks: [Block]
    
    // MARK: - Plan-Specific Data Interpretation
    
    var activeBlock: Block? {
        blocks.first { $0.isActive }
    }
    
    func getCostContext(for plan: ClaudePlan) -> CostContext {
        guard let activeBlock = activeBlock else {
            return CostContext(displayCost: 0.0, contextMessage: "No active session")
        }
        
        switch plan {
        case .pro, .max5x, .max20x:
            return CostContext(
                displayCost: activeBlock.costUSD,
                contextMessage: "This session would cost $\(String(format: "%.2f", activeBlock.costUSD)) on API pricing"
            )
        case .apiBased:
            return CostContext(
                displayCost: activeBlock.costUSD,
                contextMessage: "API Usage • $\(String(format: "%.2f", activeBlock.costUSD)) charged"
            )
        case .custom:
            return CostContext(
                displayCost: activeBlock.costUSD,
                contextMessage: "Session cost: $\(String(format: "%.2f", activeBlock.costUSD))"
            )
        }
    }
    
    func getBurnRateContext(for plan: ClaudePlan) -> BurnRateContext {
        guard let activeBlock = activeBlock else {
            return BurnRateContext(tokensPerMinute: 0.0, costPerHour: 0.0, contextMessage: "No active session")
        }
        
        let burnRate = activeBlock.burnRate
        let level = getBurnRateLevel(burnRate.tokensPerMinute, for: plan)
        
        switch plan {
        case .pro, .max5x, .max20x:
            return BurnRateContext(
                tokensPerMinute: burnRate.tokensPerMinute,
                costPerHour: burnRate.costPerHour,
                contextMessage: "\(level.displayName) usage • \(plan.title) included"
            )
        case .apiBased:
            return BurnRateContext(
                tokensPerMinute: burnRate.tokensPerMinute,
                costPerHour: burnRate.costPerHour,
                contextMessage: "\(level.displayName) • $\(String(format: "%.2f", burnRate.costPerHour))/hour"
            )
        case .custom:
            return BurnRateContext(
                tokensPerMinute: burnRate.tokensPerMinute,
                costPerHour: burnRate.costPerHour,
                contextMessage: "\(level.displayName) • \(Int(burnRate.tokensPerMinute)) tokens/min"
            )
        }
    }
    
    func getProjectionContext(for plan: ClaudePlan) -> ProjectionContext {
        guard let activeBlock = activeBlock else {
            return ProjectionContext(totalCost: 0.0, remainingMinutes: 0, contextMessage: "No active session")
        }
        
        let projection = activeBlock.projection
        
        switch plan {
        case .pro, .max5x, .max20x:
            return ProjectionContext(
                totalCost: projection.totalCost,
                remainingMinutes: projection.remainingMinutes,
                contextMessage: "Session value: $\(String(format: "%.2f", projection.totalCost)) • Included in plan"
            )
        case .apiBased:
            return ProjectionContext(
                totalCost: projection.totalCost,
                remainingMinutes: projection.remainingMinutes,
                contextMessage: "Projected total: $\(String(format: "%.2f", projection.totalCost))"
            )
        case .custom:
            return ProjectionContext(
                totalCost: projection.totalCost,
                remainingMinutes: projection.remainingMinutes,
                contextMessage: "Est. total: $\(String(format: "%.2f", projection.totalCost))"
            )
        }
    }
    
    private func getBurnRateLevel(_ tokensPerMinute: Double, for plan: ClaudePlan) -> BurnRateLevel {
        let lowThreshold = plan.defaultLowThreshold
        let highThreshold = plan.defaultHighThreshold
        
        if tokensPerMinute < lowThreshold {
            return .low
        } else if tokensPerMinute < highThreshold {
            return .medium
        } else {
            return .high
        }
    }
}

struct Block: Codable {
    let id: String
    let startTime: String
    let endTime: String
    let actualEndTime: String
    let isActive: Bool
    let isGap: Bool
    let entries: Int
    let tokenCounts: TokenCounts
    let totalTokens: Int
    let costUSD: Double
    let models: [String]
    let burnRate: BurnRate
    let projection: Projection
    let tokenLimitStatus: TokenLimitStatus?
}

struct TokenCounts: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int
    let cacheReadInputTokens: Int
}

struct BurnRate: Codable {
    let tokensPerMinute: Double
    let costPerHour: Double
}

struct Projection: Codable {
    let totalTokens: Int
    let totalCost: Double
    let remainingMinutes: Int
}

struct TokenLimitStatus: Codable {
    let limit: Int
    let projectedUsage: Int
    let percentUsed: Double
    let status: String
}

// MARK: - Plan-Specific Context Types

struct CostContext {
    let displayCost: Double
    let contextMessage: String
}

struct BurnRateContext {
    let tokensPerMinute: Double
    let costPerHour: Double
    let contextMessage: String
}

struct ProjectionContext {
    let totalCost: Double
    let remainingMinutes: Int
    let contextMessage: String
}

