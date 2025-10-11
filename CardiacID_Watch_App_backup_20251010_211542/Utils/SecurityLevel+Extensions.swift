//
//  SecurityLevel+Extensions.swift
//  HeartID Watch App
//
//  Extensions for SecurityLevel to provide additional functionality
//

import Foundation

extension SecurityLevel {
    
    /// Get the recommended capture duration for this security level
    var recommendedCaptureDuration: TimeInterval {
        switch self {
        case .low:
            return 6.0 // Faster capture for lower security
        case .medium:
            return 8.0 // Balanced duration
        case .high:
            return 10.0 // Longer capture for better accuracy
        case .maximum:
            return 12.0 // Maximum duration for highest security
        }
    }
    
    /// Get the minimum number of samples required for this security level
    var minimumSamples: Int {
        switch self {
        case .low:
            return 5
        case .medium:
            return 8
        case .high:
            return 12
        case .maximum:
            return 15
        }
    }
    
    /// Get the maximum retry attempts allowed for this security level
    var maxRetryAttempts: Int {
        switch self {
        case .low:
            return 5 // More retries for lower security
        case .medium:
            return 3 // Standard retries
        case .high:
            return 2 // Fewer retries for higher security
        case .maximum:
            return 1 // Minimal retries for maximum security
        }
    }
    
    /// Get the timeout duration for authentication attempts
    var authenticationTimeout: TimeInterval {
        switch self {
        case .low:
            return 30.0 // Longer timeout for lower security
        case .medium:
            return 20.0 // Standard timeout
        case .high:
            return 15.0 // Shorter timeout for higher security
        case .maximum:
            return 10.0 // Minimal timeout for maximum security
        }
    }
    
    /// Get the recommended processing time for this security level
    var recommendedProcessingTime: TimeInterval {
        switch self {
        case .low:
            return 1.0 // Faster processing
        case .medium:
            return 1.5 // Balanced processing
        case .high:
            return 2.0 // More thorough processing
        case .maximum:
            return 2.5 // Maximum processing time
        }
    }
    
    /// Check if this security level requires additional validation
    var requiresAdditionalValidation: Bool {
        switch self {
        case .low, .medium:
            return false
        case .high, .maximum:
            return true
        }
    }
    
    /// Get the confidence score adjustment factor for this security level
    var confidenceAdjustmentFactor: Double {
        switch self {
        case .low:
            return 0.9 // Slightly lower confidence requirement
        case .medium:
            return 1.0 // Standard confidence requirement
        case .high:
            return 1.1 // Slightly higher confidence requirement
        case .maximum:
            return 1.2 // Highest confidence requirement
        }
    }
    
    /// Get user-friendly instructions for this security level
    var instructions: String {
        switch self {
        case .low:
            return "Place your finger on the Digital Crown and hold still for 6 seconds. This provides basic security with faster authentication."
        case .medium:
            return "Place your finger on the Digital Crown and hold still for 8 seconds. This provides balanced security and convenience."
        case .high:
            return "Place your finger on the Digital Crown and hold very still for 10 seconds. This provides enhanced security with more precise matching."
        case .maximum:
            return "Place your finger on the Digital Crown and hold extremely still for 12 seconds. This provides maximum security with the strictest pattern matching."
        }
    }
    
    /// Get the recommended next security level for upgrade
    var recommendedUpgrade: SecurityLevel? {
        switch self {
        case .low:
            return .medium
        case .medium:
            return .high
        case .high:
            return .maximum
        case .maximum:
            return nil // Already at maximum
        }
    }
    
    /// Get the recommended previous security level for downgrade
    var recommendedDowngrade: SecurityLevel? {
        switch self {
        case .low:
            return nil // Already at minimum
        case .medium:
            return .low
        case .high:
            return .medium
        case .maximum:
            return .high
        }
    }
    
    /// Calculate the effective threshold considering the confidence adjustment
    var effectiveThreshold: Double {
        return threshold * confidenceAdjustmentFactor
    }
    
    /// Calculate the effective retry threshold considering the confidence adjustment
    var effectiveRetryThreshold: Double {
        return retryThreshold * confidenceAdjustmentFactor
    }
    
    /// Get a summary of this security level's characteristics
    var summary: String {
        return """
        Security Level: \(rawValue)
        Threshold: \(String(format: "%.0f%%", threshold * 100))
        Capture Duration: \(Int(recommendedCaptureDuration))s
        Min Samples: \(minimumSamples)
        Max Retries: \(maxRetryAttempts)
        """
    }
}

// MARK: - SecurityLevel Comparison

extension SecurityLevel: Comparable {
    public static func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
        let order: [SecurityLevel] = [.low, .medium, .high, .maximum]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - SecurityLevel Validation

extension SecurityLevel {
    
    /// Validate if the given confidence score meets this security level's requirements
    func isValidConfidence(_ confidence: Double) -> Bool {
        return confidence >= effectiveThreshold
    }
    
    /// Validate if the given confidence score qualifies for retry
    func qualifiesForRetry(_ confidence: Double) -> Bool {
        return confidence >= effectiveRetryThreshold && confidence < effectiveThreshold
    }
    
    /// Get the authentication result based on confidence score
    func getAuthenticationResult(for confidence: Double, attempt: Int) -> AuthenticationResult {
        if isValidConfidence(confidence) {
            return .approved(confidence: confidence)
        } else if qualifiesForRetry(confidence) && attempt < maxRetryAttempts {
            return .retry(message: "Partial match. Please try again. (\(attempt)/\(maxRetryAttempts))")
        } else {
            return .denied(reason: "Pattern does not match security requirements")
        }
    }
}
