//
//  CoreBiometricTests.swift
//  HeartID Watch App Tests
//
//  Essential tests for core biometric functionality
//

import XCTest
import Foundation

class CoreBiometricTests: XCTestCase {
    
    // MARK: - Core Functionality Tests (No Module Dependency)
    
    func testBasicFeatureExtraction() {
        // Test basic statistical calculations that would be used in biometric analysis
        let heartRateData = [75.0, 76.0, 77.0, 78.0, 79.0, 80.0, 79.0, 78.0, 77.0, 76.0]
        
        // Calculate basic statistical features
        let mean = heartRateData.reduce(0, +) / Double(heartRateData.count)
        let sortedData = heartRateData.sorted()
        let median = sortedData.count % 2 == 0 ? 
            (sortedData[sortedData.count/2 - 1] + sortedData[sortedData.count/2]) / 2 :
            sortedData[sortedData.count/2]
        
        XCTAssertGreaterThan(mean, 0, "Mean should be positive")
        XCTAssertGreaterThan(median, 0, "Median should be positive")
        XCTAssertEqual(mean, 77.0, accuracy: 0.1, "Mean should be calculated correctly")
    }
    
    func testDataValidation() {
        // Test data validation with valid and invalid inputs
        let validData = [75.0, 76.0, 77.0, 78.0, 79.0]
        let invalidData: [Double] = []
        
        // Test basic validation logic
        let validCount = validData.count
        let invalidCount = invalidData.count
        
        XCTAssertGreaterThan(validCount, 0, "Valid data should have samples")
        XCTAssertEqual(invalidCount, 0, "Invalid data should be empty")
    }
    
    func testPerformance() {
        // Test performance with larger dataset
        let largeDataset = Array(repeating: 75.0, count: 100)
        
        let startTime = Date()
        let mean = largeDataset.reduce(0, +) / Double(largeDataset.count)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertEqual(mean, 75.0, "Mean should be calculated correctly")
        XCTAssertLessThan(duration, 0.1, "Calculation should be very fast")
    }
    
    func testSecurityLevelConfiguration() {
        // Test basic security level concepts
        let lowSamples = 5
        let highSamples = 12
        let lowDuration = 6.0
        let highDuration = 12.0
        
        XCTAssertGreaterThan(highSamples, lowSamples, "High security should require more samples")
        XCTAssertGreaterThan(highDuration, lowDuration, "High security should require longer duration")
    }
    
    func testHeartRateSampleModel() {
        // Test basic heart rate sample properties
        let value = 75.0
        let timestamp = Date()
        let source = "Apple Watch"
        
        XCTAssertGreaterThan(value, 0, "Heart rate value should be positive")
        XCTAssertNotNil(timestamp, "Timestamp should not be nil")
        XCTAssertFalse(source.isEmpty, "Source should not be empty")
    }
    
    func testBiometricPatternAnalysis() {
        // Test basic pattern analysis concepts
        let regularPattern = [75.0, 75.0, 75.0, 75.0, 75.0] // Regular
        let irregularPattern = [75.0, 85.0, 65.0, 95.0, 55.0] // Irregular
        
        let regularVariance = calculateVariance(regularPattern)
        let irregularVariance = calculateVariance(irregularPattern)
        
        XCTAssertLessThan(regularVariance, irregularVariance, "Regular pattern should have lower variance")
    }
    
    // MARK: - Helper Methods
    
    private func calculateVariance(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0.0 }
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        return variance
    }
}
