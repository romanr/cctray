//
//  CCUsageOutputView.swift
//  CCTray
//
//  Created by Robert Goniszewski on 14/07/2025.
//

import SwiftUI

struct CCUsageOutputView: View {
    @EnvironmentObject var preferences: AppPreferences
    @State private var output: String = "Loading..."
    @State private var isLoading = false
    @State private var error: String?
    
    private let commandExecutor = CommandExecutor()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("ccusage Output")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    Task {
                        await fetchOutput()
                    }
                }
                .disabled(isLoading)
            }
            
            Divider()
            
            // Output content
            ScrollView {
                if let error = error {
                    Text("❌ Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    Text(output)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fetching ccusage output...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            Task {
                await fetchOutput()
            }
        }
    }
    
    private func fetchOutput() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let rawOutput = try await commandExecutor.getRawCCUsageOutput(
                commandPath: preferences.ccusageCommandPath,
                scriptPath: preferences.ccusageScriptPath,
                args: []  // Just run plain ccusage command
            )
            
            await MainActor.run {
                output = rawOutput
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    CCUsageOutputView()
        .environmentObject(AppPreferences())
}