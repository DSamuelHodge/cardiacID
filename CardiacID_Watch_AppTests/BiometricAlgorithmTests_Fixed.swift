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
        // Generate simple test data
        let samples: [Double] = [75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80,
                                 75, 76, 74, 77, 73, 78, 72, 79, 71, 80]
        
        // Calculate HRV features using specific HRVCalculator
        let hrv = HRVCalculator.calculateHRV(samples)
        
        // Validate RMSSD calculation
        XCTAssertGreaterThan(hrv.rmssd, 0.0, "RMSSD should be greater than 0")
        XCTAssertLessThan(hrv.rmssd, 200.0, "RMSSD should be less than 200ms for realistic values")
        
        // Validate pNN50 calculation
        XCTAssertGreaterThanOrEqual(hrv.pnn50, 0.0, "pNN50 should be greater than or equal to 0")
        XCTAssertLessThanOrEqual(hrv.pnn50, 1.0, "pNN50 should be less than or equal to 1.0")
        
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
    
    func testHRVCalculationWithVariousData() {
        // Test with minimal data
        let minimalSamples = Array(repeating: 75.0, count: 60)
        let minimalHRV = HRVCalculator.calculateHRV(minimalSamples)
        
        // Should not crash and should return valid structure
        XCTAssertNotNil(minimalHRV, "HRV calculation should not return nil")
        XCTAssertGreaterThanOrEqual(minimalHRV.rmssd, 0, "RMSSD should be non-negative")
        
        print("✅ Minimal Data HRV Test Results:")
        print("   RMSSD: \(String(format: "%.2f", minimalHRV.rmssd))ms")
        print("   SDNN: \(String(format: "%.2f", minimalHRV.sdnn))ms")
    }
    
    func testHRVCalculationPerformance() {
        // Generate larger dataset for performance testing
        var samples: [Double] = []
        for i in 0..<1000 {
            let baseRate = 75.0
            let variation = sin(Double(i) * 0.1) * 5.0
            samples.append(baseRate + variation + Double.random(in: -2...2))
        }
        
        // Measure performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let hrv = HRVCalculator.calculateHRV(samples)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance should be reasonable for 1000 samples
        XCTAssertLessThan(duration, 0.1, "HRV calculation should complete in less than 0.1 seconds")
        XCTAssertGreaterThan(hrv.rmssd, 0, "HRV should be calculated for large dataset")
        
        print("✅ Performance Test Results:")
        print("   Duration: \(String(format: "%.3f", duration))s")
        print("   Sample Count: \(samples.count)")
        print("   RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
    }
    
    func testHRVFeaturesQualityScore() {
        // Test quality score calculation
        let samples: [Double] = [70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68,
                                 70, 72, 68, 75, 73, 71, 76, 69, 77, 68]
        
        let hrv = HRVCalculator.calculateHRV(samples)
        let qualityScore = hrv.qualityScore
        
        XCTAssertGreaterThanOrEqual(qualityScore, 0.0, "Quality score should be non-negative")
        XCTAssertLessThanOrEqual(qualityScore, 1.0, "Quality score should be at most 1.0")
        
        print("✅ Quality Score Test Results:")
        print("   Quality Score: \(String(format: "%.2f", qualityScore))")
        print("   Health Assessment: \(hrv.healthAssessment.rawValue)")
    }
    
    func testEdgeCases() {
        // Test with insufficient data
        let insufficientSamples = [75.0, 76.0, 74.0]
        let insufficientHRV = HRVCalculator.calculateHRV(insufficientSamples)
        XCTAssertEqual(insufficientHRV.rmssd, 0, "RMSSD should be 0 with insufficient data")
        
        // Test with empty array
        let emptyHRV = HRVCalculator.calculateHRV([])
        XCTAssertEqual(emptyHRV.rmssd, 0, "RMSSD should be 0 with empty data")
        
        // Test with identical values
        let identicalSamples = Array(repeating: 75.0, count: 100)
        let identicalHRV = HRVCalculator.calculateHRV(identicalSamples)
        
        print("✅ Edge Cases Test Results:")
        print("   Insufficient data RMSSD: \(insufficientHRV.rmssd)")
        print("   Empty data RMSSD: \(emptyHRV.rmssd)")
        print("   Identical values RMSSD: \(identicalHRV.rmssd)")
    }
}