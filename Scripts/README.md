# Build Scripts

## update-git-info.sh

This script automatically updates `GitInfo.swift` with the current git commit information during the build process.

### Usage

To integrate this script into your Xcode build process:

1. Open your Xcode project
2. Select your target (CCTray)
3. Go to "Build Phases" tab
4. Click the "+" button and select "New Run Script Phase"
5. Add this script path: `${SRCROOT}/Scripts/update-git-info.sh`
6. Make sure the script runs before the "Compile Sources" phase

### What it does

- Gets the current git commit hash
- Gets the commit timestamp
- Updates `GitInfo.swift` with the latest information
- Ensures the About window always shows current build information

### Requirements

- Git must be available in the build environment
- The script must be executable (`chmod +x`)
- The project must be in a git repository