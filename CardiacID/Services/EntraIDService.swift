import Foundation
import Combine

/// Service for managing enterprise authentication with Entra ID (Azure AD)
class EntraIDService: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: EntraIDUser?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let tenantId: String
    private let clientId: String
    private let redirectUri: String
    private var accessToken: String?
    private var refreshToken: String?
    
    // MARK: - Initialization
    
    init(tenantId: String, clientId: String, redirectUri: String) {
        self.tenantId = tenantId
        self.clientId = clientId
        self.redirectUri = redirectUri
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        // In a real implementation, this would initiate OAuth2 flow with Entra ID
        // For demo purposes, we'll simulate authentication
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let mockUser = EntraIDUser(
                id: "entra-user-123",
                displayName: "John Doe",
                email: "john.doe@company.com",
                jobTitle: "Software Engineer",
                department: "Engineering",
                permissions: [.doorAccess, .nfcAccess, .bluetoothAccess, .heartAuthentication]
            )
            
            self.currentUser = mockUser
            self.isAuthenticated = true
            self.accessToken = "mock-entra-token"
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        accessToken = nil
        refreshToken = nil
    }
    
    // MARK: - Permission Management
    
    func hasPermission(_ permission: EntraIDPermission) -> Bool {
        return currentUser?.permissions.contains(permission) ?? false
    }
    
    func requestPermission(_ permission: EntraIDPermission) {
        // In a real implementation, this would request additional permissions
        // For demo purposes, we'll just log the request
        print("Requesting permission: \(permission.rawValue)")
    }
}

// MARK: - EntraID User Model

struct EntraIDUser: Identifiable, Codable {
    let id: String
    let displayName: String
    let email: String
    let jobTitle: String?
    let department: String?
    let permissions: [EntraIDPermission]
    
    init(id: String, displayName: String, email: String, jobTitle: String?, department: String?, permissions: [EntraIDPermission]) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.jobTitle = jobTitle
        self.department = department
        self.permissions = permissions
    }
}

// MARK: - EntraID Permission Enum

enum EntraIDPermission: String, CaseIterable, Codable {
    case doorAccess = "door_access"
    case nfcAccess = "nfc_access"
    case bluetoothAccess = "bluetooth_access"
    case heartAuthentication = "heart_authentication"
    case adminAccess = "admin_access"
    case deviceManagement = "device_management"
    
    var displayName: String {
        switch self {
        case .doorAccess:
            return "Door Access"
        case .nfcAccess:
            return "NFC Access"
        case .bluetoothAccess:
            return "Bluetooth Access"
        case .heartAuthentication:
            return "Heart Authentication"
        case .adminAccess:
            return "Admin Access"
        case .deviceManagement:
            return "Device Management"
        }
    }
}
