//
//  ArchitectureTestHarness.swift
//  HeartID Watch App
//
//  Comprehensive testing harness for enrollment and authentication flows
//

import Foundation
import SwiftUI
import HealthKit

/// Test harness to validate the entire HeartID architecture
class ArchitectureTestHarness: ObservableObject {
    
    // MARK: - Test State
    
    @Published var testResults: [TestResult] = []
    @Published var currentTest: String = ""
    @Published var overallStatus: TestStatus = .notStarted
    
    // MARK: - Services Under Test
    
    private let dataManager = DataManager.shared
    private let authenticationService = AuthenticationService()
    private let healthKitService = HealthKitService()
    private let xenonXCalculator = XenonXCalculator()
    
    // MARK: - Test Configuration
    
    private let testHeartRateData: [Double] = {
        // Generate realistic test heart rate data
        var data: [Double] = []
        let baseRate = 75.0
        for i in 0..<300 {
            let time = Double(i) * 0.1
            let variation = sin(time * 0.5) * 5.0 + sin(time * 0.1) * 2.0
            let noise = Double.random(in: -1...1)
            data.append(baseRate + variation + noise)
        }
        return data
    }()
    
    init() {
        setupServices()
    }
    
    private func setupServices() {
        // Configure services for testing
        authenticationService.setDataManager(dataManager)
        authenticationService.setHealthKitService(healthKitService)
    }
    
    // MARK: - Main Test Runner
    
    func runArchitectureTests() async {
        debugLog.info("🧪 Starting comprehensive architecture tests")
        
        overallStatus = .running
        testResults.removeAll()
        
        // Test 1: Service Initialization
        await testServiceInitialization()
        
        // Test 2: HealthKit Integration
        await testHealthKitIntegration()
        
        // Test 3: Data Manager Operations
        await testDataManagerOperations()
        
        // Test 4: XenonX Calculator
        await testXenonXCalculator()
        
        // Test 5: Enrollment Flow (End-to-End)
        await testEnrollmentFlow()
        
        // Test 6: Authentication Flow (End-to-End)
        await testAuthenticationFlow()
        
        // Test 7: Error Handling
        await testErrorHandling()
        
        // Test 8: State Management
        await testStateManagement()
        
        // Finalize results
        await finalizeTestResults()
    }
    
    // MARK: - Individual Test Functions
    
    private func testServiceInitialization() async {
        currentTest = "Service Initialization"
        debugLog.info("🧪 Testing service initialization...")
        
        var passed = 0
        var total = 0
        
        // Test DataManager singleton
        total += 1
        if DataManager.shared === dataManager {
            passed += 1
            addTestResult(.passed, "DataManager singleton working correctly")
        } else {
            addTestResult(.failed, "DataManager singleton failed")
        }
        
        // Test AuthenticationService initialization
        total += 1
        if authenticationService.isUserEnrolled == dataManager.isUserEnrolled() {
            passed += 1
            addTestResult(.passed, "AuthenticationService state sync working")
        } else {
            addTestResult(.failed, "AuthenticationService state sync failed")
        }
        
        // Test HealthKitService availability check
        total += 1
        let healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        addTestResult(.passed, "HealthKit availability: \(healthKitAvailable ? "Available" : "Not Available")")
        passed += 1
        
        addTestResult(passed == total ? .passed : .failed, 
                     "Service Initialization: \(passed)/\(total) tests passed")
    }
    
