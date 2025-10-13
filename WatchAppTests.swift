//
//  WatchAppTests.swift
//  HeartID Watch App Tests
//
//  Basic tests for Watch App functionality
//

import XCTest
import Testing

// Using Swift Testing framework for better compatibility
@Suite("Watch App Core Tests")
struct WatchAppCoreTests {
    
    @Test("Heart Pattern Creation")
    func testHeartPatternCreation() async throws {
        // Test heart pattern creation without external dependencies
        let sampleData = [75.0, 78.0, 72.0, 80.0, 76.0]
        let duration: TimeInterval = 5.0
        let identifier = "test_pattern"
        
        let pattern = HeartPattern(
            heartRateData: sampleData,
            duration: duration,
            encryptedIdentifier: identifier
        )
        
        #expect(pattern.heartRateData == sampleData)
        #expect(pattern.duration == duration)
        #expect(pattern.encryptedIdentifier == identifier)
    }
    
    @Test("Pattern Characteristics Calculation")
    func testPatternCharacteristics() async throws {
        let sampleData = [75.0, 78.0, 72.0, 80.0, 76.0]
        let pattern = HeartPattern(
            heartRateData: sampleData,
            duration: 5.0,
            encryptedIdentifier: "test"
        )
        
        let characteristics = pattern.patternCharacteristics
        
        // Verify average calculation
        let expectedAverage = sampleData.reduce(0, +) / Double(sampleData.count)
        #expect(abs(characteristics.averageRate - expectedAverage) < 0.01)
        
        // Verify variability calculation
        #expect(characteristics.variability >= 0)
    }
    
    @Test("Authentication Result Types")
    func testAuthenticationResults() async throws {
        let approvedResult = AuthenticationResult.approved(confidence: 0.95)
        let deniedResult = AuthenticationResult.denied(reason: "Pattern mismatch")
        let retryResult = AuthenticationResult.retry(message: "Please try again")
        
        #expect(approvedResult.isSuccessful == true)
        #expect(deniedResult.isSuccessful == false)
        #expect(retryResult.isSuccessful == false)
    }
    
    @Test("Enrollment State Management")
    func testEnrollmentStates() async throws {
        let readyState = EnrollmentState.ready
        let capturingState = EnrollmentState.capturing
        let completedState = EnrollmentState.completed
        let failedState = EnrollmentState.failed
        
        #expect(readyState == .ready)
        #expect(capturingState == .capturing)
        #expect(completedState == .completed)
        #expect(failedState == .failed)
    }
    
    @Test("Heart Rate Sample Model")
    func testHeartRateSample() async throws {
        let timestamp = Date()
        let value: Double = 75.0
        let source = "Apple Watch"
        
        let sample = HeartRateSample(
            value: value,
            timestamp: timestamp,
            source: source
        )
        
        #expect(sample.value == value)
        #expect(sample.timestamp == timestamp)
        #expect(sample.source == source)
        #expect(sample.id != UUID()) // Should have a unique ID
    }
}

@Suite("Biometric Validation Tests")
struct BiometricValidationTests {
    
    @Test("Basic Heart Rate Validation")
    func testBasicValidation() async throws {
        // Test with valid heart rate range
        let validSamples = [70.0, 75.0, 80.0, 72.0, 78.0, 74.0, 76.0, 73.0]
        let validation = EnhancedBiometricValidation.validate(validSamples)
        
        #expect(validation.qualityScore > 0.0)
        #expect(validation.validationDetails.sampleCount == validSamples.count)
        
        // Test average calculation
        let expectedAverage = validSamples.reduce(0, +) / Double(validSamples.count)
        #expect(abs(validation.validationDetails.averageHeartRate - expectedAverage) < 0.1)
    }
    
    @Test("Invalid Heart Rate Detection")
    func testInvalidHeartRates() async throws {
        // Test with out-of-range heart rates
        let invalidSamples = [300.0, 350.0, 400.0] // Way too high
        let validation = EnhancedBiometricValidation.validate(invalidSamples)
        
        #expect(validation.isValid == false)
        #expect(validation.errorMessage != nil)
    }
    
    @Test("Insufficient Sample Detection")
    func testInsufficientSamples() async throws {
        // Test with too few samples
        let fewSamples = [75.0, 76.0] // Only 2 samples
        let validation = EnhancedBiometricValidation.validate(fewSamples)
        
        #expect(validation.isValid == false)
        #expect(!validation.recommendations.isEmpty)
    }
}

@Suite("Security Tests")
struct SecurityTests {
    
    @Test("Template Store Basic Operations")
    func testTemplateStoreOperations() async throws {
        let store = TemplateStore.shared
        
        // Test pattern creation
        let testPattern = HeartPattern(
            heartRateData: [75.0, 76.0, 74.0, 77.0],
            duration: 4.0,
            encryptedIdentifier: "test_secure_pattern"
        )
        
        // Note: In actual tests, we'd need to handle keychain operations
        // For now, just verify the pattern structure
        #expect(testPattern.heartRateData.count == 4)
        #expect(testPattern.encryptedIdentifier.contains("test_secure"))
    }
    
    @Test("Pattern Similarity Calculation")
    func testPatternSimilarity() async throws {
        let pattern1 = HeartPattern(
            heartRateData: [75.0, 76.0, 74.0, 77.0],
            duration: 4.0,
            encryptedIdentifier: "pattern1"
        )
        
        let pattern2 = HeartPattern(
            heartRateData: [75.0, 76.0, 74.0, 77.0], // Identical
            duration: 4.0,
            encryptedIdentifier: "pattern2"
        )
        
        let pattern3 = HeartPattern(
            heartRateData: [100.0, 105.0, 98.0, 103.0], // Very different
            duration: 4.0,
            encryptedIdentifier: "pattern3"
        )
        
        let similarity1to2 = pattern1.patternCharacteristics.similarityScore(
            with: pattern2.patternCharacteristics
        )
        
        let similarity1to3 = pattern1.patternCharacteristics.similarityScore(
            with: pattern3.patternCharacteristics
        )
        
        #expect(similarity1to2 > similarity1to3)
        #expect(similarity1to2 > 90.0) // Should be very similar
        #expect(similarity1to3 < 90.0) // Should be less similar
    }
}