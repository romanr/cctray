import Foundation

actor CommandExecutor {
    // Cache for resolved executable paths
    private var executablePathCache: [String: String] = [:]
    
    enum CommandError: Error, LocalizedError {
        case commandNotFound(String)
        case executionFailed(Int)
        case permissionDenied(String)
        case noOutput
        case timeout
        
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
            }
        }
    }
    
    private func resolveExecutablePath(_ command: String) async throws -> (path: String, wasCached: Bool) {
        // For simple command names like "node", find the actual executable path
        if !command.contains("/") {
            // Check cache first
            if let cachedPath = executablePathCache[command] {
                return (cachedPath, true)
            } else {
                guard let foundPath = findExecutableInPath(command) else {
                    throw CommandError.commandNotFound(command)
                }
                // Cache the resolved path
                executablePathCache[command] = foundPath
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
        }
    }
    
    func executeCommand(_ command: String, args: [String], timeout: TimeInterval = 30.0) async throws -> Data {
        // Resolve executable path in actor context first
        let (executablePath, wasCached) = try await resolveExecutablePath(command)
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let process = Process()
                
                // Use the resolved executable path directly
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = args
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                // Set up timeout
                let timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                    if process.isRunning {
                        process.terminate()
                        continuation.resume(throwing: CommandError.timeout)
                    }
                }
                
                process.terminationHandler = { process in
                    timeoutTimer.invalidate()
                    
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
                } catch {
                    timeoutTimer.invalidate()
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            // If command failed and it was from cache, invalidate the cache for next time
            if wasCached {
                await invalidateCache(for: command)
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
    
    func getCCUsageData(commandPath: String, scriptPath: String? = nil) async throws -> CCUsageResponse {
        let data: Data
        
        // If scriptPath is provided, execute via Node.js
        if let scriptPath = scriptPath {
            data = try await executeCommand(
                commandPath,  // This should be the node executable path
                args: [scriptPath, "blocks", "--live", "--json", "--active"]
            )
        } else {
            // Standard execution for other commands
            data = try await executeCommand(
                commandPath,
                args: ["blocks", "--live", "--json", "--active"]
            )
        }
        
        do {
            return try JSONDecoder().decode(CCUsageResponse.self, from: data)
        } catch {
            print("JSON Decode Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            throw error
        }
    }
}