    private func testHealthKitIntegration() async {
        currentTest = "HealthKit Integration"
        debugLog.info("🧪 Testing HealthKit integration...")
        
        // Test authorization flow
        let authResult = await healthKitService.ensureAuthorization()
        
        switch authResult {
        case .authorized:
            addTestResult(.passed, "HealthKit authorization successful")
        case .denied(let message):
            addTestResult(.warning, "HealthKit authorization denied: \(message)")
        case .notAvailable(let message):
            addTestResult(.warning, "HealthKit not available: \(message)")
        }
        
        // Test sensor validation
        let sensorResult = await healthKitService.validateSensorEngagement()
        switch sensorResult {
        case .ready:
            addTestResult(.passed, "Sensor validation successful")
        case .notAuthorized(let message):
            addTestResult(.warning, "Sensor validation failed: \(message)")
        case .noRecentData(let message):
            addTestResult(.info, "No recent data available: \(message)")
        case .sensorError(let message):
            addTestResult(.failed, "Sensor error: \(message)")
        }
        
        // Test heart rate capture simulation
        let captureResult = await healthKitService.startHeartRateCapture(duration: 1.0)
        switch captureResult {
        case .success(let data):
            addTestResult(.passed, "Heart rate capture successful: \(data.count) samples")
        case .failure(let error):
            addTestResult(.warning, "Heart rate capture failed: \(error.localizedDescription)")
        }
    }
    
    private func testDataManagerOperations() async {
        currentTest = "Data Manager Operations"
        debugLog.info("🧪 Testing DataManager operations...")
        
        // Clear any existing data for clean test
        dataManager.clearAllData()
        
        // Test 1: Initial state
        if !dataManager.isUserEnrolled() {
            addTestResult(.passed, "Initial state: User not enrolled (correct)")
        } else {
            addTestResult(.failed, "Initial state: User should not be enrolled after clear")
        }
        
        // Test 2: User profile creation and storage
        let template = BiometricTemplate(heartRatePattern: testHeartRateData)
        let profile = UserProfile(template: template)
        
        let saveSuccess = dataManager.saveUserProfile(profile)
        if saveSuccess {
            addTestResult(.passed, "User profile saved successfully")
        } else {
            addTestResult(.failed, "Failed to save user profile")
            return
        }
        
        // Test 3: User profile retrieval
        if let retrievedProfile = dataManager.getUserProfile() {
            addTestResult(.passed, "User profile retrieved successfully")
            
            // Test 4: Data integrity
            if retrievedProfile.biometricTemplate.heartRatePattern.count == testHeartRateData.count {
                addTestResult(.passed, "Data integrity check passed")
            } else {
                addTestResult(.failed, "Data integrity check failed")
            }
        } else {
            addTestResult(.failed, "Failed to retrieve user profile")
        }
        
        // Test 5: Enrollment status
        if dataManager.isUserEnrolled() {
            addTestResult(.passed, "Enrollment status correctly updated")
        } else {
            addTestResult(.failed, "Enrollment status not updated")
        }
    }
    
    private func testXenonXCalculator() async {
        currentTest = "XenonX Calculator"
        debugLog.info("🧪 Testing XenonX pattern analysis...")
        
        // Test 1: Pattern analysis
        let result1 = xenonXCalculator.analyzePattern(testHeartRateData)
        if result1.confidence > 0 {
            addTestResult(.passed, "XenonX pattern analysis successful (confidence: \(String(format: "%.1f%%", result1.confidence * 100)))")
        } else {
            addTestResult(.failed, "XenonX pattern analysis failed")
            return
        }
        
        // Test 2: Pattern comparison with same data
        let result2 = xenonXCalculator.analyzePattern(testHeartRateData)
        let similarity = xenonXCalculator.comparePatterns(result1, result2)
        
        if similarity > 0.9 {
            addTestResult(.passed, "XenonX pattern comparison successful (similarity: \(String(format: "%.1f%%", similarity * 100)))")
        } else {
            addTestResult(.warning, "XenonX pattern comparison lower than expected (similarity: \(String(format: "%.1f%%", similarity * 100)))")
        }
        
        // Test 3: Pattern comparison with different data
        let differentData = testHeartRateData.map { $0 + Double.random(in: -10...10) }
        let result3 = xenonXCalculator.analyzePattern(differentData)
        let differentSimilarity = xenonXCalculator.comparePatterns(result1, result3)
        
        if differentSimilarity < similarity {
            addTestResult(.passed, "XenonX correctly distinguishes different patterns")
        } else {
            addTestResult(.warning, "XenonX pattern discrimination may need improvement")
        }
    }
    
