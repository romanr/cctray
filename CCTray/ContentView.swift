//
//  ContentView.swift
//  CCTray
//
//  Created by Robert Goniszewski on 11/07/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var usageMonitor: UsageMonitor
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with refresh button
            HStack {
                Text("CCTray")
                    .font(.headline)
                Spacer()
                Button(action: {
                    usageMonitor.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(usageMonitor.isLoading)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Usage information
            VStack(alignment: .leading, spacing: 4) {
                UsageInfoView(info: usageMonitor.getDetailedInfo())
            }
            
            Divider()
            
            // Menu actions
            VStack(alignment: .leading, spacing: 0) {
                SettingsLink {
                    Text("Preferences...")
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 4)
                
                Button("Quit CCTray") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .frame(width: 280)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct UsageInfoView: View {
    let info: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<info.count, id: \.self) { index in
                InfoRowView(text: info[index])
            }
        }
    }
}

struct InfoRowView: View {
    let text: String
    
    var body: some View {
        if text.isEmpty {
            Divider()
                .padding(.vertical, 2)
        } else {
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UsageMonitor())
        .environmentObject(AppPreferences())
}
