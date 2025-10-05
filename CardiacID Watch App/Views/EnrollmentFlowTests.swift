import Testing
import Foundation

@testable import HeartID  // Replace with actual module name

@Suite("Enrollment Flow Tests")
struct EnrollmentFlowTests {
    
    @Test("Heart template creation with valid data")
    func heartTemplateCreation() async throws {
        let validHeartRateData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        
        let template = FeatureExtractor.features(from: validHeartRateData)
        
        #expect(template != nil, "Template should be created from valid data")
        #expect(template?.count == validHeartRateData.count, "Template count should match input data count")
        #expect((template?.mean ?? 0) > 0, "Template mean should be positive")
        #expect((template?.stdev ?? -1) >= 0, "Template standard deviation should be non-negative")
    }
    
    @Test("Heart template creation fails with insufficient data")
    func heartTemplateCreationFailsWithInsufficientData() async throws {
        let insufficientData = [72.0, 74.0, 73.0]  // Less than 8 samples
        
        let template = FeatureExtractor.features(from: insufficientData)
        
        #expect(template == nil, "Template should not be created with insufficient data")
    }
    
    @Test("Heart matcher comparison")
    func heartMatcherComparison() async throws {
        let baselineData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        let similarData = [71.0, 73.0, 74.0, 76.0, 72.0, 75.0, 73.0, 71.0, 74.0]
        
        let baselineTemplate = try #require(FeatureExtractor.features(from: baselineData))
        let liveTemplate = try #require(FeatureExtractor.features(from: similarData))
        
        let result = HeartMatcher.match(live: liveTemplate, enrolled: baselineTemplate)
        
        #expect(result.score >= 0, "Match score should be non-negative")
        #expect(result.passed == (result.score <= 0.42), "Pass result should match threshold logic")
    }
    
    @Test("Authentication result properties")
    func authenticationResultProperties() async throws {
        #expect(AuthenticationResult.approved.isSuccessful, "Approved should be successful")
        #expect(!AuthenticationResult.failed.isSuccessful, "Failed should not be successful")
        #expect(AuthenticationResult.retryRequired.requiresRetry, "Retry required should require retry")
        #expect(!AuthenticationResult.approved.requiresRetry, "Approved should not require retry")
        
        #expect(!AuthenticationResult.approved.message.isEmpty, "All results should have messages")
        #expect(!AuthenticationResult.failed.message.isEmpty, "All results should have messages")
    }
    
    @Test("Template store save and load cycle")
    func templateStoreSaveLoadCycle() async throws {
        let testData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        let template = try #require(FeatureExtractor.features(from: testData))
        
        let store = TemplateStore.shared
        
        // Clear any existing template first
        store.revoke()
        
        // Save template
        try store.save(template)
        
        // Load template
        let loadedTemplate = try store.load()
        
        #expect(loadedTemplate != nil, "Should be able to load saved template")
        #expect(loadedTemplate?.version == template.version, "Loaded template should match saved version")
        #expect(loadedTemplate?.mean == template.mean, "Loaded template should match saved mean")
        #expect(loadedTemplate?.count == template.count, "Loaded template should match saved count")
        
        // Clean up
        store.revoke()
    }
    
    @Test("Template matching with very different patterns")
    func templateMatchingVariousScenarios() async throws {
        let baselineData = [70.0, 72.0, 74.0, 73.0, 71.0, 75.0, 72.0, 70.0]
        let veryDifferentData = [100.0, 105.0, 102.0, 108.0, 110.0, 106.0, 104.0, 103.0]
        
        let baselineTemplate = try #require(FeatureExtractor.features(from: baselineData))
        let differentTemplate = try #require(FeatureExtractor.features(from: veryDifferentData))
        
        let result = HeartMatcher.match(live: differentTemplate, enrolled: baselineTemplate)
        
        #expect(!result.passed, "Very different patterns should not match")
        #expect(result.score > 0.42, "Very different patterns should have high score (low similarity)")
    }
}