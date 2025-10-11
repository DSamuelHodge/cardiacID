import Foundation

extension AuthenticationResult {
    /// Represents a successful authentication
    public static var success: AuthenticationResult {
        return .approved(confidence: 1.0)
    }
    
    /// Represents a failed authentication
    public static var failure: AuthenticationResult {
        return .denied(reason: "Authentication failed")
    }
    
    /// Represents a cancelled authentication
    public static var cancelled: AuthenticationResult {
        return .error(message: "Authentication cancelled")
    }
    
    /// Convenience property to check if authentication was successful
    public var isSuccess: Bool {
        return isSuccessful
    }
    
    /// Convenience property to get the result message
    public var resultMessage: String {
        return message
    }
}
