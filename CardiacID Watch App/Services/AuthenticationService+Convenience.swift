import Foundation

extension AuthenticationService {
    /// Mark the current user as enrolled and authenticated after successful template verification.
    func markEnrolledAndAuthenticated() {
        // If these are @Published, the UI will refresh automatically.
        // If not, ensure you call `objectWillChange.send()` in your base service.
        isUserEnrolled = true
        isAuthenticated = true
        lastAuthenticationResult = .approved
    }
}
