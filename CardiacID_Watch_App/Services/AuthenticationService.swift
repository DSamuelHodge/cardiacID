import Foundation
import Combine

// MARK: - DataManager Import
// Using the real DataManager from the Models directory

/// Selection for heart pattern assessment approach
enum HeartPatternAssessmentMode: String, Codable {
    case standard
    case proprietaryXenonX
}

/// Main authentication service managing enrollment and verification
class AuthenticationService: ObservableObject {
    @Published var isUserEnrolled = false
    @Published var isAuthenticated = false
    @Published var currentSession: AuthenticationSession?
    @Published var lastAuthenticationResult: AuthenticationResult?
    @Published var errorMessage: String?
    var healthKitService: HealthKitService?
    
    /// Select which calculation path to use for heart pattern assessment
    @Published var assessmentMode: HeartPatternAssessmentMode = .standard
    
    // Note: Removed unused XenonXCalculator and HeartIDEncryptionService instances to avoid ambiguous init issues. Reintroduce if needed with explicit module qualification.
    private(set) var dataManager: DataManager?
    
    private var enrollmentPattern: XenonXResult?
    private var authenticationAttempts: [AuthenticationAttempt] = []
    
    init() {
        // DataManager will be injected via environment object
    }
    
    /// Set the HealthKit service
    func setHealthKitService(_ service: HealthKitService) {
        self.healthKitService = service
    }
    
    /// Inject DataManager dependency
    func setDataManager(_ manager: DataManager) {
        self.dataManager = manager
    }
    
    /// Set the assessment mode (standard vs proprietary XenonX)
    func setAssessmentMode(_ mode: HeartPatternAssessmentMode) {
        self.assessmentMode = mode
    }
    
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
    
    /// Complete enrollment with captured heart rate data
    func completeEnrollment(with heartRateValues: [Double]) -> Bool {
        print("🔄 Processing enrollment with \(heartRateValues.count) samples")
        
        // Validate the captured data
        let validation = EnrollmentValidation.validate(heartRateValues)
        
        guard validation.isValid else {
            print("❌ Enrollment validation failed: \(validation.errorMessage ?? "Unknown error")")
            self.errorMessage = validation.errorMessage
            return false
        }
        
        // If proprietary mode is selected, compute and stash XenonX analysis for later comparisons
        if assessmentMode == .proprietaryXenonX {
            let xenon = XenonXCalculator()
            let analysis = xenon.analyzePattern(heartRateValues)
            self.enrollmentPattern = analysis
        } else {
            self.enrollmentPattern = nil
        }
        
        // Create biometric template
        let template = BiometricTemplate(heartRatePattern: heartRateValues)
        
        // Create user profile
        let profile = UserProfile(template: template)
        
        // Save to secure storage
        guard let dataManager = dataManager else {
            print("❌ DataManager not initialized")
            self.errorMessage = "Storage system not available"
            return false
        }
        
        let saveSuccess = dataManager.saveUserProfile(profile)
        
        if saveSuccess {
            DispatchQueue.main.async {
                self.isUserEnrolled = true
            }
            print("✅ Enrollment completed successfully")
            print("📊 Quality score: \(Int(validation.qualityScore * 100))%")
            return true
        } else {
            self.errorMessage = "Failed to save enrollment data"
            return false
        }
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
    
    /// Complete authentication with captured heart rate data
    func completeAuthentication(with heartRateValues: [Double]) -> AuthenticationResult {
        print("🔄 Processing authentication with \(heartRateValues.count) samples")
        
        // Get stored profile
        guard let dataManager = dataManager else {
            return .error(message: "Storage system not available")
        }
        
        guard let profile = dataManager.getUserProfile() else {
            return .error(message: "No enrollment found")
        }
        
        // Validate capture quality
        let validation = EnrollmentValidation.validate(heartRateValues)
        guard validation.isValid else {
            return .retry(message: validation.errorMessage ?? "Please try again")
        }
        
        // Compare patterns according to selected assessment mode
        let confidence: Double
        if assessmentMode == .proprietaryXenonX, let storedX = self.enrollmentPattern {
            // Use XenonX proprietary comparison
            let xenon = XenonXCalculator()
            let currentX = xenon.analyzePattern(heartRateValues)
            confidence = xenon.comparePatterns(storedX, currentX)
        } else {
            // Use standard direct pattern comparison
            let storedPattern = profile.biometricTemplate.heartRatePattern
            confidence = comparePatterns(stored: storedPattern, captured: heartRateValues)
        }
        
        // Decision threshold
        if confidence >= 0.75 {
            dataManager.updateLastAuthenticationDate()
            return .approved(confidence: confidence)
        } else if confidence >= 0.60 {
            return .retry(message: "Partial match. Please try again.")
        } else {
            return .denied(reason: "Pattern does not match")
        }
    }
    
    /// Compare heart rate patterns and return confidence score
    private func comparePatterns(stored: [Double], captured: [Double]) -> Double {
        // Normalize both patterns to same length
        let minLength = min(stored.count, captured.count)
        let storedSlice = Array(stored.prefix(minLength))
        let capturedSlice = Array(captured.prefix(minLength))
        
        // Calculate average absolute difference
        var totalDifference: Double = 0
        for i in 0..<minLength {
            totalDifference += abs(storedSlice[i] - capturedSlice[i])
        }
        let avgDifference = totalDifference / Double(minLength)
        
        // Convert to confidence score (0.0 to 1.0)
        // Lower difference = higher confidence
        let maxAllowedDifference: Double = 30.0
        let confidence = max(0.0, 1.0 - (avgDifference / maxAllowedDifference))
        
        print("📊 Pattern comparison: \(Int(confidence * 100))% match")
        return confidence
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
        // Encrypted pattern storage is not used in the current model.
        // BiometricTemplate is stored within UserProfile; XenonXResult is not persisted.
        return nil
    }
    
    private func determineAuthenticationResult(similarity: Double) -> AuthenticationResult {
        let securityLevel = dataManager?.userPreferences.securityLevel ?? .medium
        let threshold = securityLevel.threshold
        let retryThreshold = securityLevel.retryThreshold
        
        if similarity >= threshold {
            return .approved(confidence: similarity)
        } else if similarity >= Double(retryThreshold) {
            return .retry(message: "Please try again")
        } else {
            return .denied(reason: "Pattern does not match")
        }
    }
    
    // Temporarily disabled - requires DataManager
    /*
    private func updateUserProfileAfterAuthentication() {
        guard let profile = dataManager.getUserProfile() else { return }
        
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
        if let profile = dataManager?.getUserProfile() {
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
    
    /// Test helper to mark user as enrolled and authenticated
    func markEnrolledAndAuthenticated() {
        self.isUserEnrolled = true
        self.isAuthenticated = true
        self.lastAuthenticationResult = .approved(confidence: 1.0)
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
        return .error(message: "System unavailable")
    }
    
    /// Check if background authentication is due
    func isBackgroundAuthenticationDue() -> Bool {
        guard let lastAttempt = authenticationAttempts.last?.timestamp else { return true }
        
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
        let minInterval = TimeInterval((dataManager?.userPreferences.authenticationFrequency.minIntervalMinutes ?? 15) * 60)
        
        return timeSinceLastAttempt >= minInterval
    }
}

