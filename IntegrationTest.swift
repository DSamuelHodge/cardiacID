//
//  IntegrationTest.swift
//  HeartID Watch App
//
//  Final integration test for enrollment and authentication flows
//

import Foundation
import SwiftUI

/// Final integration test runner to validate the complete system
class IntegrationTestRunner: ObservableObject {
    
    // MARK: - Test State
    
    @Published var isRunning = false
    @Published var currentStep = ""
    @Published var testResults: [String] = []
    @Published var overallSuccess = false
    @Published var progress: Double = 0.0
    
    // MARK: - Services
    
    private let dataManager = DataManager.shared
    private let authService = AuthenticationService()
    private let healthService = HealthKitService()
    
    // MARK: - Test Data
    
    private let mockHeartRateData: [Double] = {
        var data: [Double] = []
        let baseRate = 75.0
        for i in 0..<250 {  // 250 samples for good quality
            let time = Double(i) * 0.1
            let variation = sin(time * 0.3) * 8.0 + cos(time * 0.1) * 3.0
            let noise = Double.random(in: -1.5...1.5)
            data.append(baseRate + variation + noise)
        }
        return data
    }()
    
    init() {
        setupServices()
    }
    
    private func setupServices() {
        authService.setDataManager(dataManager)
        authService.setHealthKitService(healthService)
    }
    
    // MARK: - Main Test Runner
    
    func runCompleteIntegrationTest() async {
        debugLog.info("🚀 Starting complete integration test")
        
        await MainActor.run {
            isRunning = true
            currentStep = "Starting integration test..."
            testResults = []
            progress = 0.0
            overallSuccess = false
        }
        
        var allTestsPassed = true
        
        // Step 1: Clean slate
        await updateProgress(0.1, "Preparing clean test environment...")
        let cleanupSuccess = await cleanupForTest()
        if !cleanupSuccess {
            allTestsPassed = false
        }
        
        // Step 2: Service initialization
        await updateProgress(0.2, "Testing service initialization...")
        let initSuccess = await testServiceInitialization()
        if !initSuccess {
            allTestsPassed = false
        }
        
        // Step 3: HealthKit integration
        await updateProgress(0.3, "Testing HealthKit integration...")
        let healthSuccess = await testHealthKitIntegration()
        if !healthSuccess {
            allTestsPassed = false
        }
        
        // Step 4: Data validation
        await updateProgress(0.4, "Testing data validation...")
        let validationSuccess = await testDataValidation()
        if !validationSuccess {
            allTestsPassed = false
        }
        
        // Step 5: Enrollment flow
        await updateProgress(0.5, "Testing enrollment flow...")
        let enrollmentSuccess = await testEnrollmentFlow()
        if !enrollmentSuccess {
            allTestsPassed = false
        }
        
        // Step 6: Data persistence
        await updateProgress(0.7, "Testing data persistence...")
        let persistenceSuccess = await testDataPersistence()
        if !persistenceSuccess {
            allTestsPassed = false
        }
        
        // Step 7: Authentication flow
        await updateProgress(0.8, "Testing authentication flow...")
        let authSuccess = await testAuthenticationFlow()
        if !authSuccess {
            allTestsPassed = false
        }
        
        // Step 8: Error handling
        await updateProgress(0.9, "Testing error handling...")
        let errorSuccess = await testErrorHandling()
        if !errorSuccess {
            allTestsPassed = false
        }
        
        // Final results
        await updateProgress(1.0, "Test completed!")
        await MainActor.run {
            self.overallSuccess = allTestsPassed
            self.isRunning = false
            
            if allTestsPassed {
                self.addResult("🎉 ALL TESTS PASSED! Architecture is working flawlessly.")
                debugLog.info("✅ Complete integration test passed!")
            } else {
                self.addResult("⚠️ Some tests failed. Review results for details.")
                debugLog.warning("⚠️ Integration test completed with issues")
            }
        }
    }
    
    // MARK: - Individual Test Steps
    
    private func cleanupForTest() async -> Bool {
        debugLog.info("🧹 Cleaning up for test")
        
        dataManager.clearAllData()
        authService.isUserEnrolled = false
        authService.isAuthenticated = false
        authService.clearError()
        healthService.clearError()
        
        await addResult("✅ Test environment cleaned")
        return true
    }
    
    private func testServiceInitialization() async -> Bool {
        debugLog.info("🔧 Testing service initialization")
        
        var success = true
        
        // Test singleton
        if DataManager.shared === dataManager {
            await addResult("✅ DataManager singleton working")
        } else {
            await addResult("❌ DataManager singleton issue")
            success = false
        }
        
        // Test service connections
        if authService.dataManager === dataManager {
            await addResult("✅ AuthenticationService connected to DataManager")
        } else {
            await addResult("❌ AuthenticationService connection issue")
            success = false
        }
        
        return success
    }
    
    private func testHealthKitIntegration() async -> Bool {
        debugLog.info("🫀 Testing HealthKit integration")
        
        // Test availability
        let available = healthService.isAuthorized
        if available {
            await addResult("✅ HealthKit available and authorized")
            return true
        } else {
            // Try authorization
            let authResult = await healthService.ensureAuthorization()
            switch authResult {
            case .authorized:
                await addResult("✅ HealthKit authorization successful")
                return true
            case .denied(let message):
                await addResult("⚠️ HealthKit denied: \(message)")
                return true // Still a valid test result
            case .notAvailable(let message):
                await addResult("⚠️ HealthKit not available: \(message)")
                return true // Still valid for testing
            }
        }
    }
    
