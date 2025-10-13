//
//  TypeAliases.swift  
//  HeartID Watch App
//
//  Centralized type aliases and imports to resolve ambiguity issues
//

import Foundation

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
    
    private func generateMockSamples() -> [HeartRateSample] {
        return (0..<20).map { i in
            HeartRateSample(
                value: 70.0 + Double.random(in: -10...10),
                timestamp: Date().addingTimeInterval(TimeInterval(i)),
                source: "Mock",
                quality: 0.95
            )
        }
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
}