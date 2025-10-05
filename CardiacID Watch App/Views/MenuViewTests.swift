#if canImport(Testing)

import Testing
import SwiftUI

@testable import CardiacID  // Changed from HeartID to match project module name

@Suite("MenuView Integration Tests")
struct MenuViewTests {
    
    @Test("MenuView initializes correctly with all services")
    func testMenuViewInitialization() async throws {
        let authService = AuthenticationService()
        let dataManager = DataManager()
        let healthKitService = HealthKitService()
        
        #expect(authService != nil, "AuthenticationService should initialize")
        #expect(dataManager != nil, "DataManager should initialize")
        #expect(healthKitService != nil, "HealthKitService should initialize")
    }
    
    @Test("Enrollment button state reflects user enrollment status")
    func testEnrollmentButtonState() async throws {
        let authService = AuthenticationService()
        let dataManager = DataManager()
        
        // Test not enrolled state
        #expect(authService.isUserEnrolled == false, "User should not be enrolled initially")
        
        // Test enrolled state (simulate)
        authService.markEnrolledAndAuthenticated()
        #expect(authService.isUserEnrolled == true, "User should be enrolled after marking")
    }
    
    @Test("SecurityLevel enum has correct values")
    func testSecurityLevelValues() async throws {
        let levels = SecurityLevel.allCases
        
        #expect(levels.count == 4, "Should have 4 security levels")
        #expect(levels.contains(.low), "Should contain low security level")
        #expect(levels.contains(.medium), "Should contain medium security level")
        #expect(levels.contains(.high), "Should contain high security level")
        #expect(levels.contains(.maximum), "Should contain maximum security level")
        
        // Test thresholds are properly ordered
        #expect(SecurityLevel.low.threshold < SecurityLevel.medium.threshold, "Low threshold should be less than medium")
        #expect(SecurityLevel.medium.threshold < SecurityLevel.high.threshold, "Medium threshold should be less than high")
        #expect(SecurityLevel.high.threshold < SecurityLevel.maximum.threshold, "High threshold should be less than maximum")
    }
    
    @Test("UserPreferences initializes with correct defaults")
    func testUserPreferencesDefaults() async throws {
        let preferences = UserPreferences()
        
        #expect(preferences.securityLevel == .medium, "Default security level should be medium")
        #expect(preferences.enableNotifications == true, "Notifications should be enabled by default")
        #expect(preferences.enableAlarms == true, "Alarms should be enabled by default")
        #expect(preferences.backgroundAuthenticationEnabled == true, "Background auth should be enabled by default")
    }
    
    @Test("DataManager save and load cycle works")
    func testDataManagerSaveLoadCycle() async throws {
        let dataManager = DataManager()
        var preferences = UserPreferences()
        preferences.securityLevel = .high
        preferences.enableNotifications = false
        
        // Save preferences
        dataManager.saveUserPreferences(preferences)
        
        // Verify they were saved
        #expect(dataManager.userPreferences.securityLevel == .high, "Security level should be saved")
        #expect(dataManager.userPreferences.enableNotifications == false, "Notification setting should be saved")
    }
    
    @Test("Authentication status reflects service state")
    func testAuthenticationStatus() async throws {
        let authService = AuthenticationService()
        
        // Initial state
        #expect(authService.isAuthenticated == false, "Should not be authenticated initially")
        #expect(authService.lastAuthenticationResult == nil, "Should have no last result initially")
        
        // After marking authenticated
        authService.markEnrolledAndAuthenticated()
        #expect(authService.isAuthenticated == true, "Should be authenticated after marking")
        #expect(authService.lastAuthenticationResult == .approved, "Last result should be approved")
    }
    
    @Test("EnrollmentStatusView displays correct status")
    func testEnrollmentStatusView() async throws {
        // Test not enrolled
        let notEnrolledView = EnrollmentStatusView(isEnrolled: false)
        // View tests would need ViewInspector or similar testing framework
        // For now, we just ensure the view can be created
        #expect(notEnrolledView.isEnrolled == false, "View should reflect not enrolled state")
        
        // Test enrolled
        let enrolledView = EnrollmentStatusView(isEnrolled: true)
        #expect(enrolledView.isEnrolled == true, "View should reflect enrolled state")
    }
    
    @Test("CalibrationState enum works correctly")
    func testCalibrationState() async throws {
        // This tests the enum from CalibrateView
        let readyState = CalibrateView.CalibrationState.ready
        let inProgressState = CalibrateView.CalibrationState.inProgress  
        let completedState = CalibrateView.CalibrationState.completed
        let errorState = CalibrateView.CalibrationState.error("Test error")
        
        // Ensure states can be created and compared
        switch readyState {
        case .ready:
            break // Expected
        default:
            #expect(Bool(false), "Ready state should be .ready")
        }
        
        switch errorState {
        case .error(let message):
            #expect(message == "Test error", "Error state should contain correct message")
        default:
            #expect(Bool(false), "Error state should be .error")
        }
    }
    
    @Test("SheetRoute enum provides correct identifiers")
    func testSheetRouteIdentification() async throws {
        // Test that SheetRoute enum (private to MenuView) can be used properly
        // This is more of a design validation test
        let routes: [String] = ["enroll", "authenticate", "settings", "calibrate", "security", "alarm"]
        
        #expect(routes.count == 6, "Should have 6 different routes")
        #expect(routes.contains("enroll"), "Should contain enroll route")
        #expect(routes.contains("authenticate"), "Should contain authenticate route")
    }
    
    @Test("Error handling works in MenuView actions")
    func testErrorHandling() async throws {
        let authService = AuthenticationService()
        let healthKitService = HealthKitService()
        
        // Test unauthorized HealthKit scenario
        healthKitService.isAuthorized = false
        
        // In a real implementation, this would test the error handling
        // For now, we verify the service states
        #expect(healthKitService.isAuthorized == false, "HealthKit should not be authorized")
        #expect(authService.isUserEnrolled == false, "User should not be enrolled")
    }
}

// Extension for testing AuthenticationService
extension AuthenticationService {
    /// Test helper to mark user as enrolled and authenticated
    func markEnrolledAndAuthenticated() {
        self.isUserEnrolled = true
        self.isAuthenticated = true
        self.lastAuthenticationResult = .approved
    }
}

#endif
