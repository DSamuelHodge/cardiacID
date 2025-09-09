import Foundation

/// Debug configuration for HeartID Mobile app
struct DebugConfig {
    /// Enable/disable debug logging
    static let isDebugEnabled = true
    
    /// Enable/disable verbose logging
    static let isVerboseLogging = true
    
    /// Enable/disable network request logging
    static let isNetworkLoggingEnabled = true
    
    /// Enable/disable authentication logging
    static let isAuthLoggingEnabled = true
    
    /// Enable/disable watch connectivity logging
    static let isWatchLoggingEnabled = true
    
    /// Enable/disable health data logging
    static let isHealthLoggingEnabled = true
    
    /// Enable/disable UI state logging
    static let isUIStateLoggingEnabled = true
    
    /// Mock data for testing (set to true for development)
    static let useMockData = false
    
    /// Simulate network delays for testing
    static let simulateNetworkDelay = false
    
    /// Network delay in seconds (if simulation is enabled)
    static let networkDelaySeconds: Double = 1.0
    
    /// Enable/disable crash reporting
    static let isCrashReportingEnabled = true
    
    /// Enable/disable analytics
    static let isAnalyticsEnabled = false
    
    /// App version for debugging
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    /// Build number for debugging
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    
    /// Debug info string
    static var debugInfo: String {
        return "HeartID Mobile v\(appVersion) (\(buildNumber)) - Debug: \(isDebugEnabled ? "ON" : "OFF")"
    }
    
    /// Check if running in simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    /// Check if running in debug mode
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}