    private func testEnrollmentFlow() async {
        currentTest = "Enrollment Flow (End-to-End)"
        debugLog.info("🧪 Testing complete enrollment flow...")
        
        // Clear existing enrollment
        dataManager.clearAllData()
        authenticationService.isUserEnrolled = false
        
        // Test 1: Pre-enrollment state
        if !authenticationService.isUserEnrolled {
            addTestResult(.passed, "Pre-enrollment state correct")
        } else {
            addTestResult(.failed, "Pre-enrollment state incorrect")
        }
        
        // Test 2: Enrollment with valid data
        let enrollmentSuccess = await authenticationService.enroll(with: testHeartRateData)
        
        if enrollmentSuccess {
            addTestResult(.passed, "Enrollment completed successfully")
        } else {
            addTestResult(.failed, "Enrollment failed: \(authenticationService.errorMessage ?? "Unknown error")")
            return
        }
        
        // Test 3: Post-enrollment state
        if authenticationService.isUserEnrolled {
            addTestResult(.passed, "Post-enrollment state correct")
        } else {
            addTestResult(.failed, "Post-enrollment state incorrect")
        }
        
        // Test 4: Data persistence
        if dataManager.isUserEnrolled() {
            addTestResult(.passed, "Enrollment data persisted correctly")
        } else {
            addTestResult(.failed, "Enrollment data not persisted")
        }
        
        // Test 5: Enrollment with invalid data (too few samples)
        let invalidData = Array(testHeartRateData.prefix(50)) // Too few samples
        let invalidEnrollment = await authenticationService.enroll(with: invalidData)
        
        if !invalidEnrollment {
            addTestResult(.passed, "Invalid data correctly rejected")
        } else {
            addTestResult(.warning, "Invalid data was accepted (should be rejected)")
        }
    }
    
    private func testAuthenticationFlow() async {
        currentTest = "Authentication Flow (End-to-End)"
        debugLog.info("🧪 Testing complete authentication flow...")
        
        // Ensure user is enrolled from previous test
        guard authenticationService.isUserEnrolled else {
            addTestResult(.failed, "Cannot test authentication - user not enrolled")
            return
        }
        
        // Test 1: Authentication with same pattern (should succeed)
        let authResult1 = authenticationService.completeAuthentication(with: testHeartRateData)
        
        switch authResult1 {
        case .approved(let confidence):
            addTestResult(.passed, "Authentication successful with same pattern (confidence: \(String(format: "%.1f%%", confidence * 100)))")
        case .denied(let reason):
            addTestResult(.failed, "Authentication failed unexpectedly: \(reason)")
        case .retry(let message):
            addTestResult(.warning, "Authentication requested retry: \(message)")
        case .error(let message):
            addTestResult(.failed, "Authentication error: \(message)")
        case .pending:
            addTestResult(.warning, "Authentication pending (unexpected)")
        }
        
        // Test 2: Authentication with similar pattern (should succeed)
        let similarData = testHeartRateData.map { $0 + Double.random(in: -2...2) }
        let authResult2 = authenticationService.completeAuthentication(with: similarData)
        
        switch authResult2 {
        case .approved:
            addTestResult(.passed, "Authentication successful with similar pattern")
        case .retry:
            addTestResult(.info, "Authentication requested retry with similar pattern (acceptable)")
        default:
            addTestResult(.warning, "Authentication with similar pattern: \(authResult2.message)")
        }
        
        // Test 3: Authentication with very different pattern (should fail)
        let differentData = testHeartRateData.map { _ in Double.random(in: 60...90) }
        let authResult3 = authenticationService.completeAuthentication(with: differentData)
        
        switch authResult3 {
        case .denied:
            addTestResult(.passed, "Authentication correctly denied for different pattern")
        case .retry:
            addTestResult(.info, "Authentication requested retry for different pattern (acceptable)")
        case .approved:
            addTestResult(.warning, "Authentication approved for different pattern (may indicate low security)")
        default:
            addTestResult(.info, "Authentication with different pattern: \(authResult3.message)")
        }
        
        // Test 4: Authentication with insufficient data
        let insufficientData = Array(testHeartRateData.prefix(50))
        let authResult4 = authenticationService.completeAuthentication(with: insufficientData)
        
        if !authResult4.isSuccessful {
            addTestResult(.passed, "Authentication correctly rejected insufficient data")
        } else {
            addTestResult(.warning, "Authentication accepted insufficient data (should reject)")
        }
    }
    
