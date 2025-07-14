import Foundation

struct CCUsageResponse: Codable {
    let blocks: [Block]
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