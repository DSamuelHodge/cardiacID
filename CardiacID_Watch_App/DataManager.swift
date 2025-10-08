//
//  DataManager.swift
//  HeartID Watch App & iOS App
//
//  Comprehensive data management for user profiles and preferences
//

import Foundation
import Combine

/// Main data manager for user profiles, preferences, and biometric data
class DataManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published var isDataLoaded: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainService.shared
    
    // Keys for UserDefaults
    private enum Keys {
        static let userPreferences = "com.heartid.userPreferences"
        static let isUserEnrolled = "com.heartid.isUserEnrolled"
        static let lastSyncDate = "com.heartid.lastSyncDate"
    }
    
    // Keys for Keychain (secure storage)
    private enum SecureKeys {
        static let userProfile = "com.heartid.userProfile"
        static let encryptedPattern = "com.heartid.encryptedPattern"
    }
    
    init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        loadUserPreferences()
        loadUserProfile()
        isDataLoaded = true
        print("📊 DataManager: All data loaded successfully")
    }
    
    private func loadUserPreferences() {
        if let data = userDefaults.data(forKey: Keys.userPreferences),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            userPreferences = preferences
            print("✅ DataManager: User preferences loaded")
        } else {
            // Use default preferences
            userPreferences = UserPreferences()
            saveUserPreferences(userPreferences)
            print("📝 DataManager: Using default preferences")
        }
    }
    
    private func loadUserProfile() {
        if let profileData = keychain.load(key: SecureKeys.userProfile),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            userProfile = profile
            print("✅ DataManager: User profile loaded from secure storage")
        } else {
            userProfile = nil
            print("📝 DataManager: No user profile found")
        }
    }
    
    // MARK: - Data Saving
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: Keys.userPreferences)
            print("✅ DataManager: User preferences saved")
        } else {
            errorMessage = "Failed to save user preferences"
            print("❌ DataManager: Failed to save user preferences")
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
        
        if let data = try? JSONEncoder().encode(profile) {
            let success = keychain.save(data: data, key: SecureKeys.userProfile)
            if success {
                // Also save enrollment status to UserDefaults for quick access
                userDefaults.set(true, forKey: Keys.isUserEnrolled)
                print("✅ DataManager: User profile saved to secure storage")
            } else {
                errorMessage = "Failed to save user profile to secure storage"
                print("❌ DataManager: Failed to save user profile to keychain")
            }
        } else {
            errorMessage = "Failed to encode user profile"
            print("❌ DataManager: Failed to encode user profile")
        }
    }
    
    // MARK: - Data Queries
    
    var isUserEnrolled: Bool {
        return userProfile?.isEnrolled ?? false
    }
    
    var enrollmentDate: Date? {
        return userProfile?.enrollmentDate
    }
    
    var lastAuthenticationDate: Date? {
        return userProfile?.lastAuthenticationDate
    }
    
    var authenticationCount: Int {
        return userProfile?.authenticationCount ?? 0
    }
    
    var currentSecurityLevel: SecurityLevel {
        return userProfile?.securityLevel ?? userPreferences.securityLevel
    }
    
    // MARK: - Data Management
    
    func updateProfileAfterAuthentication(successful: Bool = true) {
        guard var profile = userProfile else {
            errorMessage = "No user profile to update"
            return
        }
        
        profile = profile.updateAfterAuthentication(successful: successful)
        saveUserProfile(profile)
    }
    
    func clearAllData() {
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: Keys.userPreferences)
        userDefaults.removeObject(forKey: Keys.isUserEnrolled)
        userDefaults.removeObject(forKey: Keys.lastSyncDate)
        
        // Remove from Keychain
        keychain.delete(key: SecureKeys.userProfile)
        keychain.delete(key: SecureKeys.encryptedPattern)
        
        // Reset in-memory data
        userProfile = nil
        userPreferences = UserPreferences()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .init("UserDeleted"), object: nil)
        
        print("🗑️ DataManager: All data cleared")
    }
    
    func resetToDefaults() {
        userPreferences = UserPreferences()
        saveUserPreferences(userPreferences)
        print("🔄 DataManager: Reset to default preferences")
    }
    
    // MARK: - Export/Import (for debugging or data transfer)
    
    func exportUserData() -> [String: Any]? {
        var data: [String: Any] = [:]
        
        // Add preferences
        if let preferencesData = try? JSONEncoder().encode(userPreferences) {
            data["preferences"] = preferencesData.base64EncodedString()
        }
        
        // Add profile metadata (not the actual biometric data)
        if let profile = userProfile {
            data["profileMetadata"] = [
                "enrollmentDate": profile.enrollmentDate.timeIntervalSince1970,
                "securityLevel": profile.securityLevel.rawValue,
                "authenticationCount": profile.authenticationCount,
                "isEnrolled": profile.isEnrolled
            ]
        }
        
        data["exportDate"] = Date().timeIntervalSince1970
        
        return data.isEmpty ? nil : data
    }
    
    // MARK: - Validation
    
    func validateDataIntegrity() -> Bool {
        // Check if enrolled user has valid profile
        if userDefaults.bool(forKey: Keys.isUserEnrolled) {
            guard let profile = userProfile,
                  profile.isEnrolled,
                  !profile.encryptedHeartPattern.isEmpty else {
                errorMessage = "Data integrity check failed: Enrolled user missing valid profile"
                return false
            }
        }
        
        print("✅ DataManager: Data integrity check passed")
        return true
    }
    
    // MARK: - Statistics
    
    var userStatistics: UserStatistics {
        return UserStatistics(
            enrollmentDate: userProfile?.enrollmentDate,
            totalAuthentications: userProfile?.authenticationCount ?? 0,
            lastAuthentication: userProfile?.lastAuthenticationDate,
            securityLevel: currentSecurityLevel,
            failedAttempts: userProfile?.failedAttempts ?? 0
        )
    }
}

// MARK: - Supporting Types

struct UserStatistics {
    let enrollmentDate: Date?
    let totalAuthentications: Int
    let lastAuthentication: Date?
    let securityLevel: SecurityLevel
    let failedAttempts: Int
    
    var daysSinceEnrollment: Int? {
        guard let enrollmentDate = enrollmentDate else { return nil }
        return Calendar.current.dateComponents([.day], from: enrollmentDate, to: Date()).day
    }
    
    var daysSinceLastAuth: Int? {
        guard let lastAuth = lastAuthentication else { return nil }
        return Calendar.current.dateComponents([.day], from: lastAuth, to: Date()).day
    }
}

// MARK: - Keychain Service

class KeychainService {
    static let shared = KeychainService()
    private init() {}
    
    func save(data: Data, key: String) -> Bool {
        // Delete any existing item first
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("✅ Keychain: Successfully saved data for key: \(key)")
            return true
        } else {
            print("❌ Keychain: Failed to save data for key: \(key), status: \(status)")
            return false
        }
    }
    
    func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            if let data = item as? Data {
                print("✅ Keychain: Successfully loaded data for key: \(key)")
                return data
            } else {
                print("⚠️ Keychain: Data format error for key: \(key)")
                return nil
            }
        } else if status == errSecItemNotFound {
            print("📝 Keychain: No data found for key: \(key)")
            return nil
        } else {
            print("❌ Keychain: Failed to load data for key: \(key), status: \(status)")
            return nil
        }
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Keychain: Successfully deleted data for key: \(key)")
        } else {
            print("❌ Keychain: Failed to delete data for key: \(key), status: \(status)")
        }
    }
}