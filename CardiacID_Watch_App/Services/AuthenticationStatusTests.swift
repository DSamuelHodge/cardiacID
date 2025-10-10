#if canImport(XCTest)
import XCTest
@testable import YourAppModuleName

final class UserAuthStatusTests: XCTestCase {

    func testUserAuthStatusRawValues() {
        XCTAssertEqual(UserAuthStatus.approved.rawValue, "approved")
        XCTAssertEqual(UserAuthStatus.denied.rawValue, "denied")
        XCTAssertEqual(UserAuthStatus.pending.rawValue, "pending")
        XCTAssertEqual(UserAuthStatus.error.rawValue, "error")
        XCTAssertEqual(UserAuthStatus.timeout.rawValue, "timeout")
    }

    func testExamplePayloadFromWatch() throws {
        // Example payload dictionary as might be received from the watch
        let examplePayload: [String: Any] = [
            "status": "approved",
            "userId": "12345",
            "timestamp": 1672531200,
            "metadata": [
                "device": "Apple Watch",
                "version": "7.0"
            ]
        ]

        // Required keys and their expected types
        let requiredKeysAndTypes: [String: Any.Type] = [
            "status": String.self,
            "userId": String.self,
            "timestamp": Int.self,
            "metadata": [String: Any].self
        ]

        for (key, expectedType) in requiredKeysAndTypes {
            guard let value = examplePayload[key] else {
                XCTFail("Payload is missing required key: \(key)")
                continue
            }
            XCTAssert(type(of: value) == expectedType, "Key '\(key)' has unexpected type. Expected \(expectedType), got \(type(of: value))")
        }

        // Additional validation: status should be a valid UserAuthStatus rawValue
        let statusValue = examplePayload["status"] as? String
        XCTAssertNotNil(statusValue, "Status value is nil")
        XCTAssertNotNil(UserAuthStatus(rawValue: statusValue!), "Status value '\(statusValue ?? "")' is not a valid UserAuthStatus raw value")
    }
}
#endif
