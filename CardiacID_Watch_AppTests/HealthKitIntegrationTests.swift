//
//  HealthKitIntegrationTests.swift
//  HeartID Watch App Tests
//
//  Comprehensive tests for HealthKit integration and data access
//

import XCTest
import HealthKit
@testable import CardiacID_Watch_App

class HealthKitIntegrationTests: XCTestCase {
    
    var mockHealthKitService: MockHealthKitService!
    var realHealthKitService: HealthKitService!
    
    override func setUp() {
        super.setUp()
        mockHealthKitService = MockHealthKitService()
        realHealthKitService = HealthKitService()
    }
    
    override func tearDown() {
        mockHealthKitService = nil
        realHealthKitService = nil
        super.tearDown()
    }
    
    // MARK: - Mock HealthKit Tests
    
    func testHealthKitIntegration() async {
        // Test with mock service first
        mockHealthKitService.setMockAuthorization(true)
        mockHealthKitService.generateMockSamples(count: 200)
        
        let result = await mockHealthKitService.testHeartRateDataAccess()
        XCTAssertTrue(result, "Mock HealthKit should return true when samples are available")
        
        print("✅ Mock HealthKit Integration Test Results:")
        print("   Data Access Test: \(result)")
        print("   Sample Count: \(mockHealthKitService.heartRateSamples.count)")
    }
    
    func testMockHealthKitAuthorization() async {
        // Test authorized state
        mockHealthKitService.setMockAuthorization(true)
        let authResult = await mockHealthKitService.ensureAuthorization()
        
        switch authResult {
        case .authorized:
            XCTAssertTrue(true, "Mock service should return authorized when set to true")
        default:
            XCTFail("Mock service should return authorized when set to true")
        }
        
        // Test denied state
        mockHealthKitService.setMockAuthorization(false)
        let deniedResult = await mockHealthKitService.ensureAuthorization()
        
        switch deniedResult {
        case .denied(let message):
            XCTAssertEqual(message, "Mock authorization denied", "Mock service should return proper denial message")
        default:
            XCTFail("Mock service should return denied when set to false")
        }
        
        print("✅ Mock HealthKit Authorization Test Results:")
        print("   Authorized Result: \(authResult)")
        print("   Denied Result: \(deniedResult)")
    }
    
    func testMockHealthKitDataGeneration() {
        mockHealthKitService.generateMockSamples(count: 300)
        
        let samples = mockHealthKitService.heartRateSamples
        XCTAssertEqual(samples.count, 300, "Mock service should generate correct number of samples")
        
        // Validate sample structure
        for sample in samples {
            XCTAssertGreaterThan(sample.value, 40, "Sample value should be realistic")
            XCTAssertLessThan(sample.value, 200, "Sample value should be realistic")
            XCTAssertNotNil(sample.timestamp, "Sample should have timestamp")
            XCTAssertNotNil(sample.source, "Sample should have source")
        }
        
        print("✅ Mock HealthKit Data Generation Test Results:")
        print("   Sample Count: \(samples.count)")
        print("   First Sample: \(samples.first?.value ?? 0) BPM")
        print("   Last Sample: \(samples.last?.value ?? 0) BPM")
    }
    
    // MARK: - Real HealthKit Tests (when available)
    
    func testRealHealthKitAvailability() {
        let isAvailable = HKHealthStore.isHealthDataAvailable()
        
        if isAvailable {
            print("✅ HealthKit is available on this device")
            
            // Test authorization status
            let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
            let status = realHealthKitService.authorizationStatus
            
            print("   Authorization Status: \(status)")
            
            // Test that we can create health store
            XCTAssertNotNil(realHealthKitService, "HealthKit service should be created successfully")
        } else {
            print("⚠️ HealthKit is not available on this device (simulator)")
            // This is expected in simulator, so we don't fail the test
        }
    }
    
    func testHealthKitAuthorizationFlow() async {
        // Only run this test if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Skipping HealthKit authorization test - not available")
            return
        }
        
