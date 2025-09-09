import Foundation
import CryptoKit
import Security

/// Service for handling encryption and decryption operations
class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychain = KeychainService.shared
    private let keyTag = "heartid_encryption_key"
    
    private init() {
        ensureEncryptionKeyExists()
    }
    
    // MARK: - Data Encryption/Decryption
    
    /// Encrypt data using AES-256-GCM
    func encrypt(data: Data) -> Data? {
        guard let key = getEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    /// Decrypt data using AES-256-GCM
    func decrypt(data: Data) -> Data? {
        guard let key = getEncryptionKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Heart Pattern Encryption
    
    /// Encrypt heart pattern data
    func encryptHeartPattern(_ pattern: HeartPattern) -> Data? {
        do {
            let patternData = try JSONEncoder().encode(pattern)
            return encrypt(data: patternData)
        } catch {
            print("Failed to encode heart pattern: \(error)")
            return nil
        }
    }
    
    /// Decrypt heart pattern data
    func decryptHeartPattern(_ data: Data) -> HeartPattern? {
        guard let decryptedData = decrypt(data: data) else { return nil }
        
        do {
            return try JSONDecoder().decode(HeartPattern.self, from: decryptedData)
        } catch {
            print("Failed to decode heart pattern: \(error)")
            return nil
        }
    }
    
    // MARK: - String Encryption
    
    /// Encrypt string data
    func encrypt(string: String) -> String? {
        guard let data = string.data(using: .utf8),
              let encryptedData = encrypt(data: data) else { return nil }
        return encryptedData.base64EncodedString()
    }
    
    /// Decrypt string data
    func decrypt(string: String) -> String? {
        guard let data = Data(base64Encoded: string),
              let decryptedData = decrypt(data: data) else { return nil }
        return String(data: decryptedData, encoding: .utf8)
    }
    
    // MARK: - Hashing
    
    /// Generate SHA-256 hash of string
    func hash(string: String) -> String {
        let data = string.data(using: .utf8) ?? Data()
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Generate SHA-256 hash of data
    func hash(data: Data) -> String {
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Random Data Generation
    
    /// Generate cryptographically secure random data
    func generateRandomData(length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        return result == errSecSuccess ? data : nil
    }
    
    /// Generate random string
    func generateRandomString(length: Int) -> String? {
        guard let data = generateRandomData(length: length) else { return nil }
        return data.base64EncodedString()
    }
    
    // MARK: - Key Management
    
    private func ensureEncryptionKeyExists() {
        if getEncryptionKey() == nil {
            createEncryptionKey()
        }
    }
    
    private func createEncryptionKey() {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        keychain.store(keyData, forKey: keyTag)
    }
    
    private func getEncryptionKey() -> SymmetricKey? {
        guard let keyData = keychain.retrieveData(forKey: keyTag) else { return nil }
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Certificate and Key Operations
    
    /// Generate RSA key pair
    func generateRSAKeyPair() -> (publicKey: Data, privateKey: Data)? {
        let keySize = 2048
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: keySize,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: false
            ]
        ]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to create RSA key pair: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to create RSA key pair: Unknown error")
            }
            return nil
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("Failed to extract public key")
            return nil
        }
        
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to export public key: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to export public key: Unknown error")
            }
            return nil
        }
        
        guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to export private key: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to export private key: Unknown error")
            }
            return nil
        }
        
        return (publicKey: publicKeyData as Data, privateKey: privateKeyData as Data)
    }
    
    /// Sign data with private key
    func sign(data: Data, with privateKey: Data) -> Data? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(privateKey as CFData, attributes as CFDictionary, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to create private key: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to create private key: Unknown error")
            }
            return nil
        }
        
        guard let signature = SecKeyCreateSignature(key, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to create signature: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to create signature: Unknown error")
            }
            return nil
        }
        
        return signature as Data
    }
    
    /// Verify signature with public key
    func verify(signature: Data, data: Data, with publicKey: Data) -> Bool {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(publicKey as CFData, attributes as CFDictionary, &error) else {
            if let cfError = error?.takeRetainedValue() {
                print("Failed to create public key: \(CFErrorCopyDescription(cfError) ?? "Unknown error" as CFString)")
            } else {
                print("Failed to create public key: Unknown error")
            }
            return false
        }
        
        return SecKeyVerifySignature(key, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, signature as CFData, &error)
    }
}
