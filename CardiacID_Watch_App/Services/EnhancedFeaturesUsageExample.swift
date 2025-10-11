//
//  EnhancedFeaturesUsageExample.swift
//  HeartID Watch App
//
//  Example showing how to use the enhanced biometric testing features
//

import Foundation

/// Example class showing how to use the enhanced features
class EnhancedFeaturesUsageExample {
    
    /// Example: Enhanced enrollment with better validation
    func exampleEnhancedEnrollment() {
        print("🧪 Example: Enhanced Enrollment")
        
        // Generate test data
        let samples = BiometricTestDataGenerator.generateHighQualitySamples()
        print("Generated \(samples.count) high-quality samples")
        
        // Get enhanced validation
        let validation = EnhancedBiometricValidation.validate(samples)
        print("Validation Result:")
        print("  Valid: \(validation.isValid)")
        print("  Quality Score: \(String(format: "%.2f", validation.qualityScore))")
        
        if let hrvFeatures = validation.hrvFeatures {
            print("  HRV Features:")
            print("    RMSSD: \(String(format: "%.2f", hrvFeatures.rmssd))ms")
            print("    pNN50: \(String(format: "%.3f", hrvFeatures.pnn50))")
            print("    SDNN: \(String(format: "%.2f", hrvFeatures.sdnn))ms")
        }
        
        if !validation.recommendations.isEmpty {
            print("  Recommendations: \(validation.recommendations.joined(separator: ", "))")
        }
        
        print("✅ Enhanced enrollment example completed")
    }
    
    /// Example: HRV analysis
    func exampleHRVAnalysis() {
        print("\n🧪 Example: HRV Analysis")
        
        // Generate samples with specific HRV characteristics
        let samples = BiometricTestDataGenerator.generateSamplesWithHRV(
            rmssd: 30.0,
            pnn50: 0.2,
            count: 200
        )
        
        // Calculate HRV features
        let hrv = HRVCalculator.calculateHRV(samples)
        
        print("HRV Analysis Results:")
        print("  RMSSD: \(String(format: "%.2f", hrv.rmssd))ms")
        print("  pNN50: \(String(format: "%.3f", hrv.pnn50))")
        print("  SDNN: \(String(format: "%.2f", hrv.sdnn))ms")
        print("  Mean RR: \(String(format: "%.2f", hrv.meanRR))ms")
        print("  Heart Rate Variability: \(String(format: "%.2f", hrv.heartRateVariability))")
        
        print("✅ HRV analysis example completed")
    }
    
    /// Example: Performance monitoring
    func examplePerformanceMonitoring() {
        print("\n🧪 Example: Performance Monitoring")
        
        let testSizes = [100, 500, 1000]
        
        for size in testSizes {
            let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: size)
            
            let _ = BiometricPerformanceMonitor.measure("HRV Calculation", sampleCount: size) {
                return HRVCalculator.calculateHRV(samples)
            }
            
            let _ = BiometricPerformanceMonitor.measure("Enhanced Validation", sampleCount: size) {
                return EnhancedBiometricValidation.validate(samples)
            }
            
            print("Size \(size) samples processed")
        }
        
        print("✅ Performance monitoring example completed")
    }
    
    /// Example: Mock service usage
    func exampleMockService() {
        print("\n🧪 Example: Mock Service Usage")
        
        let mockService = MockHealthKitService()
        
        // Set authorization
        mockService.setMockAuthorization(true)
        print("Mock authorization set: \(mockService.isAuthorized)")
        
        // Generate mock samples
        mockService.generateMockSamples(count: 150)
        print("Mock samples generated: \(mockService.heartRateSamples.count)")
        
        // Test data access
        Task.detached {
            let dataAccess = await mockService.testHeartRateDataAccess()
            print("Mock data access test: \(dataAccess)")
        }
        
        print("✅ Mock service example completed")
    }
    
    /// Example: Quality assessment
    func exampleQualityAssessment() {
        print("\n🧪 Example: Quality Assessment")
        
        // Test different quality levels
        let highQuality = BiometricTestDataGenerator.generateHighQualitySamples()
        let lowQuality = BiometricTestDataGenerator.generateLowQualitySamples()
        let insufficient = BiometricTestDataGenerator.generateHeartRateSamples(count: 50)
        
        let tests = [
            ("High Quality", highQuality),
            ("Low Quality", lowQuality),
            ("Insufficient", insufficient)
        ]
        
        for (name, samples) in tests {
            let validation = EnhancedBiometricValidation.validate(samples)
            print("\(name) Data:")
            print("  Valid: \(validation.isValid)")
            print("  Quality Score: \(String(format: "%.2f", validation.qualityScore))")
            if let error = validation.errorMessage {
                print("  Error: \(error)")
            }
            if !validation.recommendations.isEmpty {
                print("  Recommendations: \(validation.recommendations.joined(separator: ", "))")
            }
        }
        
        print("✅ Quality assessment example completed")
    }
    
    /// Run all examples
    func runAllExamples() {
        print("🚀 Running Enhanced Features Usage Examples")
        print(String(repeating: "=", count: 60))
        
        exampleEnhancedEnrollment()
        exampleHRVAnalysis()
        examplePerformanceMonitoring()
        exampleMockService()
        exampleQualityAssessment()
        
        print("\n" + String(repeating: "=", count: 60))
        print("🎉 All examples completed successfully!")
        print("📚 The enhanced testing framework is ready for use.")
    }
}