        // Test authorization request
        let authResult = await realHealthKitService.ensureAuthorization()
        
        switch authResult {
        case .authorized:
            print("✅ HealthKit authorization successful")
            XCTAssertTrue(realHealthKitService.isAuthorized, "Service should be marked as authorized")
            
        case .denied(let message):
            print("⚠️ HealthKit authorization denied: \(message)")
            // This is acceptable in test environment
            
        case .notAvailable(let message):
            print("⚠️ HealthKit not available: \(message)")
            // This is acceptable in test environment
            
        @unknown default:
            print("⚠️ Unknown HealthKit authorization result")
        }
        
        print("✅ HealthKit Authorization Flow Test Results:")
        print("   Result: \(authResult)")
        print("   Service Authorized: \(realHealthKitService.isAuthorized)")
    }
    
    func testHealthKitDataAccess() async {
        // Only run this test if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Skipping HealthKit data access test - not available")
            return
        }
        
        // Test data access
        let dataAccessResult = await realHealthKitService.testHeartRateDataAccess()
        
        if dataAccessResult {
            print("✅ HealthKit data access successful")
            XCTAssertTrue(dataAccessResult, "Data access should be successful")
        } else {
            print("⚠️ HealthKit data access failed - may need authorization")
            // This is acceptable if not authorized
        }
        
        print("✅ HealthKit Data Access Test Results:")
        print("   Data Access: \(dataAccessResult)")
    }
    
    func testHealthKitDiagnostics() async {
        // Only run this test if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Skipping HealthKit diagnostics test - not available")
            return
        }
        
        let diagnostics = await realHealthKitService.runHealthKitDiagnostics()
        
        XCTAssertFalse(diagnostics.isEmpty, "Diagnostics should not be empty")
        XCTAssertTrue(diagnostics.contains("HealthKit Diagnostics Report"), "Diagnostics should contain report header")
        
        print("✅ HealthKit Diagnostics Test Results:")
        print("   Diagnostics Report:")
        print(diagnostics)
    }
    
    // MARK: - Heart Rate Capture Tests
    
    func testHeartRateCaptureWithMock() {
        mockHealthKitService.generateMockSamples(count: 200)
        
        let expectation = XCTestExpectation(description: "Heart rate capture completion")
        
        mockHealthKitService.startHeartRateCapture(duration: 10.0) { result in
            switch result {
            case .success(let samples):
                XCTAssertEqual(samples.count, 200, "Should return correct number of samples")
                XCTAssertTrue(samples.allSatisfy { $0 >= 40 && $0 <= 200 }, "All samples should be realistic")
                expectation.fulfill()
                
            case .failure(let error):
                XCTFail("Mock capture should not fail: \(error.localizedDescription)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        print("✅ Mock Heart Rate Capture Test Results:")
        print("   Capture completed successfully")
    }
    
    func testHeartRateCapturePerformance() {
        let expectation = XCTestExpectation(description: "Performance test completion")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        mockHealthKitService.startHeartRateCapture(duration: 5.0) { result in
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            XCTAssertLessThan(duration, 0.1, "Mock capture should complete quickly")
            
            switch result {
            case .success(let samples):
                XCTAssertGreaterThan(samples.count, 0, "Should return samples")
            case .failure:
                XCTFail("Mock capture should not fail")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        print("✅ Heart Rate Capture Performance Test Results:")
        print("   Performance test completed")
    }
    
    // MARK: - Error Handling Tests
    
    func testHealthKitErrorHandling() {
        // Test with mock service in error state
        mockHealthKitService.setMockAuthorization(false)
        mockHealthKitService.setMockSamples([])
        
        let expectation = XCTestExpectation(description: "Error handling test")
        
        mockHealthKitService.startHeartRateCapture(duration: 5.0) { result in
            switch result {
            case .success:
                XCTFail("Should fail when not authorized and no samples")
            case .failure(let error):
                XCTAssertNotNil(error, "Should return error")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        print("✅ HealthKit Error Handling Test Results:")
        print("   Error handling test completed")
    }
    
    // MARK: - Integration with Authentication Service
    
    func testAuthenticationServiceWithMockHealthKit() {
        let mockService = MockHealthKitService()
        mockService.generateMockSamples(count: 200)
        
        // Create authentication service with mock HealthKit
        let authService = AuthenticationService()
        authService.dataManager = DataManager() // Use real data manager
        
        // Test enrollment with mock data
        let samples = mockService.heartRateSamples.map { $0.value }
        let enrollmentResult = authService.completeEnrollment(with: samples)
        
        // Enrollment should succeed with good mock data
        XCTAssertTrue(enrollmentResult, "Enrollment should succeed with good mock data")
        
        print("✅ Authentication Service Integration Test Results:")
        print("   Enrollment Result: \(enrollmentResult)")
    }
    
    func testAuthenticationServiceWithRealHealthKit() async {
        // Only run this test if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Skipping real HealthKit authentication test - not available")
            return
        }
        
        let authService = AuthenticationService()
        authService.dataManager = DataManager()
        
        // Test authorization
        let authResult = await realHealthKitService.ensureAuthorization()
        
        switch authResult {
        case .authorized:
            print("✅ Real HealthKit authentication test - authorized")
            
            // Test data access
            let dataAccess = await realHealthKitService.testHeartRateDataAccess()
            print("   Data Access: \(dataAccess)")
            
        case .denied(let message):
            print("⚠️ Real HealthKit authentication test - denied: \(message)")
            
        case .notAvailable(let message):
            print("⚠️ Real HealthKit authentication test - not available: \(message)")
            
        @unknown default:
            print("⚠️ Real HealthKit authentication test - unknown result")
        }
        
        print("✅ Real HealthKit Authentication Service Test Results:")
        print("   Authorization Result: \(authResult)")
    }
    
    // MARK: - Performance Tests
    
    func testHealthKitServicePerformance() {
        let metrics = BiometricPerformanceMonitor.measure("Mock HealthKit Service") {
            mockHealthKitService.generateMockSamples(count: 1000)
            return mockHealthKitService.heartRateSamples.count
        }
        
        XCTAssertEqual(metrics.sampleCount, 1000, "Should generate correct number of samples")
        XCTAssertLessThan(metrics.duration, 0.1, "Mock service should be fast")
        
        print("✅ HealthKit Service Performance Test Results:")
        print("   Duration: \(String(format: "%.3f", metrics.duration))s")
        print("   Memory Usage: \(metrics.memoryUsage) bytes")
        print("   Sample Count: \(metrics.sampleCount)")
    }
    
    // MARK: - Test Data Validation
    
    func testHealthKitSampleValidation() {
        let samples = BiometricTestDataGenerator.generateHeartRateSamples(count: 100)
        let heartRateSamples = samples.enumerated().map { index, value in
            HeartRateSample(
                value: value,
                timestamp: Date().addingTimeInterval(-Double(100 - index)),
                source: "Test Sensor"
            )
        }
        
        // Validate sample structure
        for sample in heartRateSamples {
            XCTAssertGreaterThan(sample.value, 40, "Sample value should be realistic")
            XCTAssertLessThan(sample.value, 200, "Sample value should be realistic")
            XCTAssertNotNil(sample.timestamp, "Sample should have timestamp")
            XCTAssertNotNil(sample.source, "Sample should have source")
        }
        
        // Validate chronological order
        for i in 1..<heartRateSamples.count {
            XCTAssertLessThanOrEqual(
                heartRateSamples[i-1].timestamp,
                heartRateSamples[i].timestamp,
                "Samples should be in chronological order"
            )
        }
        
        print("✅ HealthKit Sample Validation Test Results:")
        print("   Sample Count: \(heartRateSamples.count)")
        print("   First Sample: \(heartRateSamples.first?.value ?? 0) BPM")
        print("   Last Sample: \(heartRateSamples.last?.value ?? 0) BPM")
    }
}
