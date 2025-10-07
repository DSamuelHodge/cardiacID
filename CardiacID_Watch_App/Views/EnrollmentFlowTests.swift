import Foundation
import Combine

// Test utility class that can be run from within the main app
class EnrollmentFlowTests: ObservableObject {
    @Published var testResults: [String: Bool] = [:]
    @Published var testMessages: [String: String] = [:]
    
    func runAllTests() {
        testResults.removeAll()
        testMessages.removeAll()
        
        testHeartTemplateCreation()
        testHeartTemplateCreationFailsWithInsufficientData()
        testHeartMatcherComparison()
        testAuthenticationResultProperties()
        testTemplateStoreSaveLoadCycle()
        testTemplateMatchingVariousScenarios()
    }
    
    private func testHeartTemplateCreation() {
        let testName = "Heart template creation"
        let validHeartRateData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        
        let template = FeatureExtractor.features(from: validHeartRateData)
        
        guard template != nil else {
            testResults[testName] = false
            testMessages[testName] = "Template should be created from valid data"
            return
        }
        
        guard template?.count == validHeartRateData.count else {
            testResults[testName] = false
            testMessages[testName] = "Template count should match input data count"
            return
        }
        
        guard (template?.mean ?? 0) > 0 else {
            testResults[testName] = false
            testMessages[testName] = "Template mean should be positive"
            return
        }
        
        guard (template?.stdev ?? -1) >= 0 else {
            testResults[testName] = false
            testMessages[testName] = "Template standard deviation should be non-negative"
            return
        }
        
        testResults[testName] = true
        testMessages[testName] = "✅ Test passed"
    }
    
    private func testHeartTemplateCreationFailsWithInsufficientData() {
        let testName = "Heart template creation fails with insufficient data"
        let insufficientData = [72.0, 74.0, 73.0]  // Less than 8 samples
        
        let template = FeatureExtractor.features(from: insufficientData)
        
        guard template == nil else {
            testResults[testName] = false
            testMessages[testName] = "Template should not be created with insufficient data"
            return
        }
        
        testResults[testName] = true
        testMessages[testName] = "✅ Test passed"
    }
    
    private func testHeartMatcherComparison() {
        let testName = "Heart matcher comparison"
        let baselineData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        let similarData = [71.0, 73.0, 74.0, 76.0, 72.0, 75.0, 73.0, 71.0, 74.0]
        
        guard let baselineTemplate = FeatureExtractor.features(from: baselineData) else {
            testResults[testName] = false
            testMessages[testName] = "Failed to create baseline template"
            return
        }
        
        guard let liveTemplate = FeatureExtractor.features(from: similarData) else {
            testResults[testName] = false
            testMessages[testName] = "Failed to create live template"
            return
        }
        
        let result = HeartMatcher.match(live: liveTemplate, enrolled: baselineTemplate)
        
        guard result.score >= 0 else {
            testResults[testName] = false
            testMessages[testName] = "Match score should be non-negative"
            return
        }
        
        guard result.passed == (result.score <= 0.42) else {
            testResults[testName] = false
            testMessages[testName] = "Pass result should match threshold logic"
            return
        }
        
        testResults[testName] = true
        testMessages[testName] = "✅ Test passed"
    }
    
    private func testAuthenticationResultProperties() {
        let testName = "Authentication result properties"
        guard AuthenticationResult.approved.isSuccessful else {
            testResults[testName] = false
            testMessages[testName] = "Approved should be successful"
            return
        }
        
        guard !AuthenticationResult.failed.isSuccessful else {
            testResults[testName] = false
            testMessages[testName] = "Failed should not be successful"
            return
        }
        
        guard AuthenticationResult.retryRequired.requiresRetry else {
            testResults[testName] = false
            testMessages[testName] = "Retry required should require retry"
            return
        }
        
        guard !AuthenticationResult.approved.requiresRetry else {
            testResults[testName] = false
            testMessages[testName] = "Approved should not require retry"
            return
        }
        
        guard !AuthenticationResult.approved.message.isEmpty else {
            testResults[testName] = false
            testMessages[testName] = "All results should have messages"
            return
        }
        
        guard !AuthenticationResult.failed.message.isEmpty else {
            testResults[testName] = false
            testMessages[testName] = "All results should have messages"
            return
        }
        
        testResults[testName] = true
        testMessages[testName] = "✅ Test passed"
    }
    
    private func testTemplateStoreSaveLoadCycle() {
        let testName = "Template store save load cycle"
        let testData = [72.0, 74.0, 73.0, 75.0, 71.0, 76.0, 74.0, 72.0, 73.0]
        
        guard let template = FeatureExtractor.features(from: testData) else {
            testResults[testName] = false
            testMessages[testName] = "Failed to create template"
            return
        }
        
        let store = TemplateStore.shared
        
        // Clear any existing template first
        store.revoke()
        
        // Save template
        do {
            try store.save(template)
        } catch {
            testResults[testName] = false
            testMessages[testName] = "Failed to save template: \(error.localizedDescription)"
            return
        }
        
        // Load template
        do {
            let loadedTemplate = try store.load()
            
            guard loadedTemplate != nil else {
                testResults[testName] = false
                testMessages[testName] = "Should be able to load saved template"
                return
            }
            
            guard loadedTemplate?.version == template.version else {
                testResults[testName] = false
                testMessages[testName] = "Loaded template should match saved version"
                return
            }
            
            guard loadedTemplate?.mean == template.mean else {
                testResults[testName] = false
                testMessages[testName] = "Loaded template should match saved mean"
                return
            }
            
            guard loadedTemplate?.count == template.count else {
                testResults[testName] = false
                testMessages[testName] = "Loaded template should match saved count"
                return
            }
            
            // Clean up
            store.revoke()
            
            testResults[testName] = true
            testMessages[testName] = "✅ Test passed"
        } catch {
            testResults[testName] = false
            testMessages[testName] = "Failed to load template: \(error.localizedDescription)"
            store.revoke() // Clean up on error
        }
    }
    
    private func testTemplateMatchingVariousScenarios() {
        let testName = "Template matching various scenarios"
        let baselineData = [70.0, 72.0, 74.0, 73.0, 71.0, 75.0, 72.0, 70.0]
        let veryDifferentData = [100.0, 105.0, 102.0, 108.0, 110.0, 106.0, 104.0, 103.0]
        
        guard let baselineTemplate = FeatureExtractor.features(from: baselineData) else {
            testResults[testName] = false
            testMessages[testName] = "Failed to create baseline template"
            return
        }
        
        guard let differentTemplate = FeatureExtractor.features(from: veryDifferentData) else {
            testResults[testName] = false
            testMessages[testName] = "Failed to create different template"
            return
        }
        
        let result = HeartMatcher.match(live: differentTemplate, enrolled: baselineTemplate)
        
        guard !result.passed else {
            testResults[testName] = false
            testMessages[testName] = "Very different patterns should not match"
            return
        }
        
        guard result.score > 0.42 else {
            testResults[testName] = false
            testMessages[testName] = "Very different patterns should have high score (low similarity)"
            return
        }
        
        testResults[testName] = true
        testMessages[testName] = "✅ Test passed"
    }
}
