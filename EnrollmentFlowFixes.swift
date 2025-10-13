//
//  EnrollmentFlowFixes.swift
//  HeartID Watch App
//
//  Critical fixes for enrollment and authentication flows
//

import Foundation
import SwiftUI

// MARK: - Enrollment Flow Testing and Fixes

extension AuthenticationService {
    
    /// Enhanced enrollment method with comprehensive validation
    func performEnrollment(with heartRateData: [Double]) async -> EnrollmentTestResult {
        debugLog.auth("🔄 Starting enhanced enrollment with \(heartRateData.count) samples")
        
        // Step 1: Validate input data
        guard !heartRateData.isEmpty else {
            return EnrollmentTestResult(success: false, error: "No heart rate data provided", confidence: 0.0)
        }
        
        guard heartRateData.count >= 100 else {
            return EnrollmentTestResult(success: false, error: "Insufficient data: need at least 100 samples", confidence: 0.0)
        }
        
        // Step 2: Enhanced validation
        let validation = EnhancedBiometricValidation.validate(heartRateData)
        
        guard validation.isValid else {
            let error = validation.errorMessage ?? "Validation failed"
            return EnrollmentTestResult(success: false, error: error, confidence: validation.qualityScore)
        }
        
        // Step 3: Create biometric template
        let template = BiometricTemplate(heartRatePattern: heartRateData)
        
        // Step 4: Create user profile
        let profile = UserProfile(template: template)
        
        // Step 5: Save to secure storage
        guard let dataManager = dataManager else {
            return EnrollmentTestResult(success: false, error: "DataManager not available", confidence: 0.0)
        }
        
        let saveSuccess = dataManager.saveUserProfile(profile)
        
        if saveSuccess {
            // Update state
            DispatchQueue.main.async {
                self.isUserEnrolled = true
            }
            
            debugLog.auth("✅ Enhanced enrollment completed successfully")
            return EnrollmentTestResult(success: true, error: nil, confidence: validation.qualityScore)
        } else {
            return EnrollmentTestResult(success: false, error: "Failed to save enrollment data", confidence: validation.qualityScore)
        }
    }
    
    /// Enhanced authentication method with detailed results
    func performAuthentication(with heartRateData: [Double]) async -> AuthenticationTestResult {
        debugLog.auth("🔄 Starting enhanced authentication with \(heartRateData.count) samples")
        
        // Get stored profile
        guard let dataManager = dataManager else {
            return AuthenticationTestResult(result: .error(message: "DataManager not available"), confidence: 0.0, processingTime: 0.0)
        }
        
        guard let profile = dataManager.getUserProfile() else {
            return AuthenticationTestResult(result: .error(message: "No enrollment found"), confidence: 0.0, processingTime: 0.0)
        }
        
        let startTime = Date()
        
        // Validate capture quality
        let validation = EnhancedBiometricValidation.validate(heartRateData)
        guard validation.isValid else {
            let processingTime = Date().timeIntervalSince(startTime)
            let message = validation.errorMessage ?? "Please try again"
            return AuthenticationTestResult(result: .retry(message: message), confidence: 0.0, processingTime: processingTime)
        }
        
        // Compare patterns
        let storedPattern = profile.biometricTemplate.heartRatePattern
        let confidence = comparePatterns(stored: storedPattern, captured: heartRateData)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Enhanced decision logic
        let result: AuthenticationResult
        if confidence >= 0.85 {
            dataManager.updateLastAuthenticationDate()
            result = .approved(confidence: confidence)
        } else if confidence >= 0.65 {
            result = .retry(message: "Partial match detected. Please try again.")
        } else {
            result = .denied(reason: "Pattern does not match enrolled template")
        }
        
        debugLog.auth("✅ Enhanced authentication completed - Confidence: \(String(format: "%.1f%%", confidence * 100))")
        
        return AuthenticationTestResult(result: result, confidence: confidence, processingTime: processingTime)
    }
}

// MARK: - Test Result Types

struct EnrollmentTestResult {
    let success: Bool
    let error: String?
    let confidence: Double
    let timestamp: Date = Date()
}

struct AuthenticationTestResult {
    let result: AuthenticationResult
    let confidence: Double
    let processingTime: TimeInterval
    let timestamp: Date = Date()
}

// MARK: - HealthKit Service Flow Fixes

extension HealthKitService {
    
    /// Enhanced heart rate capture with better error handling
    func captureHeartRateForEnrollment(duration: TimeInterval = 10.0) async -> HeartRateCaptureResult {
        debugLog.health("🫀 Starting enhanced heart rate capture for enrollment")
        
        // Pre-flight checks
        guard HKHealthStore.isHealthDataAvailable() else {
            return HeartRateCaptureResult(success: false, data: [], error: "HealthKit not available", quality: 0.0)
        }
        
        guard isAuthorized else {
            return HeartRateCaptureResult(success: false, data: [], error: "HealthKit not authorized", quality: 0.0)
        }
        
        // Start capture
        let result = await startHeartRateCapture(duration: duration)
        
        switch result {
        case .success(let data):
            // Assess quality
            let quality = assessCaptureQuality(data)
            
            if quality >= 0.7 {
                debugLog.health("✅ High quality capture completed - \(data.count) samples, quality: \(String(format: "%.1f%%", quality * 100))")
                return HeartRateCaptureResult(success: true, data: data, error: nil, quality: quality)
            } else {
                debugLog.health("⚠️ Low quality capture - Quality: \(String(format: "%.1f%%", quality * 100))")
                return HeartRateCaptureResult(success: false, data: data, error: "Low quality capture. Please ensure good sensor contact.", quality: quality)
            }
            
        case .failure(let error):
            debugLog.health("❌ Heart rate capture failed: \(error.localizedDescription)")
            return HeartRateCaptureResult(success: false, data: [], error: error.localizedDescription, quality: 0.0)
        }
    }
    
