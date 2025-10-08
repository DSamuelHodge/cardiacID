import BiometricModels

extension AuthenticationResult {
    /// Represents a successful authentication
    public static var success: AuthenticationResult {
        return .succeeded
    }
    
    /// Represents a failed authentication
    public static var failure: AuthenticationResult {
        return .failed
    }
    
    /// Represents a cancelled authentication
    public static var cancelled: AuthenticationResult {
        return .cancelled
    }
}