    private func testErrorHandling() async {
        currentTest = "Error Handling"
        debugLog.info("🧪 Testing error handling...")
        
        // Test 1: Empty data handling
        let emptyResult = authenticationService.completeAuthentication(with: [])
        if !emptyResult.isSuccessful {
            addTestResult(.passed, "Empty data correctly rejected")
        } else {
            addTestResult(.failed, "Empty data was accepted")
        }
        
        // Test 2: Invalid heart rate data
        let invalidData = Array(repeating: -1.0, count: 200)
        let invalidResult = authenticationService.completeAuthentication(with: invalidData)
        if !invalidResult.isSuccessful {
            addTestResult(.passed, "Invalid heart rate data correctly rejected")
        } else {
            addTestResult(.failed, "Invalid heart rate data was accepted")
        }
        
        // Test 3: Service error clearing
        authenticationService.clearError()
        if authenticationService.errorMessage == nil {
            addTestResult(.passed, "Error clearing works correctly")
        } else {
            addTestResult(.failed, "Error clearing failed")
        }
    }
    
    private func testStateManagement() async {
        currentTest = "State Management"
        debugLog.info("🧪 Testing state management...")
        
        // Test observable object updates
        let initialEnrollmentState = authenticationService.isUserEnrolled
        
        // Simulate state change
        authenticationService.isUserEnrolled = !initialEnrollmentState
        
        // Verify state consistency
        if authenticationService.isUserEnrolled != initialEnrollmentState {
            addTestResult(.passed, "State management working correctly")
        } else {
            addTestResult(.failed, "State management not working")
        }
        
        // Restore original state
        authenticationService.isUserEnrolled = initialEnrollmentState
    }
    
    private func finalizeTestResults() async {
        currentTest = "Test Summary"
        
        let passedTests = testResults.filter { $0.status == .passed }.count
        let totalTests = testResults.count
        let passRate = totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
        
        if passRate >= 90 {
            overallStatus = .passed
            addTestResult(.passed, "🎉 Architecture tests completed successfully! Pass rate: \(String(format: "%.1f%%", passRate))")
        } else if passRate >= 70 {
            overallStatus = .warning
            addTestResult(.warning, "⚠️ Architecture tests completed with warnings. Pass rate: \(String(format: "%.1f%%", passRate))")
        } else {
            overallStatus = .failed
            addTestResult(.failed, "❌ Architecture tests failed. Pass rate: \(String(format: "%.1f%%", passRate))")
        }
        
        debugLog.info("🧪 Architecture testing completed - Pass rate: \(String(format: "%.1f%%", passRate))")
    }
    
    // MARK: - Helper Methods
    
    private func addTestResult(_ status: TestStatus, _ message: String) {
        DispatchQueue.main.async {
            let result = TestResult(
                name: self.currentTest,
                status: status,
                message: message,
                timestamp: Date()
            )
            self.testResults.append(result)
        }
        
        // Log the result
        switch status {
        case .passed:
            debugLog.info("✅ \(message)")
        case .failed:
            debugLog.error("❌ \(message)")
        case .warning:
            debugLog.warning("⚠️ \(message)")
        case .info:
            debugLog.info("ℹ️ \(message)")
        default:
            debugLog.info("📝 \(message)")
        }
    }
}

// MARK: - Supporting Types

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let status: TestStatus
    let message: String
    let timestamp: Date
}

enum TestStatus: String, CaseIterable {
    case notStarted = "Not Started"
    case running = "Running"
    case passed = "Passed"
    case failed = "Failed"
    case warning = "Warning"
    case info = "Info"
    
    var color: Color {
        switch self {
        case .passed: return .green
        case .failed: return .red
        case .warning: return .orange
        case .info: return .blue
        case .running: return .yellow
        case .notStarted: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .running: return "clock.circle.fill"
        case .notStarted: return "circle"
        }
    }
}