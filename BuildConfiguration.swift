//
//  BuildConfiguration.swift
//  HeartID Watch App
//
//  Build configuration to resolve module conflicts
//

import Foundation

// MARK: - Build Configuration Helper

struct BuildConfiguration {
    
    // MARK: - Environment Detection
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isTestEnvironment: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Feature Flags
    
    static var enableAdvancedLogging: Bool {
        return isDebug
    }
    
    static var enableHapticFeedback: Bool {
        return true // Always enabled for Watch
    }
    
    static var enableBiometricValidation: Bool {
        return true
    }
    
    // MARK: - Configuration Values
    
    static var defaultCaptureDuration: TimeInterval {
        return isDebug ? 5.0 : 10.0 // Shorter for debugging
    }
    
    static var maxRetryAttempts: Int {
        return isDebug ? 5 : 3
    }
    
    static var qualityThreshold: Double {
        return isDebug ? 0.6 : 0.75
    }
}

// MARK: - Logging Helper

struct AppLogger {
    
    static func log(_ message: String, category: LogCategory = .general) {
        if BuildConfiguration.enableAdvancedLogging {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            print("[\(timestamp)] [\(category.rawValue)] \(message)")
        }
    }
    
    static func error(_ message: String, error: Error? = nil) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] [ERROR] \(message)")
        if let error = error {
            print("[\(timestamp)] [ERROR] \(error.localizedDescription)")
        }
    }
}

enum LogCategory: String {
    case general = "GENERAL"
    case enrollment = "ENROLL"
    case authentication = "AUTH"
    case healthkit = "HEALTH"
    case biometric = "BIOMETRIC"
    case security = "SECURITY"
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}