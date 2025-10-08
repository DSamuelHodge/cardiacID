//
//  BiometricModels.swift
//  HeartID Watch App & iOS App
//
//  Comprehensive model definitions for biometric authentication
//

import Foundation

// MARK: - Authentication Results

/// Result of an authentication attempt
enum AuthenticationResult: String, CaseIterable, Codable {
    case approved = "approved"
    case retryRequired = "retry_required" 
    case failed = "failed"
    case pending = "pending"
    case systemUnavailable = "system_unavailable"
    case enrollmentRequired = "enrollment_required"
    
    var isSuccessful: Bool {
        return self == .approved
    }
    
    var requiresRetry: Bool {
        return self == .retryRequired
    }
    
    var message: String {
        switch self {
        case .approved:
            return "Authentication successful"
        case .retryRequired:
            return "Authentication partially successful - please try again"
        case .failed:
            return "Authentication failed - pattern did not match"
        case .pending:
            return "Authentication in progress"
        case .systemUnavailable:
            return "Authentication system temporarily unavailable"
        case .enrollmentRequired:
            return "Enrollment required before authentication"
        }
    }
}

// MARK: - Security Levels

/// Security level configuration for authentication
enum SecurityLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium" 
    case high = "High"
    case maximum = "Maximum"
    
    var threshold: Double {
        switch self {
        case .low: return 0.6
        case .medium: return 0.75
        case .high: return 0.85
        case .maximum: return 0.9
        }
    }
    
    var retryThreshold: Double {
        switch self {
        case .low: return 0.4
        case .medium: return 0.5
        case .high: return 0.6
        case .maximum: return 0.7
        }
    }
    
    var description: String {
        switch self {
        case .low:
            return "Lower security, faster authentication"
        case .medium:
            return "Balanced security and convenience"
        case .high:
            return "Higher security, more precise matching required"
        case .maximum:
            return "Maximum security, strictest pattern matching"
        }
    }
}

// MARK: - Authentication Session Management

/// Tracks an ongoing authentication session
class AuthenticationSession: ObservableObject {
    @Published var isActive: Bool = false
    @Published var startTime: Date?
    @Published var attempts: [AuthenticationAttempt] = []
    @Published var sessionResult: AuthenticationResult?
    
    private let maxAttempts = 3
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    
    func startSession() {
        isActive = true
        startTime = Date()
        attempts.removeAll()
        sessionResult = nil
    }
    
    func recordAttempt(_ result: AuthenticationResult) {
        let attempt = AuthenticationAttempt(
            result: result,
            confidenceScore: 0.0, // Will be set by caller
            patternMatch: 0.0,    // Will be set by caller
            duration: 0.0         // Will be set by caller
        )
        attempts.append(attempt)
        
        // Update session result
        if result.isSuccessful {
            sessionResult = result
            endSession()
        } else if attempts.count >= maxAttempts {
            sessionResult = .failed
            endSession()
        }
    }
    
    func resetSession() {
        isActive = false
        startTime = nil
        attempts.removeAll()
        sessionResult = nil
    }
    
    private func endSession() {
        isActive = false
    }
    
    var isTimedOut: Bool {
        guard let startTime = startTime else { return false }
        return Date().timeIntervalSince(startTime) > sessionTimeout
    }
    
    var remainingAttempts: Int {
        return max(0, maxAttempts - attempts.count)
    }
}

// MARK: - Authentication Attempt Tracking

/// Records details of a single authentication attempt
struct AuthenticationAttempt: Codable {
    let id = UUID()
    let timestamp = Date()
    let result: AuthenticationResult
    let confidenceScore: Double
    let patternMatch: Double
    let duration: TimeInterval
    
    init(result: AuthenticationResult, confidenceScore: Double, patternMatch: Double, duration: TimeInterval) {
        self.result = result
        self.confidenceScore = confidenceScore
        self.patternMatch = patternMatch
        self.duration = duration
    }
}

// MARK: - User Profile Management

