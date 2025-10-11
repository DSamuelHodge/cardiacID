import Foundation

/// Application configuration and settings with user customization support
struct AppConfiguration {
    
    // MARK: - Heart Rate Capture (User Configurable)
    static let minCaptureDuration: TimeInterval = 6.0
    static let maxCaptureDuration: TimeInterval = 16.0
    static let defaultCaptureDuration: TimeInterval = 8.0
    
    // MARK: - Pattern Analysis (User Configurable)
    static let minPatternSamples = 5
    static let maxPatternSamples = 50
    static let minConfidenceThreshold: Double = 0.6
    
    // MARK: - Authentication Thresholds (User Configurable)
    static let defaultSecurityThreshold: Double = 75.0
    static let defaultRetryThreshold: Double = 60.0
    static let maxRetryAttempts = 3
    
    // MARK: - Background Tasks
    static let backgroundTaskIdentifier = "com.heartid.background.authentication"
    static let notificationIdentifier = "com.heartid.authentication"
    static let minBackgroundInterval: TimeInterval = 300 // 5 minutes
    static let maxBackgroundInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Performance Settings (User Configurable)
    static let maxConcurrentOperations = 3
    static let cacheSizeLimit = 100 // MB
    static let timeoutDuration: TimeInterval = 30.0
    static let backgroundTaskTimeout: TimeInterval = 10.0
    
    // MARK: - Security Settings
    static let encryptionAlgorithm = "AES-GCM"
    static let keySize = 256 // bits
    static let hashAlgorithm = "SHA-256"
    static let maxSessionDuration: TimeInterval = 3600 // 1 hour
    static let requireReauthentication = true
    
    // MARK: - UserDefaults Keys
    static let encryptionKey = "HeartID_Encryption_Key_2024"
    static let userDefaultsKey = "HeartID_UserProfile"
    static let preferencesKey = "HeartID_UserPreferences"
    static let configurationKey = "HeartID_Configuration"
    
    // MARK: - User Configuration Management
    
    /// Get user-configured capture duration based on security level
    static func getCaptureDuration(for securityLevel: SecurityLevel) -> TimeInterval {
        let userConfig = getUserConfiguration()
        let baseDuration = securityLevel.recommendedCaptureDuration
        
        // Apply user multiplier if configured
        let multiplier = userConfig.captureDurationMultiplier
        let adjustedDuration = baseDuration * multiplier
        
        // Ensure within bounds
        return max(minCaptureDuration, min(maxCaptureDuration, adjustedDuration))
    }
    
    /// Get user-configured processing time
    static func getProcessingTime(for securityLevel: SecurityLevel) -> TimeInterval {
        let userConfig = getUserConfiguration()
        let baseTime = securityLevel.recommendedProcessingTime
        
        // Apply user multiplier if configured
        let multiplier = userConfig.processingTimeMultiplier
        return baseTime * multiplier
    }
    
    /// Get user-configured retry attempts
    static func getMaxRetryAttempts(for securityLevel: SecurityLevel) -> Int {
        let userConfig = getUserConfiguration()
        let baseAttempts = securityLevel.maxRetryAttempts
        
        // Apply user adjustment if configured
        let adjustment = userConfig.retryAttemptsAdjustment
        return max(1, min(10, baseAttempts + adjustment))
    }
    
    /// Get user-configured confidence threshold
    static func getConfidenceThreshold(for securityLevel: SecurityLevel) -> Double {
        let userConfig = getUserConfiguration()
        let baseThreshold = securityLevel.effectiveThreshold
        
        // Apply user adjustment if configured
        let adjustment = userConfig.confidenceThresholdAdjustment
        return max(0.1, min(1.0, baseThreshold + adjustment))
    }
    
    /// Check if debug mode is enabled
    static var isDebugMode: Bool {
        return getUserConfiguration().debugMode
    }
    
    /// Check if performance monitoring is enabled
    static var isPerformanceMonitoringEnabled: Bool {
        return getUserConfiguration().performanceMonitoring
    }
    
    /// Check if analytics are enabled
    static var isAnalyticsEnabled: Bool {
        return getUserConfiguration().analyticsEnabled
    }
    
    // MARK: - Configuration Storage
    
