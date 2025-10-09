//
//  BiometricModels.swift
//  HeartID Watch App & iOS App
//
//  Comprehensive model definitions for biometric authentication
//

import Foundation

// MARK: - Authentication Results

/// Result of an authentication attempt
enum AuthenticationResult: Codable {
    case approved(confidence: Double)
    case denied(reason: String)
    case retry(message: String)
    case error(message: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case confidence
        case reason
        case message
    }
    
    private enum CaseType: String, Codable {
        case approved
        case denied
        case retry
        case error
    }
    
    var isSuccessful: Bool {
        if case .approved = self { return true }
        return false
    }
    
    var message: String {
        switch self {
        case .approved(let confidence):
            return "Authentication successful (\(Int(confidence * 100))% match)"
        case .denied(let reason):
            return "Access denied: \(reason)"
        case .retry(let message):
            return message
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CaseType.self, forKey: .type)
        switch type {
        case .approved:
            let confidence = try container.decode(Double.self, forKey: .confidence)
            self = .approved(confidence: confidence)
        case .denied:
            let reason = try container.decode(String.self, forKey: .reason)
            self = .denied(reason: reason)
        case .retry:
            let message = try container.decode(String.self, forKey: .message)
            self = .retry(message: message)
        case .error:
            let message = try container.decode(String.self, forKey: .message)
            self = .error(message: message)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .approved(let confidence):
                try container.encode(CaseType.approved, forKey: .type)
                try container.encode(confidence, forKey: .confidence)
            case .denied(let reason):
                try container.encode(CaseType.denied, forKey: .type)
                try container.encode(reason, forKey: .reason)
            case .retry(let message):
                try container.encode(CaseType.retry, forKey: .type)
                try container.encode(message, forKey: .message)
            case .error(let message):
                try container.encode(CaseType.error, forKey: .type)
                try container.encode(message, forKey: .message)
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
            sessionResult = .denied(reason: "Maximum attempts reached")
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
    let id: UUID
    let timestamp: Date
    let result: AuthenticationResult
    let confidenceScore: Double
    let patternMatch: Double
    let duration: TimeInterval
    
    init(result: AuthenticationResult, confidenceScore: Double, patternMatch: Double, duration: TimeInterval) {
        self.id = UUID()
        self.timestamp = Date()
        self.result = result
        self.confidenceScore = confidenceScore
        self.patternMatch = patternMatch
        self.duration = duration
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case result
        case confidenceScore
        case patternMatch
        case duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        self.result = try container.decode(AuthenticationResult.self, forKey: .result)
        self.confidenceScore = try container.decode(Double.self, forKey: .confidenceScore)
        self.patternMatch = try container.decode(Double.self, forKey: .patternMatch)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(result, forKey: .result)
        try container.encode(confidenceScore, forKey: .confidenceScore)
        try container.encode(patternMatch, forKey: .patternMatch)
        try container.encode(duration, forKey: .duration)
    }
}

// MARK: - User Profile Management

/// User's profile including biometric data and preferences
struct UserProfile: Codable {
    let id: UUID
    let enrollmentDate: Date
    let biometricTemplate: BiometricTemplate
    var lastAuthenticationDate: Date?
    var authenticationCount: Int = 0
    
    init(id: UUID = UUID(), template: BiometricTemplate) {
        self.id = id
        self.enrollmentDate = Date()
        self.biometricTemplate = template
    }
    
    var isEnrolled: Bool {
        return true // Always enrolled if profile exists
    }
    
    mutating func updateAfterAuthentication(successful: Bool = true) -> UserProfile {
        if successful {
            lastAuthenticationDate = Date()
            authenticationCount += 1
        }
        return self
    }
}

// MARK: - Biometric Template

/// Biometric template containing heart rate pattern data
struct BiometricTemplate: Codable {
    let heartRatePattern: [Double]
    let averageHeartRate: Double
    let heartRateVariability: Double
    let captureQuality: Double
    let captureDate: Date
    
    init(heartRatePattern: [Double]) {
        self.heartRatePattern = heartRatePattern
        self.averageHeartRate = heartRatePattern.reduce(0, +) / Double(heartRatePattern.count)
        self.heartRateVariability = Self.calculateHRV(heartRatePattern)
        self.captureQuality = Self.assessQuality(heartRatePattern)
        self.captureDate = Date()
    }
    
    // Calculate Heart Rate Variability
    private static func calculateHRV(_ samples: [Double]) -> Double {
        guard samples.count > 1 else { return 0 }
        
        var differences: [Double] = []
        for i in 1..<samples.count {
            differences.append(abs(samples[i] - samples[i-1]))
        }
        
        let mean = differences.reduce(0, +) / Double(differences.count)
        return mean
    }
    
    // Assess data quality (0.0 to 1.0)
    private static func assessQuality(_ samples: [Double]) -> Double {
        guard samples.count >= 100 else { return 0.0 }
        
        let avg = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.map { pow($0 - avg, 2) }.reduce(0, +) / Double(samples.count)
        let stdDev = sqrt(variance)
        
        // Good quality: consistent but with natural variation
        // Poor quality: too consistent (sensor not on skin) or too noisy
        if stdDev < 2.0 { return 0.3 } // Too consistent
        if stdDev > 30.0 { return 0.4 } // Too noisy
        if avg < 40 || avg > 200 { return 0.2 } // Unrealistic
        
        return 0.95 // Good quality
    }
}

// MARK: - Enrollment Validation

/// Validation result for enrollment data
struct EnrollmentValidation {
    let isValid: Bool
    let errorMessage: String?
    let qualityScore: Double
    
    static func validate(_ samples: [Double]) -> EnrollmentValidation {
        // Check sample count
        guard samples.count >= 200 else {
            return EnrollmentValidation(
                isValid: false,
                errorMessage: "Insufficient data captured. Please try again.",
                qualityScore: 0.0
            )
        }
        
        // Check for realistic heart rate range
        let avg = samples.reduce(0, +) / Double(samples.count)
        guard avg >= 40 && avg <= 200 else {
            return EnrollmentValidation(
                isValid: false,
                errorMessage: "Heart rate reading out of range. Ensure sensor contact.",
                qualityScore: 0.0
            )
        }
        
        // Check for variation (not flat line)
        let variance = samples.map { pow($0 - avg, 2) }.reduce(0, +) / Double(samples.count)
        let stdDev = sqrt(variance)
        
        if stdDev < 2.0 {
            return EnrollmentValidation(
                isValid: false,
                errorMessage: "No variation detected. Ensure finger is on sensor.",
                qualityScore: 0.3
            )
        }
        
        if stdDev > 30.0 {
            return EnrollmentValidation(
                isValid: false,
                errorMessage: "Too much noise. Hold still and try again.",
                qualityScore: 0.4
            )
        }
        
        // Calculate quality score
        let qualityScore = BiometricTemplate.init(heartRatePattern: samples).captureQuality
        
        if qualityScore < 0.7 {
            return EnrollmentValidation(
                isValid: false,
                errorMessage: "Low quality capture. Please try again.",
                qualityScore: qualityScore
            )
        }
        
        return EnrollmentValidation(
            isValid: true,
            errorMessage: nil,
            qualityScore: qualityScore
        )
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

