//
//  EnhancedAuthenticationService.swift
//  HeartID Watch App
//
//  Enhanced authentication service with improved validation and HRV analysis
//

import Foundation
import Combine

/// Enhanced authentication service that extends the existing functionality
class EnhancedAuthenticationService: ObservableObject {
    
    private let baseAuthService: AuthenticationService
    private let enhancedValidator = EnhancedBiometricValidation()
    
    @Published var isUserEnrolled = false
    @Published var isAuthenticated = false
    @Published var lastAuthenticationResult: AuthenticationResult?
    @Published var errorMessage: String?
    
    init(baseAuthService: AuthenticationService) {
        self.baseAuthService = baseAuthService
        
        // Sync with base service
        self.isUserEnrolled = baseAuthService.isUserEnrolled
        self.isAuthenticated = baseAuthService.isAuthenticated
        self.lastAuthenticationResult = baseAuthService.lastAuthenticationResult
        self.errorMessage = baseAuthService.errorMessage
    }
    
    /// Enhanced enrollment with improved validation
    func completeEnrollment(with heartRateValues: [Double]) -> Bool {
        print("🔄 Enhanced enrollment processing with \(heartRateValues.count) samples")
        
        // Use enhanced validation
        let validation = EnhancedBiometricValidation.validate(heartRateValues)
        
        guard validation.isValid else {
            print("❌ Enhanced enrollment validation failed: \(validation.errorMessage ?? "Unknown error")")
            if !validation.recommendations.isEmpty {
                print("📋 Recommendations: \(validation.recommendations.joined(separator: ", "))")
            }
            self.errorMessage = validation.errorMessage
            return false
        }
        
        print("✅ Enhanced enrollment validation passed with quality score: \(validation.qualityScore)")
        
        // Log HRV features
        if let hrvFeatures = validation.hrvFeatures {
            print("📊 HRV Features - RMSSD: \(String(format: "%.2f", hrvFeatures.rmssd))ms, pNN50: \(String(format: "%.3f", hrvFeatures.pnn50))")
        }
        
        // Use base service for actual enrollment
        let success = baseAuthService.completeEnrollment(with: heartRateValues)
        
        if success {
            DispatchQueue.main.async {
                self.isUserEnrolled = true
            }
            print("✅ Enhanced enrollment completed successfully")
        }
        
        return success
    }
    
    /// Enhanced authentication with improved validation
    func completeAuthentication(with heartRateValues: [Double]) -> AuthenticationResult {
        print("🔄 Enhanced authentication processing with \(heartRateValues.count) samples")
        
        // Use enhanced validation
        let validation = EnhancedBiometricValidation.validate(heartRateValues)
        
        guard validation.isValid else {
            print("❌ Enhanced authentication validation failed: \(validation.errorMessage ?? "Unknown error")")
            if !validation.recommendations.isEmpty {
                print("📋 Recommendations: \(validation.recommendations.joined(separator: ", "))")
            }
            return .retry(message: validation.errorMessage ?? "Please try again")
        }
        
        print("✅ Enhanced authentication validation passed with quality score: \(validation.qualityScore)")
        
        // Log HRV features
        if let hrvFeatures = validation.hrvFeatures {
            print("📊 HRV Features - RMSSD: \(String(format: "%.2f", hrvFeatures.rmssd))ms, pNN50: \(String(format: "%.3f", hrvFeatures.pnn50))")
        }
        
        // Use base service for actual authentication
        let result = baseAuthService.completeAuthentication(with: heartRateValues)
        
        DispatchQueue.main.async {
            self.lastAuthenticationResult = result
            self.isAuthenticated = result.isSuccessful
        }
        
        return result
    }
    
    /// Get detailed validation report
    func getValidationReport(for samples: [Double]) -> EnhancedBiometricValidation.ValidationResult {
        return EnhancedBiometricValidation.validate(samples)
    }
    
    /// Get HRV analysis
    func getHRVAnalysis(for samples: [Double]) -> HRVCalculator.HRVFeatures {
        return HRVCalculator.calculateHRV(samples)
    }
    
    /// Performance test for biometric operations
    func runPerformanceTest(with samples: [Double]) -> BiometricPerformanceMonitor.PerformanceMetrics {
        // Clear previous metrics to get clean measurement
        BiometricPerformanceMonitor.clearMetrics()
        
        // Execute the operation being measured
        let _ = BiometricPerformanceMonitor.measure("Enhanced Authentication", sampleCount: samples.count) {
            let validation = EnhancedBiometricValidation.validate(samples)
            let hrv = HRVCalculator.calculateHRV(samples)
            // Return a meaningful result for performance measurement
            return validation.isValid && hrv.rmssd > 0
        }
        
        // Return the performance metrics
        return BiometricPerformanceMonitor.getMetrics().last!
    }
}

/// Extension to provide easy access to enhanced features
extension AuthenticationService {
    
    /// Get enhanced validation for samples
    func getEnhancedValidation(for samples: [Double]) -> EnhancedBiometricValidation.ValidationResult {
        return EnhancedBiometricValidation.validate(samples)
    }
    
    /// Get HRV analysis for samples
    func getHRVAnalysis(for samples: [Double]) -> HRVCalculator.HRVFeatures {
        return HRVCalculator.calculateHRV(samples)
    }
    
    /// Run performance benchmark
    func runPerformanceBenchmark(with samples: [Double]) -> BiometricPerformanceMonitor.PerformanceMetrics {
        // Clear previous metrics to get clean measurement
        BiometricPerformanceMonitor.clearMetrics()
        
        // Execute the operation being measured
        let _ = BiometricPerformanceMonitor.measure("Authentication Service", sampleCount: samples.count) {
            let validation = EnhancedBiometricValidation.validate(samples)
            let hrv = HRVCalculator.calculateHRV(samples)
            // Return a meaningful result for performance measurement
            return validation.isValid && hrv.rmssd > 0
        }
        
        // Return the performance metrics
        return BiometricPerformanceMonitor.getMetrics().last!
    }
}

