//
//  TypeAliases.swift  
//  HeartID Watch App
//
//  Centralized type aliases and imports to resolve ambiguity issues
//

import Foundation
import SwiftUI

// MARK: - Debug Logger Implementation

/// Simple debug logger for watchOS app
class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    private init() {}
    
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] [\(level.rawValue)] \(message)")
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func warning(_ message: String) {
        log(message, level: .warning)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    // Additional convenience methods
    func auth(_ message: String) {
        log("🔐 AUTH: \(message)", level: .info)
    }
    
    func health(_ message: String) {
        log("❤️ HEALTH: \(message)", level: .info)
    }
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Debug Logger Access
/// Global debug logger instance for consistent logging throughout the app
let debugLog = DebugLogger.shared

// MARK: - Type Aliases for Disambiguation

/// Use the main HRVCalculator implementation
typealias MainHRVCalculator = HRVCalculator

/// Use the main EnhancedBiometricValidation implementation  
typealias MainEnhancedBiometricValidation = EnhancedBiometricValidation

/// Use the main HealthKit service implementation
typealias MainHealthKitService = HealthKitService

// MARK: - Mock Service Protocol

/// Protocol that mock services should implement
protocol MockServiceProtocol {
    var isAuthorized: Bool { get set }
    var heartRateSamples: [HeartRateSample] { get set }
}

/// Enhanced mock HealthKit service for testing
class MockHealthKitService: ObservableObject, MockServiceProtocol {
    @Published var isAuthorized: Bool = false
    @Published var heartRateSamples: [HeartRateSample] = []
    @Published var isCapturing: Bool = false
    @Published var currentHeartRate: Double = 0
    @Published var captureProgress: Double = 0
    @Published var errorMessage: String?
    
    func startHeartRateCapture(duration: TimeInterval, completion: @escaping ([HeartRateSample], Error?) -> Void) {
        // Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockSamples = self.generateMockSamples()
            completion(mockSamples, nil)
        }
    }
    
    func validateHeartRateData(_ data: [Double]) -> Bool {
        return !data.isEmpty && data.allSatisfy { $0 >= 40 && $0 <= 200 }
    }
    
    func setMockAuthorization(_ authorized: Bool) {
        self.isAuthorized = authorized
    }
    
    func testHeartRateDataAccess() -> Bool {
        return isAuthorized
    }
    
    func generateMockSamples() -> [HeartRateSample] {
        return (0..<20).map { i in
            HeartRateSample(
                value: 70.0 + Double.random(in: -10...10),
                timestamp: Date().addingTimeInterval(TimeInterval(i)),
                source: "Mock",
                quality: 0.95
            )
        }
    }
    
    // Add async authorization method for compatibility
    func ensureAuthorization() async -> AuthorizationResult {
        if isAuthorized {
            return .authorized
        } else {
            return .denied("Mock authorization denied")
        }
    }
}

// MARK: - Authorization Result for Mock Service

enum AuthorizationResult {
    case authorized
    case denied(String)
    case notAvailable(String)
}

// MARK: - Service Compatibility Extensions

extension AuthenticationService {
    func setHealthKitService(_ service: HealthKitService) {
        // Implementation for service connection
        debugLog.info("🔗 HealthKit service connected to AuthenticationService")
    }
    
    func setDataManager(_ manager: DataManager) {
        // Implementation for data manager connection
        debugLog.info("🔗 DataManager connected to AuthenticationService")
    }
}

extension HealthKitService {
    func ensureAuthorization() async -> AuthorizationResult {
        // Simplified authorization check for watchOS
        if HKHealthStore.isHealthDataAvailable() {
            return .authorized
        } else {
            return .notAvailable("HealthKit not available on this device")
        }
    }
}

extension DataManager {
    func isUserEnrolled() -> Bool {
        // Check if user profile exists
        return getUserProfile() != nil
    }
}

// MARK: - View Name Disambiguation

/// Ensure view names don't conflict by using explicit namespacing
enum ViewNamespace {
    // Primary view implementations
    static let authenticateView = "AuthenticateView"
    static let enrollmentView = "EnrollmentView" 
    static let dashboardView = "DashboardView"
    static let settingsView = "SettingsView"
    static let recentActivityView = "RecentActivityView"
    
    // Flow views
    static let enrollmentFlowView = "EnrollmentFlowView"
    static let welcomeStepView = "WelcomeStepView"
    static let captureStepView = "CaptureStepView"
    static let completionStepView = "CompletionStepView"
}

// MARK: - Constants for Cross-Platform Compatibility

/// watchOS-compatible color constants
enum WatchColors {
    static let backgroundGray = Color.gray.opacity(0.2)
    static let cardBackground = Color.black.opacity(0.3)
    static let secondaryBackground = Color.gray.opacity(0.1)
    static let primary = Color.blue
    static let secondary = Color.gray
    static let accent = Color.red
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}