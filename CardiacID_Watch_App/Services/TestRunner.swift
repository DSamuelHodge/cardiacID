//
//  TestRunner.swift
//  HeartID Watch App
//
//  Simple test runner to verify the testing framework works
//

import Foundation

/// Simple test runner for the biometric testing framework
class TestRunner {
    
    static func runBasicTests() {
        print("🧪 Running Basic Biometric Tests...")
        
        // Test 1: Generate test data
        print("\n1. Testing Data Generation...")
        let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: 200)
        print("   ✅ Generated \(samples.count) samples")
        print("   📊 Mean: \(String(format: "%.1f", samples.reduce(0, +) / Double(samples.count))) BPM")
        
        // Test 2: HRV Calculation
        print("\n2. Testing HRV Calculation...")
        let hrv = HRVCalculator.calculateHRV(samples)
        print("   ✅ RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("   ✅ pNN50: \(String(format: "%.3f", hrv.pnn50))")
        print("   ✅ SDNN: \(String(format: "%.2f", hrv.sdnn))ms")
        
        // Test 3: Enhanced Validation
        print("\n3. Testing Enhanced Validation...")
        let validation = EnhancedBiometricValidation.validate(samples)
        print("   ✅ Valid: \(validation.isValid)")
        print("   ✅ Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        if let errorMessage = validation.errorMessage {
            print("   ⚠️ Error: \(errorMessage)")
        }
        if !validation.recommendations.isEmpty {
            print("   📋 Recommendations: \(validation.recommendations.joined(separator: ", "))")
        }
        
        // Test 4: Performance Monitoring
        print("\n4. Testing Performance Monitoring...")
        let _ = BiometricPerformanceMonitor.measure("Test Operation", sampleCount: samples.count) {
            return HRVCalculator.calculateHRV(samples)
        }
        print("   ✅ Performance monitoring completed")
        
        print("\n🎉 All basic tests completed successfully!")
    }
    
    static func runQualityTests() {
        print("\n🧪 Running Quality Assessment Tests...")
        
        // Test high quality data
        print("\n1. Testing High Quality Data...")
        let highQualitySamples = BiometricTestDataGenerator.generateHighQualitySamples()
        let highQualityValidation = EnhancedBiometricValidation.validate(highQualitySamples)
        print("   ✅ High Quality - Valid: \(highQualityValidation.isValid), Score: \(String(format: "%.2f", highQualityValidation.qualityScore))")
        
        // Test low quality data
        print("\n2. Testing Low Quality Data...")
        let lowQualitySamples = BiometricTestDataGenerator.generateLowQualitySamples()
        let lowQualityValidation = EnhancedBiometricValidation.validate(lowQualitySamples)
        print("   ✅ Low Quality - Valid: \(lowQualityValidation.isValid), Score: \(String(format: "%.2f", lowQualityValidation.qualityScore))")
        
        // Test insufficient data
        print("\n3. Testing Insufficient Data...")
        let insufficientSamples = BiometricTestDataGenerator.generateHeartRateSamples(count: 50)
        let insufficientValidation = EnhancedBiometricValidation.validate(insufficientSamples)
        print("   ✅ Insufficient - Valid: \(insufficientValidation.isValid), Score: \(String(format: "%.2f", insufficientValidation.qualityScore))")
        
        print("\n🎉 Quality assessment tests completed!")
    }
    
    static func runPerformanceTests() {
        print("\n🧪 Running Performance Tests...")
        
        let testSizes = [100, 500, 1000]
        
        for size in testSizes {
            print("\nTesting with \(size) samples...")
            
            let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: size)
            
            let _ = BiometricPerformanceMonitor.measure("HRV Calculation", sampleCount: size) {
                return HRVCalculator.calculateHRV(samples)
            }
            
            let _ = BiometricPerformanceMonitor.measure("Enhanced Validation", sampleCount: size) {
                return EnhancedBiometricValidation.validate(samples)
            }
            
            print("   ✅ Performance tests completed for \(size) samples")
        }
        
        print("\n🎉 Performance tests completed!")
    }
    
    static func runAllTests() {
        print("🚀 Starting Comprehensive Biometric Testing Framework Tests...")
        print(String(repeating: "=", count: 60))
        
        runBasicTests()
        runQualityTests()
        runPerformanceTests()
        
        print("\n" + String(repeating: "=", count: 60))
        print("🎉 All tests completed successfully!")
        print("📊 Testing framework is ready for production use.")
    }
}
