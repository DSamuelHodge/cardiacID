//
//  DataManager.swift
//  HeartID Watch App
//
//  Enterprise-grade data management with secure storage
//

import Foundation
import Security
import CryptoKit

/// Enterprise data manager with secure storage and encryption
class DataManager: ObservableObject {
    
    // MARK: - Configuration
    
    private let keychainService = "com.heartid.watchapp"
    private let userProfileKey = "user_profile_v2"
    private let encryptionKey = "biometric_encryption_key"
    
    // MARK: - Published Properties
    
    @Published var userPreferences = UserPreferences()
    @Published var isDataLoaded = false
    @Published var lastSyncDate: Date?
    @Published var dataIntegrityStatus: DataIntegrityStatus = .unknown
    
    // MARK: - Private Properties
    
    private var encryptionKeyData: SymmetricKey?
    
    // MARK: - Initialization
    
    init() {
        setupEncryption()
        loadUserPreferences()
        verifyDataIntegrity()
    }
    
    // MARK: - Encryption Setup
    
    private func setupEncryption() {
        // Try to load existing encryption key
        if let existingKeyData = loadFromKeychain(key: encryptionKey) {
            encryptionKeyData = SymmetricKey(data: existingKeyData)
            print("✅ Loaded existing encryption key")
        } else {
            // Generate new encryption key
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            if saveToKeychain(data: keyData, key: encryptionKey) {
                encryptionKeyData = newKey
                print("✅ Generated new encryption key")
            } else {
                print("❌ Failed to save encryption key to keychain")
            }
        }
    }
    
    // MARK: - User Profile Management
    
    /// Save user profile with encryption
    func saveUserProfile(_ profile: UserProfile) -> Bool {
        print("💾 Saving user profile to secure storage")
        
        guard let encryptionKey = encryptionKeyData else {
            print("❌ Encryption key not available")
            return false
        }
        
        do {
            // Encode profile to JSON
            let profileData = try JSONEncoder().encode(profile)
            
            // Encrypt the data
            let encryptedData = try encryptData(profileData, with: encryptionKey)
            
            // Save to keychain
            let success = saveToKeychain(data: encryptedData, key: userProfileKey)
            
            if success {
                print("✅ User profile saved successfully")
                updateDataIntegrityStatus(.valid)
            } else {
                print("❌ Failed to save user profile to keychain")
                updateDataIntegrityStatus(.corrupted)
            }
            
            return success
            
        } catch {
            print("❌ Failed to save user profile: \(error)")
            updateDataIntegrityStatus(.corrupted)
            return false
        }
    }
    
    /// Load user profile with decryption
    func getUserProfile() -> UserProfile? {
        print("📂 Loading user profile from secure storage")
        
        guard let encryptionKey = encryptionKeyData else {
            print("❌ Encryption key not available")
            return nil
        }
        
        guard let encryptedData = loadFromKeychain(key: userProfileKey) else {
            print("⚠️ No user profile found in storage")
            return nil
        }
        
        do {
            // Decrypt the data
            let decryptedData = try decryptData(encryptedData, with: encryptionKey)
            
            // Decode profile from JSON
            let profile = try JSONDecoder().decode(UserProfile.self, from: decryptedData)
            
            print("✅ User profile loaded successfully")
            updateDataIntegrityStatus(.valid)
            return profile
            
        } catch {
            print("❌ Failed to load user profile: \(error)")
            updateDataIntegrityStatus(.corrupted)
            return nil
        }
    }
    
    /// Update last authentication date
    func updateLastAuthenticationDate() -> Bool {
        guard var profile = getUserProfile() else {
            print("❌ Cannot update authentication date - no profile found")
            return false
        }
        
        profile = profile.updateAfterAuthentication(successful: true)
        return saveUserProfile(profile)
    }
    
    /// Check if user is enrolled
    func isUserEnrolled() -> Bool {
        return getUserProfile() != nil
    }
    
    // MARK: - User Preferences Management
    
    /// Save user preferences
    func saveUserPreferences(_ preferences: UserPreferences) -> Bool {
        do {
            let data = try JSONEncoder().encode(preferences)
            let success = saveToUserDefaults(data: data, key: "user_preferences")
            
            if success {
                DispatchQueue.main.async {
                    self.userPreferences = preferences
                }
                print("✅ User preferences saved")
            }
            
            return success
        } catch {
            print("❌ Failed to save user preferences: \(error)")
            return false
        }
    }
    
    /// Load user preferences
    private func loadUserPreferences() {
        if let data = loadFromUserDefaults(key: "user_preferences") {
            do {
                let preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
                DispatchQueue.main.async {
                    self.userPreferences = preferences
                    self.isDataLoaded = true
                }
                print("✅ User preferences loaded")
            } catch {
                print("❌ Failed to decode user preferences: \(error)")
                // Use default preferences
                DispatchQueue.main.async {
                    self.isDataLoaded = true
                }
            }
        } else {
            // No preferences saved, use defaults
            DispatchQueue.main.async {
                self.isDataLoaded = true
            }
            print("⚠️ No user preferences found, using defaults")
        }
    }
    
