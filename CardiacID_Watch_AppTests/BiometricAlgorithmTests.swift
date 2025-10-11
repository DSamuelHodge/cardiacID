//
//  BiometricAlgorithmTests.swift
//  HeartID Watch App Tests
//
//  Comprehensive tests for biometric algorithms and HRV calculations
//

import XCTest
@testable import CardiacID_Watch_App

class BiometricAlgorithmTests: XCTestCase {
    
    // MARK: - HRV Calculation Tests
    
    func testHRVCalculation() {
        // Generate test data with known characteristics
        let samples = BiometricTestDataGenerator.generateSamplesWithHRV(
            rmssd: 25.0,
            pnn50: 0.15,
            count: 200
        )
        
        // Calculate HRV features
        let hrv = HRVCalculator.calculateHRV(samples)
        
        // Validate RMSSD calculation
        XCTAssertGreaterThan(hrv.rmssd, 10.0, "RMSSD should be greater than 10ms for healthy variability")
        XCTAssertLessThan(hrv.rmssd, 100.0, "RMSSD should be less than 100ms for realistic values")
        
        // Validate pNN50 calculation
        XCTAssertGreaterThan(hrv.pnn50, 0.0, "pNN50 should be greater than 0")
        XCTAssertLessThan(hrv.pnn50, 1.0, "pNN50 should be less than 1.0")
        
        // Validate SDNN calculation
        XCTAssertGreaterThan(hrv.sdnn, 0.0, "SDNN should be greater than 0")
        
        // Validate mean RR interval
        XCTAssertGreaterThan(hrv.meanRR, 300.0, "Mean RR should be greater than 300ms (200 BPM max)")
        XCTAssertLessThan(hrv.meanRR, 1500.0, "Mean RR should be less than 1500ms (40 BPM min)")
        
        print("✅ HRV Test Results:")
        print("   RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("   pNN50: \(String(format: "%.3f", hrv.pnn50))")
        print("   SDNN: \(String(format: "%.2f", hrv.sdnn))ms")
        print("   Mean RR: \(String(format: "%.2f", hrv.meanRR))ms")
    }
    
    func testHRVCalculationWithHighQualityData() {
        let samples = BiometricTestDataGenerator.generateHighQualitySamples()
        let hrv = HRVCalculator.calculateHRV(samples)
        
        // High quality data should have good HRV characteristics
        XCTAssertGreaterThan(hrv.rmssd, 15.0, "High quality data should have RMSSD > 15ms")
        XCTAssertGreaterThan(hrv.pnn50, 0.05, "High quality data should have pNN50 > 0.05")
        XCTAssertGreaterThan(hrv.sdnn, 20.0, "High quality data should have SDNN > 20ms")
        
        print("✅ High Quality HRV Test Results:")
        print("   RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("   pNN50: \(String(format: "%.3f", hrv.pnn50))")
        print("   SDNN: \(String(format: "%.2f", hrv.sdnn))ms")
    }
    
    func testHRVCalculationWithLowQualityData() {
        let samples = BiometricTestDataGenerator.generateLowQualitySamples()
        let hrv = HRVCalculator.calculateHRV(samples)
        
        // Low quality data should have poor HRV characteristics
        XCTAssertLessThan(hrv.rmssd, 20.0, "Low quality data should have RMSSD < 20ms")
        XCTAssertLessThan(hrv.pnn50, 0.1, "Low quality data should have pNN50 < 0.1")
        
        print("✅ Low Quality HRV Test Results:")
        print("   RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("   pNN50: \(String(format: "%.3f", hrv.pnn50))")
        print("   SDNN: \(String(format: "%.2f", hrv.sdnn))ms")
    }
    
    func testHRVCalculationWithEdgeCases() {
        // Test with minimal data
        let minimalSamples = [75.0, 76.0]
        let minimalHRV = HRVCalculator.calculateHRV(minimalSamples)
        XCTAssertEqual(minimalHRV.rmssd, 0, "RMSSD should be 0 with insufficient data")
        
        // Test with identical values
        let identicalSamples = Array(repeating: 75.0, count: 100)
        let identicalHRV = HRVCalculator.calculateHRV(identicalSamples)
        XCTAssertEqual(identicalHRV.rmssd, 0, "RMSSD should be 0 with identical values")
        XCTAssertEqual(identicalHRV.pnn50, 0, "pNN50 should be 0 with identical values")
        
        // Test with empty array
        let emptyHRV = HRVCalculator.calculateHRV([])
        XCTAssertEqual(emptyHRV.rmssd, 0, "RMSSD should be 0 with empty data")
        
        print("✅ Edge Cases HRV Test Results:")
        print("   Minimal data RMSSD: \(minimalHRV.rmssd)")
        print("   Identical values RMSSD: \(identicalHRV.rmssd)")
        print("   Empty data RMSSD: \(emptyHRV.rmssd)")
    }
    
    // MARK: - Enhanced Biometric Validation Tests
    
    func testEnhancedBiometricValidation() {
        let highQualitySamples = BiometricTestDataGenerator.generateHighQualitySamples()
        let validation = EnhancedBiometricValidation.validate(highQualitySamples)
        
        XCTAssertTrue(validation.isValid, "High quality samples should pass validation")
        XCTAssertGreaterThan(validation.qualityScore, 0.6, "High quality samples should have quality score > 0.6")
        XCTAssertNil(validation.errorMessage, "High quality samples should not have error message")
        XCTAssertNotNil(validation.hrvFeatures, "HRV features should be calculated")
        
        print("✅ Enhanced Validation Test Results:")
        print("   Valid: \(validation.isValid)")
        print("   Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        print("   Error Message: \(validation.errorMessage ?? "None")")
        print("   Recommendations: \(validation.recommendations)")
    }
    
    func testEnhancedBiometricValidationWithLowQuality() {
        let lowQualitySamples = BiometricTestDataGenerator.generateLowQualitySamples()
        let validation = EnhancedBiometricValidation.validate(lowQualitySamples)
        
        XCTAssertFalse(validation.isValid, "Low quality samples should fail validation")
        XCTAssertLessThan(validation.qualityScore, 0.6, "Low quality samples should have quality score < 0.6")
        XCTAssertNotNil(validation.errorMessage, "Low quality samples should have error message")
        XCTAssertFalse(validation.recommendations.isEmpty, "Low quality samples should have recommendations")
        
        print("✅ Low Quality Validation Test Results:")
        print("   Valid: \(validation.isValid)")
        print("   Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        print("   Error Message: \(validation.errorMessage ?? "None")")
        print("   Recommendations: \(validation.recommendations)")
    }
    
    func testEnhancedBiometricValidationWithInsufficientData() {
        let insufficientSamples = BiometricTestDataGenerator.generateHeartRateSamples(count: 50)
        let validation = EnhancedBiometricValidation.validate(insufficientSamples)
        
        XCTAssertFalse(validation.isValid, "Insufficient samples should fail validation")
        XCTAssertEqual(validation.qualityScore, 0.0, "Insufficient samples should have quality score 0")
        XCTAssertNotNil(validation.errorMessage, "Insufficient samples should have error message")
        XCTAssertTrue(validation.recommendations.contains("Increase capture duration"), "Should recommend increasing capture duration")
        
        print("✅ Insufficient Data Validation Test Results:")
        print("   Valid: \(validation.isValid)")
        print("   Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        print("   Error Message: \(validation.errorMessage ?? "None")")
        print("   Recommendations: \(validation.recommendations)")
    }
    
    // MARK: - Performance Tests
    
    func testHRVCalculationPerformance() {
        let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: 1000)
        
        let metrics = BiometricPerformanceMonitor.measure("HRV Calculation", sampleCount: samples.count) {
            return HRVCalculator.calculateHRV(samples)
        }
        
        // Performance should be reasonable for 1000 samples
        XCTAssertLessThan(metrics.duration, 0.1, "HRV calculation should complete in less than 0.1 seconds")
        XCTAssertLessThan(metrics.memoryUsage, 1024 * 1024, "HRV calculation should use less than 1MB memory")
        
        print("✅ Performance Test Results:")
        print("   Duration: \(String(format: "%.3f", metrics.duration))s")
        print("   Memory Usage: \(metrics.memoryUsage) bytes")
        print("   Sample Count: \(metrics.sampleCount)")
    }
    
    func testValidationPerformance() {
        let samples = BiometricTestDataGenerator.generateHighQualitySamples()
        
        let metrics = BiometricPerformanceMonitor.measure("Enhanced Validation", sampleCount: samples.count) {
            return EnhancedBiometricValidation.validate(samples)
        }
        
        // Validation should be fast
        XCTAssertLessThan(metrics.duration, 0.05, "Validation should complete in less than 0.05 seconds")
        
        print("✅ Validation Performance Test Results:")
        print("   Duration: \(String(format: "%.3f", metrics.duration))s")
        print("   Memory Usage: \(metrics.memoryUsage) bytes")
    }
    
    // MARK: - Test Data Generator Tests
    
    func testTestDataGenerator() {
        let samples = BiometricTestDataGenerator.generateHeartRateSamples()
        
        XCTAssertEqual(samples.count, 200, "Default sample count should be 200")
        XCTAssertTrue(samples.allSatisfy { $0 >= 40 && $0 <= 200 }, "All samples should be in realistic heart rate range")
        
        let mean = samples.reduce(0, +) / Double(samples.count)
        XCTAssertGreaterThan(mean, 40, "Mean heart rate should be greater than 40 BPM")
        XCTAssertLessThan(mean, 200, "Mean heart rate should be less than 200 BPM")
        
        print("✅ Test Data Generator Results:")
        print("   Sample Count: \(samples.count)")
        print("   Mean Heart Rate: \(String(format: "%.1f", mean)) BPM")
        print("   Range: \(samples.min() ?? 0) - \(samples.max() ?? 0) BPM")
    }
    
    func testTestDataGeneratorWithCustomParameters() {
        let samples = BiometricTestDataGenerator.generateHeartRateSamples(
            count: 500,
            baseRate: 80.0,
            variability: 10.0,
            noiseLevel: 3.0
        )
        
        XCTAssertEqual(samples.count, 500, "Custom sample count should be respected")
        
        let mean = samples.reduce(0, +) / Double(samples.count)
        XCTAssertGreaterThan(mean, 70, "Mean should be close to base rate")
        XCTAssertLessThan(mean, 90, "Mean should be close to base rate")
        
        print("✅ Custom Test Data Generator Results:")
        print("   Sample Count: \(samples.count)")
        print("   Mean Heart Rate: \(String(format: "%.1f", mean)) BPM")
        print("   Expected Base Rate: 80.0 BPM")
    }
    
    // MARK: - Integration Tests
    
    func testBiometricTemplateCreation() {
        let samples = BiometricTestDataGenerator.generateHighQualitySamples()
        let validation = EnhancedBiometricValidation.validate(samples)
        
        XCTAssertTrue(validation.isValid, "Samples should be valid for template creation")
        
        if let hrvFeatures = validation.hrvFeatures {
            // Test that HRV features are reasonable for template creation
            XCTAssertGreaterThan(hrvFeatures.rmssd, 10.0, "RMSSD should be sufficient for template creation")
            XCTAssertGreaterThan(hrvFeatures.sdnn, 15.0, "SDNN should be sufficient for template creation")
            
            print("✅ Biometric Template Creation Test Results:")
            print("   RMSSD: \(String(format: "%.2f", hrvFeatures.rmssd))ms")
            print("   SDNN: \(String(format: "%.2f", hrvFeatures.sdnn))ms")
            print("   Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        }
    }
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        BiometricPerformanceMonitor.clearMetrics()
    }
    
    override func tearDown() {
        // Print performance summary
        let metrics = BiometricPerformanceMonitor.getMetrics()
        if !metrics.isEmpty {
            print("\n📊 Performance Summary:")
            for metric in metrics {
                print("   \(metric.operationName): \(String(format: "%.3f", metric.duration))s")
            }
        }
        
        super.tearDown()
    }
}