/// User's profile including biometric data and preferences
struct UserProfile: Codable {
    let id = UUID()
    let encryptedHeartPattern: String
    let securityLevel: SecurityLevel
    let enrollmentDate = Date()
    private(set) var lastAuthenticationDate: Date?
    private(set) var authenticationCount: Int = 0
    private(set) var failedAttempts: Int = 0
    
    init(encryptedHeartPattern: String, securityLevel: SecurityLevel) {
        self.encryptedHeartPattern = encryptedHeartPattern
        self.securityLevel = securityLevel
    }
    
    var isEnrolled: Bool {
        return !encryptedHeartPattern.isEmpty
    }
    
    mutating func updateAfterAuthentication(successful: Bool = true) -> UserProfile {
        if successful {
            lastAuthenticationDate = Date()
            authenticationCount += 1
            failedAttempts = 0 // Reset failed attempts on success
        } else {
            failedAttempts += 1
        }
        return self
    }
}

// MARK: - User Preferences

/// User's app preferences and settings
struct UserPreferences: Codable {
    var securityLevel: SecurityLevel = .medium
    var enableAlarms: Bool = true
    var enableNotifications: Bool = true
    var authenticationFrequency: AuthenticationFrequency = .moderate
    var enableBackgroundAuthentication: Bool = false
    var debugMode: Bool = false
    var enableBluetooth: Bool = true
    var enableNFC: Bool = true
    
    enum AuthenticationFrequency: String, CaseIterable, Codable {
        case minimal = "Minimal"
        case moderate = "Moderate"
        case frequent = "Frequent"
        case continuous = "Continuous"
        
        var minIntervalMinutes: Int {
            switch self {
            case .minimal: return 60     // 1 hour
            case .moderate: return 30    // 30 minutes
            case .frequent: return 15    // 15 minutes
            case .continuous: return 5   // 5 minutes
            }
        }
    }
}

// MARK: - Biometric Pattern Analysis

/// Result from XenonX pattern analysis
struct XenonXResult: Codable {
    let patternId: String
    let confidence: Double
    let timestamp: Date
    let analysisData: Data
    
    init(patternId: String, confidence: Double, analysisData: Data) {
        self.patternId = patternId
        self.confidence = confidence
        self.timestamp = Date()
        self.analysisData = analysisData
    }
}

// MARK: - Mock Services for Development

/// Mock XenonX calculator for pattern analysis
class XenonXCalculator {
    func analyzePattern(_ heartRateData: [Double]) -> XenonXResult {
        // Mock implementation - in real app this would be sophisticated biometric analysis
        let confidence = Double.random(in: 0.6...0.95)
        let patternId = UUID().uuidString
        let analysisData = try! JSONEncoder().encode(heartRateData)
        
        return XenonXResult(
            patternId: patternId,
            confidence: confidence,
            analysisData: analysisData
        )
    }
    
    func comparePatterns(_ stored: XenonXResult, _ current: XenonXResult) -> Double {
        // Mock implementation - in real app this would compare actual biometric patterns
        let baseSimilarity = Double.random(in: 0.5...0.9)
        
        // Add some logic to make it more realistic
        let confidenceFactor = min(stored.confidence, current.confidence)
        let adjustedSimilarity = baseSimilarity * confidenceFactor
        
        return adjustedSimilarity
    }
}

// MARK: - Encryption Service

/// Service for encrypting/decrypting biometric templates
class EncryptionService {
    func encryptXenonXResult(_ result: XenonXResult) -> Data? {
        // Mock implementation - in real app this would use proper encryption
        return try? JSONEncoder().encode(result)
    }
    
    func decryptXenonXResult(_ encryptedData: Data) -> XenonXResult? {
        // Mock implementation - in real app this would use proper decryption
        return try? JSONDecoder().decode(XenonXResult.self, from: encryptedData)
    }
}

// MARK: - App Configuration

/// Configuration constants for the biometric system
enum AppConfiguration {
    static let defaultCaptureDuration: TimeInterval = 12.0
    static let minCaptureDuration: TimeInterval = 9.0
    static let maxCaptureDuration: TimeInterval = 16.0
    static let minPatternSamples: Int = 8
    static let maxRetryAttempts: Int = 3
    static let sessionTimeoutMinutes: Int = 5
}
