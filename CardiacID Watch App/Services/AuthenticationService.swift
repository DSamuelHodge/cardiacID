import Foundation
import Combine

// MARK: - DataManager Import
// Using the real DataManager from the Models directory

/// Main authentication service managing enrollment and verification
class AuthenticationService: ObservableObject {
    @Published var isUserEnrolled = false
    @Published var isAuthenticated = false
    @Published var currentSession: AuthenticationSession?
    @Published var lastAuthenticationResult: AuthenticationResult?
    @Published var errorMessage: String?
    
    private let xenonXCalculator = XenonXCalculator()
    private let encryptionService = EncryptionService()
    private(set) var dataManager: DataManager?
    
    private var enrollmentPattern: XenonXResult?
    private var authenticationAttempts: [AuthenticationAttempt] = []
    
    init() {
        // DataManager will be injected via environment object
    }
    
    /// Set the data manager (called from the app)
    func setDataManager(_ dataManager: DataManager) {
        self.dataManager = dataManager
        loadUserProfile()
    }
    
    // Supabase service not available in watch app
    
    // MARK: - Enrollment Process
    
    /// Start enrollment process
    func startEnrollment() -> AnyPublisher<EnrollmentProgress, Never> {
        return Publishers.Merge(
            Just(EnrollmentProgress.started),
            enrollmentPublisher()
        )
        .eraseToAnyPublisher()
    }
    