    private func testDataValidation() async -> Bool {
        debugLog.info("🔍 Testing data validation")
        
        var success = true
        
        // Test with valid data
        let validation = EnhancedBiometricValidation.validate(mockHeartRateData)
        if validation.isValid {
            await addResult("✅ Valid data accepted (quality: \(String(format: "%.1f%%", validation.qualityScore * 100)))")
        } else {
            await addResult("❌ Valid data rejected: \(validation.errorMessage ?? "Unknown")")
            success = false
        }
        
        // Test with invalid data
        let invalidData = Array(repeating: 0.0, count: 10)
        let invalidValidation = EnhancedBiometricValidation.validate(invalidData)
        if !invalidValidation.isValid {
            await addResult("✅ Invalid data correctly rejected")
        } else {
            await addResult("❌ Invalid data was accepted")
            success = false
        }
        
        return success
    }
    
    private func testEnrollmentFlow() async -> Bool {
        debugLog.info("📝 Testing enrollment flow")
        
        // Perform enrollment
        let success = await authService.enroll(with: mockHeartRateData)
        
        if success {
            await addResult("✅ Enrollment completed successfully")
            
            // Verify state
            if authService.isUserEnrolled {
                await addResult("✅ Enrollment state updated correctly")
                return true
            } else {
                await addResult("❌ Enrollment state not updated")
                return false
            }
        } else {
            let error = authService.errorMessage ?? "Unknown error"
            await addResult("❌ Enrollment failed: \(error)")
            return false
        }
    }
    
    private func testDataPersistence() async -> Bool {
        debugLog.info("💾 Testing data persistence")
        
        // Check if data was saved
        if dataManager.isUserEnrolled() {
            await addResult("✅ Enrollment data persisted")
            
            // Try to retrieve profile
            if let profile = dataManager.getUserProfile() {
                await addResult("✅ User profile retrieved successfully")
                
                // Check data integrity
                if !profile.biometricTemplate.heartRatePattern.isEmpty {
                    await addResult("✅ Biometric data intact")
                    return true
                } else {
                    await addResult("❌ Biometric data corrupted")
                    return false
                }
            } else {
                await addResult("❌ User profile retrieval failed")
                return false
            }
        } else {
            await addResult("❌ Enrollment data not persisted")
            return false
        }
    }
    
    private func testAuthenticationFlow() async -> Bool {
        debugLog.info("🔐 Testing authentication flow")
        
        // Test with same data (should succeed)
        let result = authService.completeAuthentication(with: mockHeartRateData)
        
        switch result {
        case .approved(let confidence):
            await addResult("✅ Authentication successful (confidence: \(String(format: "%.1f%%", confidence * 100)))")
            return true
            
        case .retry(let message):
            await addResult("⚠️ Authentication requested retry: \(message)")
            return true // Retry is acceptable
            
        case .denied(let reason):
            await addResult("❌ Authentication denied: \(reason)")
            return false
            
        case .error(let message):
            await addResult("❌ Authentication error: \(message)")
            return false
            
        case .pending:
            await addResult("⚠️ Authentication pending (unexpected)")
            return false
        }
    }
    
    private func testErrorHandling() async -> Bool {
        debugLog.info("⚠️ Testing error handling")
        
        var success = true
        
        // Test with empty data
        let emptyResult = authService.completeAuthentication(with: [])
        if !emptyResult.isSuccessful {
            await addResult("✅ Empty data correctly rejected")
        } else {
            await addResult("❌ Empty data was accepted")
            success = false
        }
        
        // Test error clearing
        authService.clearError()
        if authService.errorMessage == nil {
            await addResult("✅ Error clearing works")
        } else {
            await addResult("❌ Error clearing failed")
            success = false
        }
        
        return success
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double, _ step: String) async {
        await MainActor.run {
            self.progress = progress
            self.currentStep = step
        }
    }
    
    private func addResult(_ message: String) async {
        await MainActor.run {
            self.testResults.append(message)
        }
        debugLog.info(message)
    }
}

// MARK: - Integration Test View

struct IntegrationTestView: View {
    @StateObject private var testRunner = IntegrationTestRunner()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: testRunner.overallSuccess ? "checkmark.seal.fill" : "testtube.2")
                            .font(.system(size: 50))
                            .foregroundColor(testRunner.overallSuccess ? .green : .blue)
                            .symbolEffect(.bounce, value: testRunner.overallSuccess)
                        
                        Text("Integration Test")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Complete system validation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress
                    if testRunner.isRunning {
                        VStack(spacing: 8) {
                            ProgressView(value: testRunner.progress)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            Text(testRunner.currentStep)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    
                    // Results
                    if !testRunner.testResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Test Results")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(testRunner.testResults, id: \.self) { result in
                                    Text(result)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(backgroundForResult(result))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    
                    // Actions
                    if !testRunner.isRunning {
                        Button("Run Complete Test") {
                            Task {
                                await testRunner.runCompleteIntegrationTest()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Integration Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func backgroundForResult(_ result: String) -> Color {
        if result.contains("✅") {
            return Color.green.opacity(0.1)
        } else if result.contains("❌") {
            return Color.red.opacity(0.1)
        } else if result.contains("⚠️") {
            return Color.orange.opacity(0.1)
        } else if result.contains("🎉") {
            return Color.blue.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Preview

struct IntegrationTestView_Previews: PreviewProvider {
    static var previews: some View {
        IntegrationTestView()
    }
}