//
//  DataManager.swift
//  HeartID Watch App
//
//  Enterprise-ready data management with full compatibility
//

import Foundation
import Security

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private enum Keys {
        static let isUserEnrolled = "isUserEnrolled"
        static let enrollmentDate = "enrollmentDate"
        static let lastAuthDate = "lastAuthenticationDate"
        static let templateVersion = "templateVersion"
    }
    
    private let userDefaults = UserDefaults.standard
    
    @Published var isUserEnrolled: Bool = false
    @Published var userPreferences: UserPreferences = UserPreferences()
    
    var enrollmentDate: Date? {
        userDefaults.object(forKey: Keys.enrollmentDate) as? Date
    }
    
    var lastAuthenticationDate: Date? {
        userDefaults.object(forKey: Keys.lastAuthDate) as? Date
    }
    
    var authenticationCount: Int {
        userDefaults.integer(forKey: "authenticationCount")
    }
    
    var currentSecurityLevel: SecurityLevel {
        userPreferences.securityLevel
    }
    
    init() {
        isUserEnrolled = userDefaults.bool(forKey: Keys.isUserEnrolled)
        loadUserPreferences()
    }
    
    // MARK: - Enrollment Management
    
    func setUserEnrolled(_ enrolled: Bool) {
        isUserEnrolled = enrolled
        userDefaults.set(enrolled, forKey: Keys.isUserEnrolled)
        
        if enrolled {
            userDefaults.set(Date(), forKey: Keys.enrollmentDate)
        }
    }
    
    func updateLastAuthentication() {
        userDefaults.set(Date(), forKey: Keys.lastAuthDate)
        let count = userDefaults.integer(forKey: "authenticationCount")
        userDefaults.set(count + 1, forKey: "authenticationCount")
    }
    
    func updateLastAuthenticationDate() {
        updateLastAuthentication()
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(_ profile: UserProfile) -> Bool {
        // Save basic profile info
        userDefaults.set(profile.id, forKey: "userProfileId")
        userDefaults.set(profile.enrollmentDate, forKey: Keys.enrollmentDate)
        userDefaults.set(profile.lastAuthenticationDate, forKey: Keys.lastAuthDate)
        userDefaults.set(profile.authenticationCount, forKey: "authenticationCount")
        
        // Save biometric template
        if let templateData = try? JSONEncoder().encode(profile.template) {
            return saveBiometricTemplate(templateData)
        }
        
        return false
    }
    
    func getUserProfile() -> UserProfile? {
        guard let profileId = userDefaults.string(forKey: "userProfileId"),
              let templateData = loadBiometricTemplate(),
              let template = try? JSONDecoder().decode(BiometricTemplate.self, from: templateData) else {
            return nil
        }
        
        var profile = UserProfile(id: profileId, template: template)
        profile.enrollmentDate = userDefaults.object(forKey: Keys.enrollmentDate) as? Date
        profile.lastAuthenticationDate = userDefaults.object(forKey: Keys.lastAuthDate) as? Date
        profile.authenticationCount = userDefaults.integer(forKey: "authenticationCount")
        
        return profile
    }
    
    // MARK: - User Preferences
    
    private func loadUserPreferences() {
        if let data = userDefaults.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = preferences
        }
    }
    
    func saveUserPreferences() {
        if let data = try? JSONEncoder().encode(userPreferences) {
            userDefaults.set(data, forKey: "userPreferences")
        }
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        // Clear UserDefaults
        userDefaults.removeObject(forKey: Keys.isUserEnrolled)
        userDefaults.removeObject(forKey: Keys.enrollmentDate)
        userDefaults.removeObject(forKey: Keys.lastAuthDate)
        userDefaults.removeObject(forKey: "authenticationCount")
        userDefaults.removeObject(forKey: "userProfileId")
        userDefaults.removeObject(forKey: "userPreferences")
        
        // Clear Keychain
        deleteBiometricTemplate()
        
        // Reset state
        isUserEnrolled = false
        userPreferences = UserPreferences()
    }
    
    func resetToDefaults() {
        userPreferences = UserPreferences()
        saveUserPreferences()
    }
    
    // MARK: - Secure Storage
    
    func saveBiometricTemplate(_ template: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricTemplate",
            kSecValueData as String: template
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func loadBiometricTemplate() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricTemplate",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        
        return nil
    }
    
    func deleteBiometricTemplate() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "biometricTemplate"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// MARK: - UserPreferences Model

struct UserPreferences: Codable {
    var securityLevel: SecurityLevel = .medium
    var enableNotifications: Bool = true
    var autoLockEnabled: Bool = true
    var authenticationFrequency: AuthenticationFrequency = .onDemand
    
    enum AuthenticationFrequency: String, Codable, CaseIterable {
        case onDemand = "onDemand"
        case periodic = "periodic"
        case continuous = "continuous"
    }
}