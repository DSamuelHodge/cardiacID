import XCTest
import Foundation

@testable import HeartID  // Replace with actual module name

class EnrollmentFlowTests: XCTestCase {
    
    func testHeartTemplateCreation() async throws {
        let validHeartRateData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        
        let template = FeatureExtractor.features(from: validHeartRateData)
        
        XCTAssertNotNil(template, "Template should be created from valid data")
        XCTAssertEqual(template?.count, validHeartRateData.count, "Template count should match input data count")
        XCTAssertGreaterThan(template?.mean ?? 0, 0, "Template mean should be positive")
        XCTAssertGreaterThanOrEqual(template?.stdev ?? -1, 0, "Template standard deviation should be non-negative")
    }
    
    func testHeartTemplateCreationFailsWithInsufficientData() async throws {
        let insufficientData = [72.0, 74.0, 73.0]  // Less than 8 samples
        
        let template = FeatureExtractor.features(from: insufficientData)
        
        XCTAssertNil(template, "Template should not be created with insufficient data")
    }
    
    func testHeartMatcherComparison() async throws {
        let baselineData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        let similarData = [71.0, 73.0, 74.0, 76.0, 72.0, 75.0, 73.0, 71.0, 74.0]
        
        let baselineTemplate = try XCTUnwrap(FeatureExtractor.features(from: baselineData))
        let liveTemplate = try XCTUnwrap(FeatureExtractor.features(from: similarData))
        
        let result = HeartMatcher.match(live: liveTemplate, enrolled: baselineTemplate)
        
        XCTAssertGreaterThanOrEqual(result.score, 0, "Match score should be non-negative")
        XCTAssertEqual(result.passed, result.score <= 0.42, "Pass result should match threshold logic")
    }
    
    func testAuthenticationResultProperties() async throws {
        XCTAssertTrue(AuthenticationResult.approved.isSuccessful, "Approved should be successful")
        XCTAssertFalse(AuthenticationResult.failed.isSuccessful, "Failed should not be successful")
        XCTAssertTrue(AuthenticationResult.retryRequired.requiresRetry, "Retry required should require retry")
        XCTAssertFalse(AuthenticationResult.approved.requiresRetry, "Approved should not require retry")
        
        XCTAssertFalse(AuthenticationResult.approved.message.isEmpty, "All results should have messages")
        XCTAssertFalse(AuthenticationResult.failed.message.isEmpty, "All results should have messages")
    }
    
    func testTemplateStoreSaveLoadCycle() async throws {
        let testData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        let template = try XCTUnwrap(FeatureExtractor.features(from: testData))
        
        let store = TemplateStore.shared
        
        // Clear any existing template first
        store.revoke()
        
        // Save template
        try store.save(template)
        
        // Load template
        let loadedTemplate = try store.load()
        
        XCTAssertNotNil(loadedTemplate, "Should be able to load saved template")
        XCTAssertEqual(loadedTemplate?.version, template.version, "Loaded template should match saved version")
        XCTAssertEqual(loadedTemplate?.mean, template.mean, "Loaded template should match saved mean")
        XCTAssertEqual(loadedTemplate?.count, template.count, "Loaded template should match saved count")
        
        // Clean up
        store.revoke()
    }
    
    func testTemplateMatchingVariousScenarios() async throws {
        let baselineData = [70.0, 72.0, 74.0, 73.0, 71.0, 75.0, 72.0, 70.0]
        let veryDifferentData = [100.0, 105.0, 102.0, 108.0, 110.0, 106.0, 104.0, 103.0]
        
        let baselineTemplate = try XCTUnwrap(FeatureExtractor.features(from: baselineData))
        let differentTemplate = try XCTUnwrap(FeatureExtractor.features(from: veryDifferentData))
        
        let result = HeartMatcher.match(live: differentTemplate, enrolled: baselineTemplate)
        
        XCTAssertFalse(result.passed, "Very different patterns should not match")
        XCTAssertGreaterThan(result.score, 0.42, "Very different patterns should have high score (low similarity)")
    }
}
