//
//  DataManager.swift
//  HeartID
//
//  Handles secure storage and retrieval of biometric data
//

import Foundation
import Security

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // UserDefaults keys
    private enum Keys {
        static let isUserEnrolled = "isUserEnrolled"
        static let enrollmentDate = "enrollmentDate"
        static let lastAuthDate = "lastAuthenticationDate"
    }
    
    // Keychain keys
    private enum SecureKeys {
        static let userProfile = "com.heartid.userProfile"
        static let biometricTemplate = "com.heartid.biometricTemplate"
    }
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Published Properties
    @Published var isUserEnrolled: Bool = false
    @Published var userPreferences: UserPreferences = UserPreferences()
    
    var currentSecurityLevel: SecurityLevel { userPreferences.securityLevel }
    
    var enrollmentDate: Date? { userDefaults.object(forKey: Keys.enrollmentDate) as? Date }
    var lastAuthenticationDate: Date? { userDefaults.object(forKey: Keys.lastAuthDate) as? Date }
    var authenticationCount: Int { 0 }
    
    init() {
        self.isUserEnrolled = userDefaults.bool(forKey: Keys.isUserEnrolled)
        loadUserPreferences()
    }
    
    // MARK: - User Profile Management
    
    func saveUserProfile(_ profile: UserProfile) -> Bool {
        // Save to Keychain
        guard let profileData = try? JSONEncoder().encode(profile) else {
            print("❌ Failed to encode user profile")
            return false
        }
        
        let saveSuccess = saveToKeychain(data: profileData, key: SecureKeys.userProfile)
        
        if saveSuccess {
            // Update UserDefaults flags
            userDefaults.set(true, forKey: Keys.isUserEnrolled)
            userDefaults.set(profile.enrollmentDate, forKey: Keys.enrollmentDate)
            
            DispatchQueue.main.async {
                self.isUserEnrolled = true
            }
            
            print("✅ User profile saved successfully")
            return true
        }
        
        print("❌ Failed to save user profile to Keychain")
        return false
    }
    
    func getUserProfile() -> UserProfile? {
        guard let profileData = loadFromKeychain(key: SecureKeys.userProfile),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) else {
            print("⚠️ No user profile found or decode failed")
            return nil
        }
        
        return profile
    }
    
    func deleteUserProfile() -> Bool {
        let deleteSuccess = deleteFromKeychain(key: SecureKeys.userProfile)
        
        if deleteSuccess {
            userDefaults.set(false, forKey: Keys.isUserEnrolled)
            userDefaults.removeObject(forKey: Keys.enrollmentDate)
            userDefaults.removeObject(forKey: Keys.lastAuthDate)
            
            DispatchQueue.main.async {
                self.isUserEnrolled = false
            }
            
            // Post notification
            NotificationCenter.default.post(name: .init("UserDeleted"), object: nil)
            
            print("✅ User profile deleted successfully")
            return true
        }
        
        print("❌ Failed to delete user profile")
        return false
    }
    
    func updateLastAuthenticationDate() {
        userDefaults.set(Date(), forKey: Keys.lastAuthDate)
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(data: Data, key: String) -> Bool {
        // Delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
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
    
    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - User Preferences and Data Reset
    
    func saveUserPreferences(_ preferences: UserPreferences) {
        self.userPreferences = preferences
        // Persist to UserDefaults
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: "userPreferencesData")
        }
    }
    
    func loadUserPreferences() {
        if let data = userDefaults.data(forKey: "userPreferencesData"),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = prefs
        } else {
            self.userPreferences = UserPreferences()
        }
    }
    
    func clearAllData() {
        _ = deleteUserProfile()
        userDefaults.removeObject(forKey: Keys.isUserEnrolled)
        userDefaults.removeObject(forKey: Keys.enrollmentDate)
        userDefaults.removeObject(forKey: Keys.lastAuthDate)
        userDefaults.removeObject(forKey: "userPreferencesData")
        DispatchQueue.main.async { self.isUserEnrolled = false }
    }
    
    func resetToDefaults() {
        self.userPreferences = UserPreferences()
        saveUserPreferences(self.userPreferences)
    }
}
