# CCTray

A macOS menu bar application that monitors Claude Code usage in real-time, providing instant visibility into your AI development costs and usage patterns.

## 🚀 Features

- **Real-time Monitoring**: Live tracking of Claude Code usage via the `ccusage` CLI
- **Smart Menu Bar Display**: Rotating display showing cost, burn rate, and remaining session time
- **Customizable Interface**: Orange "C" icon with configurable update and rotation intervals
- **Comprehensive Preferences**: Four-tab settings window (General, Display, Advanced, About)
- **Intelligent Error Handling**: Exponential backoff, automatic Node.js path detection
- **Performance Optimized**: Caching, background execution, and minimal resource usage

## 📱 Screenshots

*Menu bar icon and dropdown coming soon*

*Preferences window screenshots coming soon*

## 🎯 Requirements

- **macOS 13.0+** (macOS Ventura or later)
- **Node.js** (any version with npm)
- **ccusage CLI tool** (`npm install -g ccusage`)

## 📦 Installation

### 1. Install Dependencies

First, ensure you have Node.js and the ccusage CLI tool:

```bash
# Install ccusage globally
npm install -g ccusage

# Verify installation
ccusage --version
```

### 2. Download CCTray

1. Download the latest release from [Releases](https://github.com/goniszewski/cctray/releases)
2. Move `CCTray.app` to your Applications folder
3. Launch CCTray

### 3. Node.js Path Configuration

CCTray automatically detects Node.js installations from:
- **Homebrew**: `/opt/homebrew/bin/node`
- **System**: `/usr/local/bin/node`, `/usr/bin/node`  
- **nvm**: `~/.nvm/versions/node/*/bin/node`
- **PATH environment variable**

If auto-detection fails, manually configure the Node.js path in Preferences → Advanced.

## 🎮 Usage

### Basic Operation

1. **Launch**: CCTray appears as an orange "C" in your menu bar
2. **Click**: View detailed usage information in the dropdown
3. **Rotating Display**: Icon cycles through cost → burn rate → remaining time every 5 seconds
4. **Preferences**: Click "Preferences..." to customize settings

### Menu Bar States

- **💤**: No active Claude Code session
- **⏳**: Loading usage data
- **❌**: Error connecting to ccusage
- **C $X.XX**: Current session cost
- **C XXX/min**: Current burn rate (tokens per minute)
- **C XXmin**: Estimated time remaining

### Understanding Burn Rate Colors

- **🟢 LOW**: < 300 tokens/min
- **🟡 MEDIUM**: 300-700 tokens/min  
- **🔴 HIGH**: > 700 tokens/min

## ⚙️ Configuration

### General Settings
- **Update Interval**: How often to fetch usage data (1-30 seconds)
- **Display Components**: Toggle cost, burn rate, and remaining time
- **Launch at Login**: Auto-start CCTray with macOS

### Display Settings
- **Rotation Speed**: How fast the menu bar display cycles (1-30 seconds)
- **Decimal Places**: Cost display precision (0-3 decimal places)
- **Burn Rate Thresholds**: Customize low/high warning levels

### Advanced Settings
- **Node.js Command**: Custom Node.js executable path
- **ccusage Script**: Custom ccusage script location
- **Reset to Defaults**: Restore all settings

### About
- **Version Information**: Current app version
- **Author**: Robert Goniszewski

## 🛠 Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/goniszewski/cctray.git
cd cctray

# Open in Xcode
open CCTray.xcodeproj

# Build with Xcode (Cmd+B) or command line:
xcodebuild -project CCTray.xcodeproj -scheme CCTray -configuration Debug
```

### Running Tests

```bash
# Unit tests
xcodebuild test -project CCTray.xcodeproj -scheme CCTray -destination 'platform=macOS'

# In Xcode: Cmd+U for all tests
```

### Architecture Overview

CCTray follows modern SwiftUI patterns with:

- **MVVM Architecture**: Clean separation of Models, Views, and ViewModels
- **Actor-based Services**: Safe async operations with `CommandExecutor`
- **State Management**: `@StateObject`, `@EnvironmentObject`, and `@AppStorage`
- **Menu Bar Integration**: Modern `MenuBarExtra` with `SettingsLink`

**Key Components:**
- `UsageMonitor`: Core business logic and data fetching
- `CommandExecutor`: Secure shell command execution with caching
- `AppPreferences`: User settings with persistent storage
- `PreferencesView`: Four-tab settings interface

### File Structure

```
CCTray/
├── CCTray/
│   ├── Models/           # Data models and enums
│   ├── Views/            # SwiftUI views and UI components
│   ├── ViewModels/       # Business logic and state management
│   ├── Services/         # External service integration
│   └── Utilities/        # Helper classes and extensions
├── CCTrayTests/          # Unit tests
└── CCTrayUITests/        # UI tests
```

## 🔧 Troubleshooting

### Common Issues

**"Command not found" Error**
- Ensure Node.js is installed and accessible
- Check Node.js path in Preferences → Advanced
- Verify ccusage is installed: `npm list -g ccusage`

**"Permission denied" Error**  
- CCTray requires permission to execute shell commands
- Check macOS security settings
- App sandbox is disabled for command execution

**Menu Bar Shows "❌"**
- Verify ccusage CLI is working: `ccusage blocks --live --json`
- Check Node.js installation and PATH
- Review error details in the dropdown menu

**High CPU Usage**
- Increase update interval in Preferences → General
- CCTray uses exponential backoff during errors to reduce load

### Advanced Troubleshooting

**Custom ccusage Installation**
```bash
# Find your ccusage installation
npm list -g ccusage

# Configure custom path in Preferences → Advanced
# Example: /Users/username/.nvm/versions/node/v20.11.0/lib/node_modules/ccusage/dist/index.js
```

**Debug Mode**
Enable detailed logging by running CCTray from Terminal:
```bash
/Applications/CCTray.app/Contents/MacOS/CCTray
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/goniszewski/cctray/issues)
- **Discussions**: [GitHub Discussions](https://github.com/goniszewski/cctray/discussions)

---

**Made with ❤️ for the Claude Code community**