    private func enrollmentPublisher() -> AnyPublisher<EnrollmentProgress, Never> {
        return Future<EnrollmentProgress, Never> { promise in
            // This would be called from the UI when heart rate capture is complete
            // For now, we'll simulate the process
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(.success(.capturing))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Complete enrollment with captured heart rate data using enhanced multi-algorithm approach
    func completeEnrollment(with heartRateData: [Double]) -> Bool {
        guard !heartRateData.isEmpty else {
            errorMessage = "No heart rate data provided for enrollment"
            return false
        }
        
        // Check if dataManager is available
        guard let dataManager = dataManager else {
            errorMessage = "Data manager not available. Please restart the app."
            return false
        }
        
        // Temporarily disabled - Use enhanced calculator for analysis
        // let enhancedResult = enhancedCalculator.analyzeHeartPattern(heartRateData)
        
        // Check pattern quality using enhanced metrics
        // guard enhancedResult.qualityScore > 0.6 && enhancedResult.fusedConfidence > 0.5 else {
        //     errorMessage = "Heart pattern quality too low for enrollment. Quality: \(String(format: "%.1f%%", enhancedResult.qualityScore * 100)). Please try again."
        //     return false
        // }
        
        // Analyze pattern using XenonX calculator for backward compatibility
        let xenonXResult = xenonXCalculator.analyzePattern(heartRateData)
        
        // Check pattern quality
        guard xenonXResult.confidence > 0.7 else {
            errorMessage = "Heart pattern quality too low for enrollment. Please try again."
            return false
        }
        
        // Encrypt the pattern
        guard let encryptedPattern = encryptionService.encryptXenonXResult(xenonXResult) else {
            errorMessage = "Failed to encrypt heart pattern"
            return false
        }
        
        // Create user profile
        let userProfile = UserProfile(
            encryptedHeartPattern: encryptedPattern.base64EncodedString(),
            securityLevel: dataManager.userPreferences.securityLevel
        )
        
        // Save profile locally
        dataManager.saveUserProfile(userProfile)
        
        // Store enrollment pattern for immediate verification
        enrollmentPattern = xenonXResult
        
        // Temporarily disabled - Store NASA enrollment model
        // nasaEnrollmentModel = enhancedResult.nasaModel
        
        isUserEnrolled = true
        
        // Send enrollment status to iOS app via Watch Connectivity
        sendEnrollmentStatusToiOS()
        
        errorMessage = nil
        return true
    }
    
    // MARK: - Authentication Process
    
    /// Start authentication process
    func startAuthentication() -> AnyPublisher<AuthenticationProgress, Never> {
        guard isUserEnrolled else {
            return Just(.error("User not enrolled"))
                .eraseToAnyPublisher()
        }
        
        return Publishers.Merge(
            Just(AuthenticationProgress.started),
            authenticationPublisher()
        )
        .eraseToAnyPublisher()
    }
    
    private func authenticationPublisher() -> AnyPublisher<AuthenticationProgress, Never> {
        return Future<AuthenticationProgress, Never> { promise in
            // This would be called from the UI when heart rate capture is complete
            // For now, we'll simulate the process
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(.success(.capturing))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Complete authentication with captured heart rate data using enhanced multi-algorithm approach
    func completeAuthentication(with heartRateData: [Double]) -> AuthenticationResult {
        guard isUserEnrolled else {
            errorMessage = "User not enrolled. Please complete enrollment first."
            return .failed
        }
        
        guard !heartRateData.isEmpty else {
            errorMessage = "No heart rate data provided for authentication"
            return .failed
        }
        
        // Check if dataManager is available
        guard dataManager != nil else {
            errorMessage = "Data manager not available. Please restart the app."
            return .failed
        }
        
        // Temporarily disabled - Use enhanced calculator for analysis
        // let enhancedResult = enhancedCalculator.analyzeHeartPattern(heartRateData)
        
        // Analyze current pattern
        let currentPattern = xenonXCalculator.analyzePattern(heartRateData)
        
        // Load stored pattern
        guard let storedPattern = loadStoredPattern() else {
            errorMessage = "Failed to load stored heart pattern"
            return .failed
        }
        
        // Compare patterns
        let similarity = xenonXCalculator.comparePatterns(storedPattern, currentPattern)
        
        // Determine result based on thresholds
        let result = determineAuthenticationResult(similarity: similarity)
        
        // Record attempt
        let attempt = AuthenticationAttempt(
            result: result,
            confidenceScore: currentPattern.confidence,
            patternMatch: similarity,
            duration: 0 // This would be calculated from actual capture time
        )
        
        authenticationAttempts.append(attempt)
        
        // Update session
        if currentSession == nil {
            currentSession = AuthenticationSession()
        }
        currentSession?.recordAttempt(result)
        
        // Update authentication status
        isAuthenticated = result.isSuccessful
        lastAuthenticationResult = result
        
        // Update user profile if successful
        if result.isSuccessful {
            // updateUserProfileAfterAuthentication()  // Temporarily disabled
        }
        
        // Supabase service not available in watch app
        
        // Send authentication result to iOS app via Watch Connectivity
        sendAuthenticationResultToiOS(result)
        
        return result
    }
    
    // Temporarily disabled - NASA specific helper method
    /*
    /// Generate detailed authentication message based on enhanced analysis
    private func generateAuthenticationDetails(_ result: EnhancedAnalysisResult) -> String {
        var details: [String] = []
        
        switch result.recommendedAction {
        case .accept:
            details.append("Authentication successful")
            details.append("Confidence: \(String(format: "%.1f%%", result.fusedConfidence * 100))")
        case .reject:
            details.append("Authentication failed")
            details.append("Confidence too low: \(String(format: "%.1f%%", result.fusedConfidence * 100))")
        case .requireMoreData:
            details.append("More data required")
            details.append("Current confidence: \(String(format: "%.1f%%", result.fusedConfidence * 100))")
        case .lowConfidence:
            details.append("Low confidence authentication")
            details.append("Confidence: \(String(format: "%.1f%%", result.fusedConfidence * 100))")
        }
        
        if result.algorithmAgreement < 0.7 {
            details.append("Algorithm disagreement detected")
        }
        
        if let nasaResult = result.nasaResult {
            details.append("NASA: \(nasaResult.accepted ? "Pass" : "Fail") (\(nasaResult.votes)/\(nasaResult.totalVotes) votes)")
        }
        
        if let xenonXResult = result.xenonXResult {
            details.append("XenonX: \(String(format: "%.1f%%", xenonXResult.confidence * 100)) confidence")
        }
        
        return details.joined(separator: " • ")
    }
    */
    
    // MARK: - Pattern Management
    
    private func loadStoredPattern() -> XenonXResult? {
        guard let userProfile = dataManager?.userProfile,
              let encryptedData = Data(base64Encoded: userProfile.encryptedHeartPattern) else { return nil }
        
        return encryptionService.decryptXenonXResult(encryptedData)
    }
    
    private func determineAuthenticationResult(similarity: Double) -> AuthenticationResult {
        let securityLevel = dataManager?.userProfile?.securityLevel ?? .medium
        let threshold = securityLevel.threshold
        let retryThreshold = securityLevel.retryThreshold
        
        if similarity >= threshold {
            return .approved
        } else if similarity >= Double(retryThreshold) {
            return .retryRequired
        } else {
            return .failed
        }
    }
    
    // Temporarily disabled - requires DataManager
    /*
    private func updateUserProfileAfterAuthentication() {
        guard var profile = dataManager.userProfile else { return }
        
        let updatedProfile = profile.updateAfterAuthentication()
        dataManager.saveUserProfile(updatedProfile)
        
        // Sync updated profile to Supabase if available
        if let supabaseService = supabaseService {
            Task {
                await supabaseService.syncUserProfile(updatedProfile)
            }
        }
    }
    */
    
    // MARK: - Session Management
    
    func startNewSession() {
        currentSession = AuthenticationSession()
        currentSession?.startSession()
    }
    
    func endCurrentSession() {
        currentSession?.resetSession()
        currentSession = nil
        isAuthenticated = false
    }
    
    // MARK: - Data Management
    
    private func loadUserProfile() {
        if let profile = dataManager?.userProfile {
            isUserEnrolled = profile.isEnrolled
            if isUserEnrolled {
                enrollmentPattern = loadStoredPattern()
            }
        }
    }
    
    func clearAllData() {
        dataManager?.clearAllData()
        isUserEnrolled = false
        isAuthenticated = false
        enrollmentPattern = nil
        authenticationAttempts.removeAll()
        currentSession = nil
        lastAuthenticationResult = nil
        errorMessage = nil
    }
    
    /// Logout user and clear session
    func logout() {
        isAuthenticated = false
        currentSession = nil
        lastAuthenticationResult = nil
        errorMessage = nil
        // Note: We keep isUserEnrolled = true for testing purposes
        // In production, you might want to clear this too
    }
    
    // MARK: - Watch Connectivity Integration
    
    /// Send enrollment status to iOS companion app
    private func sendEnrollmentStatusToiOS() {
        // This would be called from the app's WatchConnectivityService
        // For now, we'll post a notification that the WatchConnectivityService can listen to
        NotificationCenter.default.post(
            name: .init("SendEnrollmentStatus"),
            object: nil,
            userInfo: ["isEnrolled": isUserEnrolled]
        )
    }
    
    /// Send authentication result to iOS companion app
    private func sendAuthenticationResultToiOS(_ result: AuthenticationResult) {
        // This would be called from the app's WatchConnectivityService
        NotificationCenter.default.post(
            name: .init("SendAuthenticationResult"),
            object: nil,
            userInfo: [
                "result": result.rawValue,
                "message": result.message,
                "isSuccessful": result.isSuccessful
            ]
        )
    }
    
    // MARK: - Statistics
    
    var authenticationStatistics: AuthenticationStatistics {
        let totalAttempts = authenticationAttempts.count
        let successfulAttempts = authenticationAttempts.filter { $0.result.isSuccessful }.count
        let averageConfidence = authenticationAttempts.map { $0.confidenceScore }.reduce(0, +) / Double(max(totalAttempts, 1))
        let averageMatch = authenticationAttempts.map { $0.patternMatch }.reduce(0, +) / Double(max(totalAttempts, 1))
        
        return AuthenticationStatistics(
            totalAttempts: totalAttempts,
            successfulAttempts: successfulAttempts,
            successRate: totalAttempts > 0 ? Double(successfulAttempts) / Double(totalAttempts) * 100 : 0,
            averageConfidence: averageConfidence,
            averageMatch: averageMatch,
            lastAttempt: authenticationAttempts.last?.timestamp
        )
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

enum EnrollmentProgress {
    case started
    case capturing
    case processing
    case completed
    case error(String)
}

enum AuthenticationProgress {
    case started
    case capturing
    case processing
    case completed(AuthenticationResult)
    case error(String)
}

struct AuthenticationStatistics {
    let totalAttempts: Int
    let successfulAttempts: Int
    let successRate: Double
    let averageConfidence: Double
    let averageMatch: Double
    let lastAttempt: Date?
}

// MARK: - Background Authentication

extension AuthenticationService {
    /// Perform background authentication (called by background task service)
    func performBackgroundAuthentication() -> AuthenticationResult {
        // This would be called by the background task service
        // For now, return a placeholder result
        return .systemUnavailable
    }
    
    /// Check if background authentication is due
    func isBackgroundAuthenticationDue() -> Bool {
        guard let lastAttempt = authenticationAttempts.last?.timestamp else { return true }
        
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
        let minInterval = TimeInterval((dataManager?.userPreferences.authenticationFrequency.minIntervalMinutes ?? 15) * 60)
        
        return timeSinceLastAttempt >= minInterval
    }
}

