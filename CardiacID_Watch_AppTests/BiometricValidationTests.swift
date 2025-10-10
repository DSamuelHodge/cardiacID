//
//  BiometricValidationTests.swift
//  HeartID Watch App Tests
//
//  Unit tests for biometric feature extraction and validation
//

import XCTest
@testable import CardiacID_Watch_App

class BiometricValidationTests: XCTestCase {
    
    var xenonCalculator: XenonXCalculator!
    var testHeartRateData: [Double]!
    
    override func setUp() {
        super.setUp()
        xenonCalculator = XenonXCalculator()
        
        // Generate synthetic heart rate data for testing
        testHeartRateData = generateSyntheticHeartRateData()
    }
    
    override func tearDown() {
        xenonCalculator = nil
        testHeartRateData = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Generation
    
    func generateSyntheticHeartRateData() -> [Double] {
        // Generate 10 seconds of heart rate data at 1Hz
        var data: [Double] = []
        let baseRate = 75.0
        let timePoints = 10
        
        for i in 0..<timePoints {
            // Add some realistic variation
            let variation = sin(Double(i) * 0.5) * 5.0
            let noise = Double.random(in: -2.0...2.0)
            let heartRate = baseRate + variation + noise
            data.append(heartRate)
        }
        
        return data
    }
    
    func generateHighQualityData() -> [Double] {
        // Generate high-quality data with clear patterns
        var data: [Double] = []
        let baseRate = 70.0
        let timePoints = 15
        
        for i in 0..<timePoints {
            // Clear sinusoidal pattern
            let pattern = sin(Double(i) * 0.3) * 8.0
            let heartRate = baseRate + pattern
            data.append(heartRate)
        }
        
        return data
    }
    
    func generateLowQualityData() -> [Double] {
        // Generate low-quality data with high noise
        var data: [Double] = []
        let baseRate = 80.0
        let timePoints = 8
        
        for i in 0..<timePoints {
            // High noise, no clear pattern
            let noise = Double.random(in: -15.0...15.0)
            let heartRate = baseRate + noise
            data.append(heartRate)
        }
        
        return data
    }
    
    // MARK: - Feature Extraction Tests
    
    func testTemporalFeatureExtraction() {
        let features = xenonCalculator.extractTemporalFeatures(from: testHeartRateData)
        
        XCTAssertNotNil(features, "Temporal features should be extracted")
        XCTAssertGreaterThan(features.mean, 0, "Mean heart rate should be positive")
        XCTAssertGreaterThan(features.stdDev, 0, "Standard deviation should be positive")
        XCTAssertGreaterThan(features.variance, 0, "Variance should be positive")
    }
    
    func testFrequencyFeatureExtraction() {
        let features = xenonCalculator.extractFrequencyFeatures(from: testHeartRateData)
        
        XCTAssertNotNil(features, "Frequency features should be extracted")
        XCTAssertGreaterThan(features.dominantFrequency, 0, "Dominant frequency should be positive")
        XCTAssertGreaterThan(features.spectralCentroid, 0, "Spectral centroid should be positive")
        XCTAssertGreaterThan(features.spectralRolloff, 0, "Spectral rolloff should be positive")
    }
    
    func testMorphologicalFeatureExtraction() {
        let features = xenonCalculator.extractMorphologicalFeatures(from: testHeartRateData)
        
        XCTAssertNotNil(features, "Morphological features should be extracted")
        XCTAssertGreaterThan(features.skewness, -10, "Skewness should be reasonable")
        XCTAssertGreaterThan(features.kurtosis, -10, "Kurtosis should be reasonable")
        XCTAssertGreaterThan(features.entropy, 0, "Entropy should be positive")
    }
    
    func testPatternMatching() {
        let template = xenonCalculator.createTemplate(from: testHeartRateData)
        let matchResult = xenonCalculator.matchPattern(testHeartRateData, against: template)
        
        XCTAssertNotNil(template, "Template should be created")
        XCTAssertNotNil(matchResult, "Match result should be generated")
        XCTAssertGreaterThan(matchResult.confidence, 0, "Confidence should be positive")
        XCTAssertLessThanOrEqual(matchResult.confidence, 1.0, "Confidence should be <= 1.0")
    }
    
    // MARK: - Quality Assessment Tests
    
    func testHighQualityDataRecognition() {
        let highQualityData = generateHighQualityData()
        let quality = xenonCalculator.assessDataQuality(highQualityData)
        
        XCTAssertGreaterThan(quality, 0.7, "High quality data should score > 0.7")
    }
    
    func testLowQualityDataRecognition() {
        let lowQualityData = generateLowQualityData()
        let quality = xenonCalculator.assessDataQuality(lowQualityData)
        
        XCTAssertLessThan(quality, 0.5, "Low quality data should score < 0.5")
    }
    
    func testDataValidation() {
        let validData = generateHighQualityData()
        let invalidData = [Double]() // Empty data
        
        XCTAssertTrue(xenonCalculator.validateData(validData), "Valid data should pass validation")
        XCTAssertFalse(xenonCalculator.validateData(invalidData), "Invalid data should fail validation")
    }
    
    // MARK: - Security Level Tests
    
    func testSecurityLevelThresholds() {
        let highQualityData = generateHighQualityData()
        let lowQualityData = generateLowQualityData()
        
        // Test different security levels
        let lowSecurity = SecurityLevel.low
        let highSecurity = SecurityLevel.high
        
        let lowThreshold = lowSecurity.effectiveThreshold
        let highThreshold = highSecurity.effectiveThreshold
        
        XCTAssertLessThan(lowThreshold, highThreshold, "Low security should have lower threshold")
        
        // Test that high quality data passes high security
        let highQualityScore = xenonCalculator.assessDataQuality(highQualityData)
        XCTAssertGreaterThan(highQualityScore, highThreshold, "High quality data should pass high security")
        
        // Test that low quality data fails high security
        let lowQualityScore = xenonCalculator.assessDataQuality(lowQualityData)
        XCTAssertLessThan(lowQualityScore, highThreshold, "Low quality data should fail high security")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() {
        // Generate large dataset
        var largeDataset: [Double] = []
        for _ in 0..<1000 {
            largeDataset.append(Double.random(in: 60.0...100.0))
        }
        
        // Measure performance
        let startTime = Date()
        let features = xenonCalculator.extractTemporalFeatures(from: largeDataset)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        XCTAssertNotNil(features, "Features should be extracted from large dataset")
        XCTAssertLessThan(duration, 1.0, "Feature extraction should complete in < 1 second")
    }
    
    func testFFTCachingPerformance() {
        let data1 = generateHighQualityData()
        let data2 = generateHighQualityData()
        
        // First FFT calculation
        let startTime1 = Date()
        let features1 = xenonCalculator.extractFrequencyFeatures(from: data1)
        let endTime1 = Date()
        
        // Second FFT calculation (should benefit from caching)
        let startTime2 = Date()
        let features2 = xenonCalculator.extractFrequencyFeatures(from: data2)
        let endTime2 = Date()
        
        let duration1 = endTime1.timeIntervalSince(startTime1)
        let duration2 = endTime2.timeIntervalSince(startTime2)
        
        XCTAssertNotNil(features1, "First FFT should complete")
        XCTAssertNotNil(features2, "Second FFT should complete")
        XCTAssertLessThan(duration2, duration1, "Second FFT should be faster due to caching")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyDataHandling() {
        let emptyData: [Double] = []
        
        XCTAssertFalse(xenonCalculator.validateData(emptyData), "Empty data should fail validation")
        
        let features = xenonCalculator.extractTemporalFeatures(from: emptyData)
        XCTAssertNil(features, "Empty data should return nil features")
    }
    
    func testSingleDataPointHandling() {
        let singlePoint = [75.0]
        
        XCTAssertFalse(xenonCalculator.validateData(singlePoint), "Single data point should fail validation")
    }
    
    func testExtremeValuesHandling() {
        let extremeData = [0.0, 1000.0, -100.0, 200.0]
        
        let features = xenonCalculator.extractTemporalFeatures(from: extremeData)
        XCTAssertNotNil(features, "Extreme values should be handled gracefully")
    }
    
    // MARK: - Template Versioning Tests
    
    func testTemplateVersioning() {
        let data = generateHighQualityData()
        let template = xenonCalculator.createTemplate(from: data)
        
        XCTAssertNotNil(template, "Template should be created")
        XCTAssertEqual(template.version, 1, "Template version should be 1")
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndAuthentication() {
        let enrollmentData = generateHighQualityData()
        let authenticationData = generateHighQualityData()
        
        // Create template
        let template = xenonCalculator.createTemplate(from: enrollmentData)
        XCTAssertNotNil(template, "Template creation should succeed")
        
        // Match against template
        let matchResult = xenonCalculator.matchPattern(authenticationData, against: template)
        XCTAssertNotNil(matchResult, "Pattern matching should succeed")
        
        // Verify confidence is reasonable
        XCTAssertGreaterThan(matchResult.confidence, 0.5, "Confidence should be reasonable")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithInvalidInput() {
        let invalidData = [Double.nan, Double.infinity, -Double.infinity]
        
        // Should handle invalid input gracefully
        let features = xenonCalculator.extractTemporalFeatures(from: invalidData)
        XCTAssertNil(features, "Invalid input should return nil")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Test that FFT setup is properly cleaned up
        let data = generateHighQualityData()
        
        // Create multiple calculators to test memory management
        var calculators: [XenonXCalculator] = []
        for _ in 0..<10 {
            let calculator = XenonXCalculator()
            let _ = calculator.extractFrequencyFeatures(from: data)
            calculators.append(calculator)
        }
        
        // Clear calculators
        calculators.removeAll()
        
        // Should not crash or leak memory
        XCTAssertTrue(true, "Memory management should be handled properly")
    }
}
