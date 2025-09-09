import Foundation
import Combine

/// Service for managing passwordless authentication methods
class PasswordlessAuthService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var errorMessage: String?
    @Published var availableMethods: [PasswordlessMethod] = []
    @Published var enrollmentPublisher = PassthroughSubject<EnrollmentResult, Never>()
    @Published var authResultPublisher = PassthroughSubject<AuthResult, Never>()
    
    // MARK: - Private Properties
    
    private var enrolledMethods: [PasswordlessMethod] = []
    private let userDefaults = UserDefaults.standard
    private let enrolledMethodsKey = "enrolledPasswordlessMethods"
    
    // MARK: - Initialization
    
    init() {
        loadAvailableMethods()
        loadEnrolledMethods()
    }
    
    // MARK: - Public Methods
    
    func getEnrolledMethods() -> [PasswordlessMethod] {
        return enrolledMethods
    }
    
    func enroll(method: PasswordlessMethod, with heartPattern: HeartPattern) {
        // In a real implementation, this would:
        // 1. Validate the heart pattern
        // 2. Create a biometric template
        // 3. Store it securely
        // 4. Register with the authentication system
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var enrolledMethod = method
            enrolledMethod.isEnrolled = true
            enrolledMethod.enrolledAt = Date()
            
            self.enrolledMethods.append(enrolledMethod)
            self.saveEnrolledMethods()
            
            let result = EnrollmentResult(success: true, method: enrolledMethod, error: nil)
            self.enrollmentPublisher.send(result)
        }
    }
    
    func removeEnrollment(method: PasswordlessMethod) {
        enrolledMethods.removeAll { $0.id == method.id }
        saveEnrolledMethods()
    }
    
    func authenticate(method: PasswordlessMethod, with heartPattern: HeartPattern) {
        // In a real implementation, this would:
        // 1. Validate the heart pattern against stored templates
        // 2. Calculate similarity score
        // 3. Determine if authentication succeeds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate authentication with 90% success rate
            let success = Double.random(in: 0...1) < 0.9
            let result = AuthResult(success: success, method: method, error: success ? nil : "Pattern mismatch")
            self.authResultPublisher.send(result)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadAvailableMethods() {
        availableMethods = [
            PasswordlessMethod(
                id: "biometric",
                name: "Face ID / Touch ID",
                type: .biometric,
                isAvailable: true,
                isEnrolled: false
            ),
            PasswordlessMethod(
                id: "fido2",
                name: "FIDO2 Security Key",
                type: .fido2,
                isAvailable: true,
                isEnrolled: false
            ),
            PasswordlessMethod(
                id: "nfc",
                name: "NFC Card",
                type: .nfc,
                isAvailable: true,
                isEnrolled: false
            ),
            PasswordlessMethod(
                id: "bluetooth",
                name: "Bluetooth Device",
                type: .bluetooth,
                isAvailable: true,
                isEnrolled: false
            ),
            PasswordlessMethod(
                id: "heartid",
                name: "Heart ID",
                type: .heartID,
                isAvailable: true,
                isEnrolled: false
            )
        ]
    }
    
    private func loadEnrolledMethods() {
        if let data = userDefaults.data(forKey: enrolledMethodsKey),
           let methods = try? JSONDecoder().decode([PasswordlessMethod].self, from: data) {
            enrolledMethods = methods
        }
    }
    
    private func saveEnrolledMethods() {
        if let data = try? JSONEncoder().encode(enrolledMethods) {
            userDefaults.set(data, forKey: enrolledMethodsKey)
        }
    }
}

// MARK: - Passwordless Method Model

struct PasswordlessMethod: Identifiable, Codable {
    let id: String
    let name: String
    let type: PasswordlessMethodType
    let isAvailable: Bool
    var isEnrolled: Bool
    var enrolledAt: Date?
    
    init(id: String, name: String, type: PasswordlessMethodType, isAvailable: Bool, isEnrolled: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.isAvailable = isAvailable
        self.isEnrolled = isEnrolled
        self.enrolledAt = nil
    }
}

// MARK: - Passwordless Method Type

enum PasswordlessMethodType: String, CaseIterable, Codable {
    case biometric = "biometric"
    case fido2 = "fido2"
    case nfc = "nfc"
    case bluetooth = "bluetooth"
    case heartID = "heartid"
}

// MARK: - Result Models

struct EnrollmentResult {
    let success: Bool
    let method: PasswordlessMethod
    let error: String?
}

struct AuthResult {
    let success: Bool
    let method: PasswordlessMethod
    let error: String?
}
