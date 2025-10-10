import Testing
import Foundation
@testable import CardiacID_Watch_App

@Suite("Background Task Status Tests")
struct CardiacID_Watch_AppTests {

    @Test("Smoke test")
    func example() async throws {
        #expect(true)
    }

    @Test("BackgroundTaskStatus displayName mapping")
    func testDisplayNames() async throws {
        let expectations: [(BackgroundTaskStatus, String)] = [
            (.idle, "Idle"),
            (.monitoring, "Monitoring"),
            (.checking, "Checking"),
            (.authenticated, "Authenticated"),
            (.failed, "Failed"),
            (.retry, "Retry Required"),
            (.error, "Error"),
            (.background, "Background")
        ]
        for (status, expected) in expectations {
            #expect(status.displayName == expected, "\(status) displayName mismatch")
        }
    }

    @Test("BackgroundTaskStatus color mapping")
    func testColors() async throws {
        let expectations: [(BackgroundTaskStatus, String)] = [
            (.idle, "gray"),
            (.monitoring, "blue"),
            (.checking, "orange"),
            (.authenticated, "green"),
            (.failed, "red"),
            (.retry, "yellow"),
            (.error, "red"),
            (.background, "purple")
        ]
        for (status, expected) in expectations {
            #expect(status.color == expected, "\(status) color mismatch")
        }
    }

    @Test("BackgroundTaskService statusDescription for each status")
    func testStatusDescriptions() async throws {
        let service = BackgroundTaskService()
        let expectations: [(BackgroundTaskStatus, String)] = [
            (.idle, "Background monitoring inactive"),
            (.monitoring, "Monitoring authentication status"),
            (.checking, "Performing background check"),
            (.authenticated, "Background authentication successful"),
            (.failed, "Background authentication failed"),
            (.retry, "Background authentication requires retry"),
            (.error, "Background authentication error"),
            (.background, "Running in background")
        ]
        for (status, expected) in expectations {
            service.backgroundTaskStatus = status
            #expect(service.statusDescription == expected, "\(status) description mismatch")
        }
    }

    @Test("BackgroundTaskService timeSinceLastCheck formatting")
    func testTimeSinceLastCheck() async throws {
        let service = BackgroundTaskService()

        // Never case
        service.lastBackgroundCheck = nil
        #expect(service.timeSinceLastCheck == "Never")

        // Seconds (< 60)
        service.lastBackgroundCheck = Date().addingTimeInterval(-30)
        #expect(service.timeSinceLastCheck.hasSuffix("s ago"))

        // Minutes (< 3600)
        service.lastBackgroundCheck = Date().addingTimeInterval(-120) // 2 minutes
        #expect(service.timeSinceLastCheck == "2m ago")

        // Hours (>= 3600)
        service.lastBackgroundCheck = Date().addingTimeInterval(-7200) // 2 hours
        #expect(service.timeSinceLastCheck == "2h ago")
    }
}

