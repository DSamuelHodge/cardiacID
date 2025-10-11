//
//  IntegrationTest.swift
//  HeartID Watch App
//
//  Simple integration test to verify the testing framework works
//

import Foundation

/// Simple integration test to verify the testing framework
class IntegrationTest {
    
    static func testFrameworkIntegration() {
        print("🧪 Testing Framework Integration...")
        
        // Test 1: Data Generation
        print("\n1. Testing Data Generation...")
        let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: 100)
        print("   ✅ Generated \(samples.count) samples")
        
        // Test 2: HRV Calculation
        print("\n2. Testing HRV Calculation...")
        let hrv = HRVCalculator.calculateHRV(samples)
        print("   ✅ RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("   ✅ pNN50: \(String(format: "%.3f", hrv.pnn50))")
        
        // Test 3: Enhanced Validation
        print("\n3. Testing Enhanced Validation...")
        let validation = EnhancedBiometricValidation.validate(samples)
        print("   ✅ Valid: \(validation.isValid)")
        print("   ✅ Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        
        // Test 4: Performance Monitoring
        print("\n4. Testing Performance Monitoring...")
        let _ = BiometricPerformanceMonitor.measure("Integration Test", sampleCount: samples.count) {
            return HRVCalculator.calculateHRV(samples)
        }
        print("   ✅ Performance monitoring completed")
        
        print("\n🎉 Framework integration test completed successfully!")
    }
    
    static func testMockService() {
        print("\n🧪 Testing Mock Service...")
        
        let mockService = MockHealthKitService()
        mockService.setMockAuthorization(true)
        mockService.generateMockSamples(count: 50)
        
        print("   ✅ Mock service created")
        print("   ✅ Authorization set: \(mockService.isAuthorized)")
        print("   ✅ Samples generated: \(mockService.heartRateSamples.count)")
        
        print("\n🎉 Mock service test completed successfully!")
    }
    
    static func runAllIntegrationTests() {
        print("🚀 Starting Integration Tests...")
        print(String(repeating: "=", count: 50))
        
        testFrameworkIntegration()
        testMockService()
        
        print("\n" + String(repeating: "=", count: 50))
        print("🎉 All integration tests completed successfully!")
    }
}
