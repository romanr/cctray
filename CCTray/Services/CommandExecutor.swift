import Foundation

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

actor CommandExecutor {
    // Cache for resolved executable paths
    private var executablePathCache: [String: String] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpiryInterval: TimeInterval = 300 // 5 minutes
    private var environmentFingerprint: String?
    
    // Command execution serialization
    private var isExecutingCCUsage = false
    
    // Diagnostic logging
    private var diagnosticMode = false
    private var commandExecutionHistory: [(timestamp: Date, command: String, success: Bool, duration: TimeInterval)] = []
    private let maxHistoryEntries = 100
    
    enum CommandError: Error, LocalizedError {
        case commandNotFound(String)
        case executionFailed(Int)
        case permissionDenied(String)
        case noOutput
        case timeout
        case invalidJSON(String)
        case emptyJSON
        case malformedJSON(String)
        case executionInProgress
        
        var errorDescription: String? {
            switch self {
            case .commandNotFound(let command):
                return "Command not found: \(command). Please ensure Node.js is installed and accessible."
            case .executionFailed(let code):
                switch code {
                case 126:
                    return "Permission denied (exit code 126). Check app permissions and Node.js installation."
                case 127:
                    return "Command not found (exit code 127). Please install Node.js or check the path."
                default:
                    return "Command failed with exit code: \(code)"
                }
            case .permissionDenied(let command):
                return "Permission denied executing: \(command). Check app entitlements and macOS security settings."
            case .noOutput:
                return "No output received from command"
            case .timeout:
                return "Command execution timed out"
            case .invalidJSON(let details):
                return "Invalid JSON response: \(details)"
            case .emptyJSON:
                return "Empty JSON response received"
            case .malformedJSON(let details):
                return "Malformed JSON response: \(details)"
            case .executionInProgress:
                return "Command execution already in progress"
            }
        }
    }
    
    private func resolveExecutablePath(_ command: String) async throws -> (path: String, wasCached: Bool) {
        // Clean up expired cache entries
        invalidateExpiredCache()
        
        // For simple command names like "node", find the actual executable path
        if !command.contains("/") {
            // Check cache first with validation
            if isCacheValid(for: command), let cachedPath = executablePathCache[command] {
                return (cachedPath, true)
            } else {
                guard let foundPath = findExecutableInPath(command) else {
                    throw CommandError.commandNotFound(command)
                }
                // Cache the resolved path with timestamp
                executablePathCache[command] = foundPath
                cacheTimestamps[command] = Date()
                
                // Update environment fingerprint if not set
                if environmentFingerprint == nil {
                    environmentFingerprint = generateEnvironmentFingerprint()
                }
                
                return (foundPath, false)
            }
        } else {
            // For full paths, check if they exist first
            guard FileManager.default.fileExists(atPath: command) else {
                throw CommandError.commandNotFound(command)
            }
            return (command, false)
        }
    }
    
    private func invalidateCache(for command: String) {
        if !command.contains("/") {
            executablePathCache[command] = nil
            cacheTimestamps[command] = nil
        }
    }
    
    private func generateEnvironmentFingerprint() -> String {
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let homeDir = NSHomeDirectory()
        let nodeVersion = ProcessInfo.processInfo.environment["NODE_VERSION"] ?? ""
        let nvmDir = ProcessInfo.processInfo.environment["NVM_DIR"] ?? ""
        
        return "\(pathEnv.hashValue):\(homeDir.hashValue):\(nodeVersion):\(nvmDir)"
    }
    
    private func isCacheValid(for command: String) -> Bool {
        // Check if cache exists
        guard executablePathCache[command] != nil else { return false }
        
        // Check if cache has expired
        if let timestamp = cacheTimestamps[command] {
            let age = Date().timeIntervalSince(timestamp)
            if age > cacheExpiryInterval {
                return false
            }
        } else {
            return false
        }
        
        // Check if environment has changed
        let currentFingerprint = generateEnvironmentFingerprint()
        if environmentFingerprint != currentFingerprint {
            environmentFingerprint = currentFingerprint
            return false
        }
        
        return true
    }
    
    private func invalidateExpiredCache() {
        let now = Date()
        for (command, timestamp) in cacheTimestamps {
            if now.timeIntervalSince(timestamp) > cacheExpiryInterval {
                executablePathCache[command] = nil
                cacheTimestamps[command] = nil
            }
        }
    }
    
    private func invalidateAllCache() {
        executablePathCache.removeAll()
        cacheTimestamps.removeAll()
        environmentFingerprint = nil
    }
    
    // Public function to force cache invalidation (useful for session transitions)
    func forceInvalidateCache() {
        invalidateAllCache()
    }
    
    // Diagnostic logging functions
    func enableDiagnosticMode() {
        diagnosticMode = true
        diagnosticLog("🔍 Diagnostic mode enabled")
    }
    
    func disableDiagnosticMode() {
        diagnosticMode = false
        diagnosticLog("🔍 Diagnostic mode disabled")
    }
    
    private func diagnosticLog(_ message: String) {
        if diagnosticMode {
            let timestamp = DateFormatter.iso8601.string(from: Date())
            print("[DIAGNOSTIC] \(timestamp): \(message)")
        }
    }
    
    private func recordCommandExecution(command: String, success: Bool, duration: TimeInterval) {
        let entry = (timestamp: Date(), command: command, success: success, duration: duration)
        commandExecutionHistory.append(entry)
        
        // Keep only recent entries
        if commandExecutionHistory.count > maxHistoryEntries {
            commandExecutionHistory.removeFirst()
        }
        
        if diagnosticMode {
            let status = success ? "✅" : "❌"
            diagnosticLog("\(status) Command: \(command), Duration: \(String(format: "%.2f", duration))s")
        }
    }
    
    func getCommandExecutionHistory() -> [(timestamp: Date, command: String, success: Bool, duration: TimeInterval)] {
        return commandExecutionHistory
    }
    
    
    func executeCommand(_ command: String, args: [String], timeout: TimeInterval = 30.0) async throws -> Data {
        // Resolve executable path in actor context first
        let (executablePath, wasCached) = try await resolveExecutablePath(command)
        
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    let process = Process()
                    
                    // Use the resolved executable path directly
                    process.executableURL = URL(fileURLWithPath: executablePath)
                    process.arguments = args
                    
                    let outputPipe = Pipe()
                    let errorPipe = Pipe()
                    process.standardOutput = outputPipe
                    process.standardError = errorPipe
                    
                    process.terminationHandler = { process in
                        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        
                        if process.terminationStatus == 0 {
                            if outputData.isEmpty {
                                continuation.resume(throwing: CommandError.noOutput)
                            } else {
                                continuation.resume(returning: outputData)
                            }
                        } else {
                            if !errorData.isEmpty {
                                let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                                print("Command error: \(errorString)")
                                
                                // Check for specific permission errors
                                if errorString.contains("Operation not permitted") || process.terminationStatus == 126 {
                                    continuation.resume(throwing: CommandError.permissionDenied(executablePath))
                                    return
                                }
                            }
                            continuation.resume(throwing: CommandError.executionFailed(Int(process.terminationStatus)))
                        }
                    }
                    
                    do {
                        try process.run()
                        
                        // Start timeout task
                        Task {
                            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                            if process.isRunning {
                                process.terminate()
                                continuation.resume(throwing: CommandError.timeout)
                            }
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            } onCancel: {
                // This will be called if the task is cancelled
            }
        } catch {
            // If command failed and it was from cache, invalidate the cache for next time
            if wasCached {
                invalidateCache(for: command)
            }
            throw error
        }
    }
    
    private func findExecutableInPath(_ command: String) -> String? {
        // Common paths where Node.js might be installed
        let searchPaths = [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "\(NSHomeDirectory())/.nvm/versions/node/v22.11.0/bin",
            "\(NSHomeDirectory())/.nvm/versions/node/v20.11.0/bin",
            "\(NSHomeDirectory())/.nvm/versions/node/v18.20.4/bin",
            "/Users/\(NSUserName())/.nvm/current/bin",
            "/System/Library/Frameworks/Node.framework/Versions/Current/bin"
        ]
        
        // Also check current PATH environment variable
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            let pathComponents = pathEnv.split(separator: ":").map(String.init)
            
            // Search through all paths (predefined + PATH environment)
            for path in searchPaths + pathComponents {
                let executablePath = "\(path)/\(command)"
                if FileManager.default.isExecutableFile(atPath: executablePath) {
                    return executablePath
                }
            }
        } else {
            // Fallback to predefined paths only
            for path in searchPaths {
                let executablePath = "\(path)/\(command)"
                if FileManager.default.isExecutableFile(atPath: executablePath) {
                    return executablePath
                }
            }
        }
        
        return nil
    }
    
    private func validateJSON(data: Data) throws -> Data {
        // Check if data is empty
        guard !data.isEmpty else {
            throw CommandError.emptyJSON
        }
        
        // Convert to string for validation
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw CommandError.invalidJSON("Unable to convert data to string")
        }
        
        // Check for common malformed JSON patterns
        let trimmedString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if completely empty after trimming
        if trimmedString.isEmpty {
            throw CommandError.emptyJSON
        }
        
        // Check if it looks like JSON (starts with { or [)
        if !trimmedString.hasPrefix("{") && !trimmedString.hasPrefix("[") {
            throw CommandError.malformedJSON("Response doesn't start with valid JSON structure")
        }
        
        // Check if it looks truncated (doesn't end with } or ])
        if !trimmedString.hasSuffix("}") && !trimmedString.hasSuffix("]") {
            throw CommandError.malformedJSON("Response appears to be truncated")
        }
        
        // Try to parse as generic JSON to validate structure
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw CommandError.malformedJSON("JSON structure validation failed: \(error.localizedDescription)")
        }
        
        return data
    }
    
    private func attemptJSONRepair(data: Data) throws -> Data {
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw CommandError.invalidJSON("Unable to convert data to string for repair")
        }
        
        let trimmedString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to repair common JSON issues
        var repairedString = trimmedString
        
        // If it looks like it might be a truncated JSON object, try to close it
        if repairedString.hasPrefix("{") && !repairedString.hasSuffix("}") {
            // Count braces to see if we can balance them
            let openBraces = repairedString.filter { $0 == "{" }.count
            let closeBraces = repairedString.filter { $0 == "}" }.count
            
            if openBraces > closeBraces {
                // Try to close the JSON by adding missing braces
                let missingBraces = openBraces - closeBraces
                repairedString += String(repeating: "}", count: missingBraces)
            }
        }
        
        // Try to parse the repaired JSON
        guard let repairedData = repairedString.data(using: .utf8) else {
            throw CommandError.invalidJSON("Unable to convert repaired string to data")
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: repairedData, options: [])
            print("JSON repair successful")
            return repairedData
        } catch {
            throw CommandError.malformedJSON("JSON repair failed: \(error.localizedDescription)")
        }
    }
    
    func getCCUsageData(commandPath: String, scriptPath: String? = nil, tokenLimitEnabled: Bool = false, tokenLimitValue: String = "0") async throws -> CCUsageResponse {
        let startTime = Date()
        diagnosticLog("🚀 Starting ccusage command execution")
        
        // Prevent concurrent ccusage calls
        if isExecutingCCUsage {
            diagnosticLog("⚠️ Concurrent ccusage execution blocked")
            throw CommandError.executionInProgress
        }
        
        isExecutingCCUsage = true
        defer { isExecutingCCUsage = false }
        
        let data: Data
        
        // Build base arguments
        var args = ["blocks", "--live", "--json", "--active"]
        
        // Add token limit flag if enabled
        if tokenLimitEnabled {
            args.append("--token-limit")
            args.append(tokenLimitValue)
        }
        
        // If scriptPath is provided, execute via Node.js
        if let scriptPath = scriptPath {
            data = try await executeCommand(
                commandPath,  // This should be the node executable path
                args: [scriptPath] + args
            )
        } else {
            // Standard execution for other commands
            data = try await executeCommand(
                commandPath,
                args: args
            )
        }
        
        // Validate JSON structure before attempting to parse
        do {
            diagnosticLog("🔍 Validating JSON structure")
            let validatedData = try validateJSON(data: data)
            diagnosticLog("✅ JSON validation successful")
            
            let response = try JSONDecoder().decode(CCUsageResponse.self, from: validatedData)
            let duration = Date().timeIntervalSince(startTime)
            recordCommandExecution(command: "ccusage", success: true, duration: duration)
            diagnosticLog("✅ CCUsage command completed successfully in \(String(format: "%.2f", duration))s")
            return response
        } catch let error as CommandError {
            let duration = Date().timeIntervalSince(startTime)
            recordCommandExecution(command: "ccusage", success: false, duration: duration)
            
            // Try JSON repair as fallback for malformed JSON
            if case .malformedJSON = error {
                do {
                    diagnosticLog("🔧 Attempting JSON repair...")
                    let repairedData = try attemptJSONRepair(data: data)
                    let response = try JSONDecoder().decode(CCUsageResponse.self, from: repairedData)
                    diagnosticLog("✅ JSON repair successful")
                    return response
                } catch {
                    diagnosticLog("❌ JSON repair failed, falling back to original error")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        diagnosticLog("JSON Validation Error: \(error)")
                        diagnosticLog("Raw JSON: \(jsonString)")
                    }
                    throw error
                }
            } else {
                // Re-throw other validation errors with detailed context
                if let jsonString = String(data: data, encoding: .utf8) {
                    diagnosticLog("JSON Validation Error: \(error)")
                    diagnosticLog("Raw JSON: \(jsonString)")
                }
                throw error
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            recordCommandExecution(command: "ccusage", success: false, duration: duration)
            
            // Handle JSONDecoder errors
            diagnosticLog("❌ JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                diagnosticLog("Raw JSON: \(jsonString)")
                throw CommandError.invalidJSON("Decoding failed: \(error.localizedDescription)")
            }
            throw CommandError.invalidJSON("Decoding failed with unknown error")
        }
    }
    
    func getRawCCUsageOutput(commandPath: String, scriptPath: String? = nil, args: [String] = []) async throws -> String {
        let data: Data
        
        // If scriptPath is provided, execute via Node.js
        if let scriptPath = scriptPath {
            data = try await executeCommand(
                commandPath,  // This should be the node executable path
                args: [scriptPath] + args
            )
        } else {
            // Standard execution for other commands
            data = try await executeCommand(
                commandPath,
                args: args
            )
        }
        
        guard let output = String(data: data, encoding: .utf8) else {
            throw CommandError.noOutput
        }
        
        return output
    }
}