    /// Assess the quality of captured heart rate data
    private func assessCaptureQuality(_ data: [Double]) -> Double {
        guard !data.isEmpty else { return 0.0 }
        
        // Quality factors
        let countScore = min(Double(data.count) / 300.0, 1.0) // Ideal: 300+ samples
        
        let mean = data.reduce(0, +) / Double(data.count)
        let rangeScore = (mean >= 50 && mean <= 150) ? 1.0 : 0.5
        
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let stdDev = sqrt(variance)
        let variabilityScore = (stdDev > 2 && stdDev < 25) ? 1.0 : 0.5
        
        // Overall quality score
        return (countScore * 0.4) + (rangeScore * 0.3) + (variabilityScore * 0.3)
    }
}

// MARK: - Heart Rate Capture Result

struct HeartRateCaptureResult {
    let success: Bool
    let data: [Double]
    let error: String?
    let quality: Double
    let timestamp: Date = Date()
}

// MARK: - Data Manager Flow Fixes

extension DataManager {
    
    /// Enhanced user profile saving with validation
    func saveUserProfileSafely(_ profile: UserProfile) -> DataManagerResult {
        debugLog.data("💾 Starting enhanced user profile save")
        
        do {
            // Validate profile data
            guard !profile.biometricTemplate.heartRatePattern.isEmpty else {
                return DataManagerResult(success: false, error: "Empty biometric template")
            }
            
            // Check storage space (simplified check)
            guard profile.biometricTemplate.heartRatePattern.count < 10000 else {
                return DataManagerResult(success: false, error: "Biometric template too large")
            }
            
            // Attempt save
            let success = saveUserProfile(profile)
            
            if success {
                debugLog.data("✅ User profile saved successfully")
                return DataManagerResult(success: true, error: nil)
            } else {
                return DataManagerResult(success: false, error: "Save operation failed")
            }
            
        } catch {
            debugLog.data("❌ User profile save error: \(error.localizedDescription)")
            return DataManagerResult(success: false, error: error.localizedDescription)
        }
    }
    
    /// Enhanced user profile retrieval with validation
    func getUserProfileSafely() -> (profile: UserProfile?, error: String?) {
        debugLog.data("🔍 Starting enhanced user profile retrieval")
        
        do {
            if let profile = getUserProfile() {
                // Validate retrieved profile
                guard !profile.biometricTemplate.heartRatePattern.isEmpty else {
                    return (nil, "Corrupted biometric template")
                }
                
                debugLog.data("✅ User profile retrieved successfully")
                return (profile, nil)
            } else {
                return (nil, "No profile found")
            }
            
        } catch {
            debugLog.data("❌ User profile retrieval error: \(error.localizedDescription)")
            return (nil, error.localizedDescription)
        }
    }
}

// MARK: - Data Manager Result

struct DataManagerResult {
    let success: Bool
    let error: String?
    let timestamp: Date = Date()
}

// MARK: - Enhanced Flow Testing

class EnhancedFlowTester: ObservableObject {
    
    @Published var testStatus: String = "Ready"
    @Published var enrollmentResult: EnrollmentTestResult?
    @Published var authenticationResult: AuthenticationTestResult?
    
    private let authService = AuthenticationService()
    private let healthService = HealthKitService()
    private let dataManager = DataManager.shared
    
    init() {
        setupServices()
    }
    
    private func setupServices() {
        authService.setDataManager(dataManager)
        authService.setHealthKitService(healthService)
    }
    
    /// Test complete enrollment flow
    func testEnrollmentFlow() async {
        debugLog.info("🧪 Starting enhanced enrollment flow test")
        
        await MainActor.run {
            testStatus = "Testing enrollment flow..."
        }
        
        // Generate test data
        let testData = generateTestHeartRateData()
        
        // Run enrollment
        let result = await authService.performEnrollment(with: testData)
        
        await MainActor.run {
            self.enrollmentResult = result
            if result.success {
                self.testStatus = "✅ Enrollment test passed!"
            } else {
                self.testStatus = "❌ Enrollment test failed: \(result.error ?? "Unknown")"
            }
        }
    }
    
    /// Test complete authentication flow
    func testAuthenticationFlow() async {
        debugLog.info("🧪 Starting enhanced authentication flow test")
        
        await MainActor.run {
            testStatus = "Testing authentication flow..."
        }
        
        // Ensure enrollment exists
        guard authService.isUserEnrolled else {
            await MainActor.run {
                testStatus = "❌ Cannot test authentication - no enrollment found"
            }
            return
        }
        
        // Generate test data (similar to enrollment)
        let testData = generateTestHeartRateData()
        
        // Run authentication
        let result = await authService.performAuthentication(with: testData)
        
        await MainActor.run {
            self.authenticationResult = result
            if result.result.isSuccessful {
                self.testStatus = "✅ Authentication test passed!"
            } else {
                self.testStatus = "⚠️ Authentication test completed: \(result.result.message)"
            }
        }
    }
    
    /// Generate realistic test heart rate data
    private func generateTestHeartRateData(baseRate: Double = 75.0, samples: Int = 300) -> [Double] {
        var data: [Double] = []
        
        for i in 0..<samples {
            let time = Double(i) * 0.1
            let heartRateVariation = sin(time * 0.5) * 8.0 + sin(time * 0.1) * 3.0
            let noise = Double.random(in: -2...2)
            let value = baseRate + heartRateVariation + noise
            data.append(max(40.0, min(200.0, value))) // Clamp to realistic range
        }
        
        return data
    }
}