    /// Get user configuration from UserDefaults
    private static func getUserConfiguration() -> UserConfiguration {
        if let data = UserDefaults.standard.data(forKey: configurationKey),
           let config = try? JSONDecoder().decode(UserConfiguration.self, from: data) {
            return config
        }
        return UserConfiguration() // Default configuration
    }
    
    /// Save user configuration to UserDefaults
    static func saveUserConfiguration(_ config: UserConfiguration) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configurationKey)
        }
    }
    
    /// Reset configuration to defaults
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: configurationKey)
    }
}

// MARK: - User Configuration Model

/// User-configurable settings for the app
struct UserConfiguration: Codable {
    // Capture settings
    var captureDurationMultiplier: Double = 1.0
    var processingTimeMultiplier: Double = 1.0
    var retryAttemptsAdjustment: Int = 0
    var confidenceThresholdAdjustment: Double = 0.0
    
    // Feature toggles
    var debugMode: Bool = false
    var performanceMonitoring: Bool = true
    var analyticsEnabled: Bool = true
    var hapticFeedbackEnabled: Bool = true
    var soundEffectsEnabled: Bool = false
    
    // Advanced settings
    var enableAdvancedAnalytics: Bool = false
    var enableCrashReporting: Bool = true
    var enableUsageStatistics: Bool = true
    var enableBiometricLogging: Bool = false
    
    // Performance settings
    var enableFFTCaching: Bool = true
    var enableFeatureCaching: Bool = true
    var maxCacheSize: Int = 100 // MB
    var cacheExpirationTime: TimeInterval = 3600 // 1 hour
    
    // Security settings
    var enableTemplateEncryption: Bool = true
    var enableSecureEnclave: Bool = true
    var enableKeychainSync: Bool = false
    var requireBiometricReauth: Bool = true
    
    // UI settings
    var enableAnimations: Bool = true
    var enableHapticFeedback: Bool = true
    var enableSoundEffects: Bool = false
    var preferredTheme: String = "system"
    
    // Validation settings
    var enableDataValidation: Bool = true
    var enableQualityChecks: Bool = true
    var enableConsistencyChecks: Bool = true
    var enableTrendAnalysis: Bool = true
    
    init() {
        // Use default values
    }
}

// MARK: - Configuration Validation

extension UserConfiguration {
    
    /// Validate configuration values
    func validate() -> [String] {
        var errors: [String] = []
        
        if captureDurationMultiplier < 0.5 || captureDurationMultiplier > 2.0 {
            errors.append("Capture duration multiplier must be between 0.5 and 2.0")
        }
        
        if processingTimeMultiplier < 0.5 || processingTimeMultiplier > 2.0 {
            errors.append("Processing time multiplier must be between 0.5 and 2.0")
        }
        
        if retryAttemptsAdjustment < -2 || retryAttemptsAdjustment > 5 {
            errors.append("Retry attempts adjustment must be between -2 and 5")
        }
        
        if confidenceThresholdAdjustment < -0.2 || confidenceThresholdAdjustment > 0.2 {
            errors.append("Confidence threshold adjustment must be between -0.2 and 0.2")
        }
        
        if maxCacheSize < 10 || maxCacheSize > 1000 {
            errors.append("Max cache size must be between 10 and 1000 MB")
        }
        
        if cacheExpirationTime < 300 || cacheExpirationTime > 86400 {
            errors.append("Cache expiration time must be between 5 minutes and 24 hours")
        }
        
        return errors
    }
    
    /// Get configuration summary
    var summary: String {
        return """
        Capture Duration: \(String(format: "%.1fx", captureDurationMultiplier))
        Processing Time: \(String(format: "%.1fx", processingTimeMultiplier))
        Retry Adjustment: \(retryAttemptsAdjustment)
        Confidence Adjustment: \(String(format: "%.2f", confidenceThresholdAdjustment))
        Debug Mode: \(debugMode ? "On" : "Off")
        Performance Monitoring: \(performanceMonitoring ? "On" : "Off")
        Analytics: \(analyticsEnabled ? "On" : "Off")
        Haptic Feedback: \(hapticFeedbackEnabled ? "On" : "Off")
        """
    }
}