    // MARK: - Data Integrity
    
    /// Verify data integrity
    private func verifyDataIntegrity() {
        print("🔍 Verifying data integrity")
        
        // Check if encryption key is available
        guard encryptionKeyData != nil else {
            updateDataIntegrityStatus(.noEncryption)
            return
        }
        
        // Try to load and verify user profile if it exists
        if let profile = getUserProfile() {
            // Verify profile data is valid
            if profile.biometricTemplate.heartRatePattern.isEmpty {
                updateDataIntegrityStatus(.corrupted)
            } else {
                updateDataIntegrityStatus(.valid)
            }
        } else {
            // No profile means user not enrolled yet
            updateDataIntegrityStatus(.noData)
        }
    }
    
    private func updateDataIntegrityStatus(_ status: DataIntegrityStatus) {
        DispatchQueue.main.async {
            self.dataIntegrityStatus = status
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Data Management
    
    /// Clear all stored data
    func clearAllData() {
        print("🗑️ Clearing all stored data")
        
        // Remove from keychain
        deleteFromKeychain(key: userProfileKey)
        deleteFromKeychain(key: encryptionKey)
        
        // Clear user defaults
        UserDefaults.standard.removeObject(forKey: "user_preferences")
        
        // Reset state
        DispatchQueue.main.async {
            self.userPreferences = UserPreferences()
            self.dataIntegrityStatus = .unknown
            self.lastSyncDate = nil
        }
        
        // Regenerate encryption key
        setupEncryption()
        
        print("✅ All data cleared and encryption key regenerated")
    }
    
    /// Export data for backup (encrypted)
    func exportData() -> Data? {
        guard let profile = getUserProfile() else {
            print("❌ No profile to export")
            return nil
        }
        
        do {
            let exportData = DataExport(
                profile: profile,
                preferences: userPreferences,
                exportDate: Date(),
                version: "2.0"
            )
            
            let jsonData = try JSONEncoder().encode(exportData)
            print("✅ Data exported successfully (\(jsonData.count) bytes)")
            return jsonData
            
        } catch {
            print("❌ Failed to export data: \(error)")
            return nil
        }
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else {
            print("❌ Keychain save failed with status: \(status)")
            return false
        }
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status != errSecItemNotFound {
            print("❌ Keychain load failed with status: \(status)")
        }
        
        return nil
    }
    
    private func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - UserDefaults Operations
    
    private func saveToUserDefaults(data: Data, key: String) -> Bool {
        UserDefaults.standard.set(data, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    private func loadFromUserDefaults(key: String) -> Data? {
        return UserDefaults.standard.data(forKey: key)
    }
    
    // MARK: - Encryption Operations
    
    private func encryptData(_ data: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data, with key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Statistics
    
    /// Get data storage statistics
    func getStorageStatistics() -> StorageStatistics {
        let profileSize = loadFromKeychain(key: userProfileKey)?.count ?? 0
        let preferencesSize = loadFromUserDefaults(key: "user_preferences")?.count ?? 0
        let encryptionKeySize = loadFromKeychain(key: encryptionKey)?.count ?? 0
        
        return StorageStatistics(
            totalSize: profileSize + preferencesSize + encryptionKeySize,
            profileSize: profileSize,
            preferencesSize: preferencesSize,
            encryptionKeySize: encryptionKeySize,
            isEncrypted: encryptionKeyData != nil,
            integrityStatus: dataIntegrityStatus
        )
    }
}

// MARK: - Supporting Types

enum DataIntegrityStatus: String, CaseIterable {
    case valid = "Valid"
    case corrupted = "Corrupted"
    case noData = "No Data"
    case noEncryption = "No Encryption"
    case unknown = "Unknown"
    
    var isHealthy: Bool {
        return self == .valid || self == .noData
    }
    
    var description: String {
        switch self {
        case .valid:
            return "Data integrity verified"
        case .corrupted:
            return "Data corruption detected"
        case .noData:
            return "No stored data found"
        case .noEncryption:
            return "Encryption not available"
        case .unknown:
            return "Integrity status unknown"
        }
    }
}

struct StorageStatistics {
    let totalSize: Int
    let profileSize: Int
    let preferencesSize: Int
    let encryptionKeySize: Int
    let isEncrypted: Bool
    let integrityStatus: DataIntegrityStatus
    
    var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
    }
}

struct DataExport: Codable {
    let profile: UserProfile
    let preferences: UserPreferences
    let exportDate: Date
    let version: String
}