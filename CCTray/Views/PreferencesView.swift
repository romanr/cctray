import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        TabView {
            GeneralPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
            
            DisplayPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "eye")
                    Text("Display")
                }
            
            AdvancedPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "terminal")
                    Text("Advanced")
                }
            
            AboutPreferencesView()
                .environmentObject(preferences)
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("About")
                }
        }
        .frame(width: 500, height: 500)
    }
}

struct GeneralPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        Form {
            Section("Update Settings") {
                HStack {
                    Text("Update Interval:")
                    Spacer()
                    Slider(value: $preferences.updateInterval, in: 1...30, step: 1) {
                        Text("Update Interval")
                    }
                    Text("\(Int(preferences.updateInterval))s")
                        .frame(width: 30, alignment: .trailing)
                }
            }
            
            Section("Display Components") {
                Toggle("Show Cost", isOn: $preferences.showCost)
                Toggle("Show Burn Rate", isOn: $preferences.showBurnRate)
                Toggle("Show Remaining Time", isOn: $preferences.showRemainingTime)
            }
            
            Section("Startup") {
                Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
            }
        }
        .padding()
    }
}

struct DisplayPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        Form {
            Section("Cost Display") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decimal Places:")
                    
                    Picker("Decimal Places", selection: $preferences.costDecimalPlaces) {
                        Text("0").tag(0)
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("3").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section("Burn Rate Thresholds") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Low Threshold:")
                        TextField("Low", value: $preferences.lowBurnRateThreshold, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("tokens/min")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("High Threshold:")
                        TextField("High", value: $preferences.highBurnRateThreshold, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("tokens/min")
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("🟢 LOW: < \(Int(preferences.lowBurnRateThreshold)) tokens/min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("🟡 MED: \(Int(preferences.lowBurnRateThreshold))-\(Int(preferences.highBurnRateThreshold)) tokens/min")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("🔴 HIGH: > \(Int(preferences.highBurnRateThreshold)) tokens/min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Display Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rotation Speed:")
                        Spacer()
                        Text("\(Int(preferences.rotationInterval))s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $preferences.rotationInterval, in: 1...30, step: 1) {
                        Text("Rotation Interval")
                    }
                }
            }
        }
        .padding()
    }
}

struct AdvancedPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        Form {
            Section("Node.js Configuration") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Node.js Command:")
                        
                        TextField("node command or full path", text: $preferences.ccusageCommandPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Use 'node' to auto-detect, or provide full path. Default works with Homebrew, nvm, and system installations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ccusage Script:")
                        
                        TextField("Path to ccusage script", text: $preferences.ccusageScriptPath)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Full path to the ccusage script. Default works with nvm installations.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Reset") {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func resetToDefaults() {
        preferences.updateInterval = 5.0
        preferences.rotationInterval = 5.0
        preferences.showCost = true
        preferences.showBurnRate = true
        preferences.showRemainingTime = true
        preferences.lowBurnRateThreshold = 300.0
        preferences.highBurnRateThreshold = 700.0
        preferences.costDecimalPlaces = 2
        preferences.ccusageCommandPath = "node"
        preferences.ccusageScriptPath = "/Users/goniszewski/.nvm/versions/node/v20.11.0/lib/node_modules/ccusage/dist/index.js"
        preferences.launchAtLogin = false
    }
}

struct AboutPreferencesView: View {
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        Form {
            Section("App Information") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version:")
                            .frame(width: 80, alignment: .leading)
                        Text(appVersion)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Author:")
                            .frame(width: 80, alignment: .leading)
                        Text("Robert Goniszewski")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            
        }
        .padding()
    }
    
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

// Preview removed for Swift Package compatibility