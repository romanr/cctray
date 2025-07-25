import Foundation
import AppKit
import UserNotifications

class SoundManager: ObservableObject {
    @MainActor static let shared = SoundManager()
    
    // Available system notification sounds
    static let systemSounds: [(name: String, displayName: String)] = [
        ("", "No Sound"),
        ("default", "Default"),
        ("Basso", "Basso"),
        ("Blow", "Blow"),
        ("Bottle", "Bottle"),
        ("Frog", "Frog"),
        ("Funk", "Funk"),
        ("Glass", "Glass"),
        ("Hero", "Hero"),
        ("Morse", "Morse"),
        ("Ping", "Ping"),
        ("Pop", "Pop"),
        ("Purr", "Purr"),
        ("Sosumi", "Sosumi"),
        ("Submarine", "Submarine"),
        ("Tink", "Tink")
    ]
    
    private init() {}
    
    // MARK: - Sound Creation
    
    /// Creates a UNNotificationSound for the given sound name
    static func createNotificationSound(from soundName: String) -> UNNotificationSound? {
        if soundName == "default" || soundName.isEmpty {
            return .default
        }
        
        // For system sounds, try to create with the name
        return UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
    }
    
    // MARK: - Sound Preview
    
    /// Plays a preview of the selected sound
    @MainActor func previewSound(_ soundName: String) {
        if soundName == "default" || soundName.isEmpty {
            // Play the default system sound
            NSSound.beep()
            return
        }
        
        // Try to find and play the system sound
        if let sound = NSSound(named: soundName) {
            sound.play()
        } else {
            // Fallback to system beep if sound not found
            NSSound.beep()
        }
    }
    
    // MARK: - Sound Validation
    
    /// Validates if a sound name is available on the system
    static func isValidSound(_ soundName: String) -> Bool {
        if soundName == "default" || soundName.isEmpty {
            return true
        }
        
        // Check if it's a known system sound
        return systemSounds.contains { $0.name == soundName }
    }
    
    /// Gets the display name for a sound
    static func displayName(for soundName: String) -> String {
        if let sound = systemSounds.first(where: { $0.name == soundName }) {
            return sound.displayName
        }
        return soundName.capitalized
    }
    
    // MARK: - Migration Support
    
    /// Migrates from boolean sound preference to named sound preference
    static func migrateFromBooleanPreference(_ enabled: Bool) -> String {
        return enabled ? "default" : ""
    }
    
    /// Checks if sound is enabled (for backward compatibility)
    static func isSoundEnabled(_ soundName: String) -> Bool {
        return !soundName.isEmpty
    }
}