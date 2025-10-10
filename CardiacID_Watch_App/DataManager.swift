//
//  DataManager.swift
//  HeartID
//
//  Handles secure storage and retrieval of biometric data
//

import Foundation
import Security
import CryptoKit

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // UserDefaults keys
    private enum Keys {
        static let isUserEnrolled = "isUserEnrolled"
        static let enrollmentDate = "enrollmentDate"
        static let lastAuthDate = "lastAuthenticationDate"
        static let templateVersion = "templateVersion"
    }
    
    // Keychain keys
    private enum SecureKeys {
        static let userProfile = "com.heartid.userProfile"
        static let biometricTemplate = "com.heartid.biometricTemplate"
        static let encryptionKey = "com.heartid.encryptionKey"
    }
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainService()
    
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
        do {
            // Encrypt biometric template before storage
            let encryptedTemplate = try encryptBiometricTemplate(profile.biometricTemplate)
            
            // Create secure profile with encrypted template
            let secureProfile = SecureUserProfile(
                id: profile.id,
                enrollmentDate: profile.enrollmentDate,
                encryptedTemplate: encryptedTemplate,
                lastAuthenticationDate: profile.lastAuthenticationDate,
                authenticationCount: profile.authenticationCount,
                templateVersion: getCurrentTemplateVersion()
            )
            
            // Encode and save to Keychain
            let profileData = try JSONEncoder().encode(secureProfile)
            let saveSuccess = saveToKeychain(data: profileData, key: SecureKeys.userProfile)
            
            if saveSuccess {
                // Update UserDefaults flags
                userDefaults.set(true, forKey: Keys.isUserEnrolled)
                userDefaults.set(profile.enrollmentDate, forKey: Keys.enrollmentDate)
                userDefaults.set(getCurrentTemplateVersion(), forKey: Keys.templateVersion)
                
                DispatchQueue.main.async {
                    self.isUserEnrolled = true
                }
                
                print("✅ User profile saved successfully with encryption")
                return true
            }
            
            print("❌ Failed to save user profile to Keychain")
            return false
        } catch {
            print("❌ Failed to encrypt user profile: \(error.localizedDescription)")
            return false
        }
    }
    
    func getUserProfile() -> UserProfile? {
        guard let profileData = loadFromKeychain(key: SecureKeys.userProfile) else {
            print("⚠️ No user profile found in Keychain")
            return nil
        }
        
        do {
            // Try to decode as SecureUserProfile first (new format)
            if let secureProfile = try? JSONDecoder().decode(SecureUserProfile.self, from: profileData) {
                // Decrypt biometric template
                let decryptedTemplate = try decryptBiometricTemplate(secureProfile.encryptedTemplate)
                
                // Create UserProfile from secure profile
                var userProfile = UserProfile(id: secureProfile.id, template: decryptedTemplate)
                userProfile.lastAuthenticationDate = secureProfile.lastAuthenticationDate
                userProfile.authenticationCount = secureProfile.authenticationCount
                return userProfile
            } else {
                // Fallback to old format (unencrypted)
                let profile = try JSONDecoder().decode(UserProfile.self, from: profileData)
                print("⚠️ Loaded unencrypted profile - consider re-enrolling for enhanced security")
                return profile
            }
        } catch {
            print("❌ Failed to decode user profile: \(error.localizedDescription)")
            return nil
        }
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
        return keychain.save(data: data, key: key)
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        return keychain.load(key: key)
    }
    
    private func deleteFromKeychain(key: String) -> Bool {
        return keychain.delete(key: key)
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
    
    // MARK: - Encryption Methods
    
    /// Encrypt biometric template using AES-GCM
    private func encryptBiometricTemplate(_ template: BiometricTemplate) throws -> Data {
        let templateData = try JSONEncoder().encode(template)
        let key = try getOrCreateEncryptionKey()
        
        let sealedBox = try AES.GCM.seal(templateData, using: key)
        return sealedBox.combined!
    }
    
    /// Decrypt biometric template using AES-GCM
    private func decryptBiometricTemplate(_ encryptedData: Data) throws -> BiometricTemplate {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try JSONDecoder().decode(BiometricTemplate.self, from: decryptedData)
    }
    
    /// Get or create encryption key for biometric templates
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let keyData = loadFromKeychain(key: SecureKeys.encryptionKey) {
            return SymmetricKey(data: keyData)
        }
        
        // Create new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        // Save to Keychain
        if saveToKeychain(data: keyData, key: SecureKeys.encryptionKey) {
            return newKey
        } else {
            throw DataManagerError.encryptionKeyCreationFailed
        }
    }
    
    /// Get current template version for future algorithm updates
    private func getCurrentTemplateVersion() -> Int {
        return userDefaults.integer(forKey: Keys.templateVersion) > 0 ? 
               userDefaults.integer(forKey: Keys.templateVersion) : 1
    }
    
    /// Check if template needs migration to newer version
    func needsTemplateMigration() -> Bool {
        let currentVersion = getCurrentTemplateVersion()
        let latestVersion = 1 // Update this when algorithm changes
        
        return currentVersion < latestVersion
    }
    
    /// Migrate template to newer version
    func migrateTemplate() -> Bool {
        guard needsTemplateMigration() else { return true }
        
        guard let profile = getUserProfile() else { return false }
        
        // Re-save with current version
        let success = saveUserProfile(profile)
        if success {
            userDefaults.set(getCurrentTemplateVersion(), forKey: Keys.templateVersion)
        }
        
        return success
    }
}

// MARK: - Supporting Types

/// Secure user profile with encrypted biometric template
struct SecureUserProfile: Codable {
    let id: UUID
    let enrollmentDate: Date
    let encryptedTemplate: Data
    let lastAuthenticationDate: Date?
    let authenticationCount: Int
    let templateVersion: Int
}

/// DataManager specific errors
enum DataManagerError: Error, LocalizedError {
    case encryptionKeyCreationFailed
    case templateDecryptionFailed
    case templateMigrationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionKeyCreationFailed:
            return "Failed to create encryption key"
        case .templateDecryptionFailed:
            return "Failed to decrypt biometric template"
        case .templateMigrationFailed:
            return "Failed to migrate template to newer version"
        }
    }
}

/// Keychain service for secure storage
class KeychainService {
    func save(data: Data, key: String) -> Bool {
        // Delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item with enhanced security
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false // Device-only, no iCloud sync
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func load(key: String) -> Data? {
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
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
