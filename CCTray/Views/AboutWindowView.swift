//
//  AboutWindowView.swift
//  CCTray
//
//  Created by Robert Goniszewski on 14/07/2025.
//

import SwiftUI

struct AboutWindowView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(systemName: "c.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // App Name and Version
            VStack(spacing: 4) {
                Text("CCTray")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text("macOS menu bar app for Claude Code usage monitoring")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
            
            // Author and Repository
            VStack(spacing: 12) {
                HStack {
                    Text("Author:")
                        .fontWeight(.medium)
                    Button(GitInfo.authorHandle) {
                        if let url = URL(string: "https://github.com/goniszewski") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                
                HStack {
                    Text("Repository:")
                        .fontWeight(.medium)
                    Button(GitInfo.repositoryDisplayURL) {
                        if let url = URL(string: GitInfo.repositoryURL) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                
                VStack(spacing: 4) {
                    Text("Latest Commit:")
                        .fontWeight(.medium)
                    Text(GitInfo.shortCommitHash)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text(GitInfo.formattedCommitDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .padding(.horizontal)
            
            // Copyright
            Text(appCopyright)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var appCopyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? "© 2025 Robert Goniszewski"
    }
}

#Preview {
    AboutWindowView()
}
