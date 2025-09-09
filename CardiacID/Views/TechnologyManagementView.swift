import SwiftUI
import Combine
import CoreBluetooth
import CoreNFC

/// Comprehensive technology management screen for EntraID, Active Directory, NFC, Bluetooth, and door locks
struct TechnologyManagementView: View {
    // Services
    @StateObject private var entraIDService = EntraIDService(
        tenantId: "your-tenant-id",
        clientId: "your-client-id",
        redirectUri: "your-redirect-uri"
    )
    @StateObject private var bluetoothService = BluetoothDoorLockService()
    @StateObject private var nfcService = NFCService()
    @StateObject private var deviceManagementService = DeviceManagementService(entraIDService: EntraIDService(
        tenantId: "your-tenant-id",
        clientId: "your-client-id",
        redirectUri: "your-redirect-uri"
    ))
    @StateObject private var passwordlessService = PasswordlessAuthService()
    
    // State
    @State private var selectedTab: TechnologyTab = .entraID
    @State private var showingSettings = false
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: ManagedDevice?
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Colors
    private let colors = HeartIDColors()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                // Technology Tabs
                TechnologyTabView(selectedTab: $selectedTab)
                
                // Content
                TabContentView(
                    selectedTab: selectedTab,
                    entraIDService: entraIDService,
                    bluetoothService: bluetoothService,
                    nfcService: nfcService,
                    deviceManagementService: deviceManagementService,
                    passwordlessService: passwordlessService,
                    onDeviceSelected: { device in
                        selectedDevice = device
                        showingDeviceDetails = true
                    }
                )
            }
            .background(colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                TechnologySettingsView(
                    entraIDService: entraIDService,
                    bluetoothService: bluetoothService,
                    nfcService: nfcService
                )
            }
            .sheet(isPresented: $showingDeviceDetails) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onAppear {
                setupServices()
            }
        }
    }
    
    private func setupServices() {
        // Setup error handling
        entraIDService.$errorMessage
            .compactMap { $0 }
            .sink { error in
                errorMessage = error
                showingError = true
            }
            .store(in: &cancellables)
        
        bluetoothService.$errorMessage
            .compactMap { $0 }
            .sink { error in
                errorMessage = error
                showingError = true
            }
            .store(in: &cancellables)
        
        nfcService.$errorMessage
            .compactMap { $0 }
            .sink { error in
                errorMessage = error
                showingError = true
            }
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Header View
struct HeaderView: View {
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Technology Management")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Manage enterprise, device, and security integrations")
                        .font(.subheadline)
                        .foregroundColor(colors.text.opacity(0.7))
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(colors.surface)
    }
}

// MARK: - Technology Tab View
struct TechnologyTabView: View {
    @Binding var selectedTab: TechnologyTab
    private let colors = HeartIDColors()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(TechnologyTab.allCases, id: \.self) { tab in
                    TechnologyTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(colors.surface)
    }
}

struct TechnologyTabButton: View {
    let tab: TechnologyTab
    let isSelected: Bool
    let action: () -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                Text(tab.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? colors.accent : colors.text.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? colors.accent.opacity(0.1) : Color.clear)
            )
        }
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    let selectedTab: TechnologyTab
    let entraIDService: EntraIDService
    let bluetoothService: BluetoothDoorLockService
    let nfcService: NFCService
    let deviceManagementService: DeviceManagementService
    let passwordlessService: PasswordlessAuthService
    let onDeviceSelected: (ManagedDevice) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .bluetooth:
                    BluetoothManagementView(
                        service: bluetoothService,
                        onDeviceSelected: onDeviceSelected
                    )
                case .nfc:
                    NFCManagementView(
                        service: nfcService,
                        onDeviceSelected: onDeviceSelected
                    )
                case .entraID:
                    EntraIDManagementView(service: entraIDService)
                case .activeDirectory:
                    ActiveDirectoryManagementView()
                case .legacySystems:
                    LegacySystemsManagementView()
                case .passwordlessAuth:
                    PasswordlessAuthManagementView(
                        passwordlessService: passwordlessService
                    )
                case .keychainService:
                    KeychainServiceManagementView()
                case .doorLockManagement:
                    DoorLockManagementView(
                        bluetoothService: bluetoothService,
                        onDeviceSelected: onDeviceSelected
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Technology Tabs
enum TechnologyTab: String, CaseIterable {
    case bluetooth = "Bluetooth"
    case nfc = "NFC"
    case entraID = "Entra ID"
    case activeDirectory = "Active Directory"
    case legacySystems = "Legacy Systems"
    case passwordlessAuth = "Passwordless Auth"
    case keychainService = "Keychain"
    case doorLockManagement = "Door Locks"
    
    var icon: String {
        switch self {
        case .bluetooth: return "bluetooth"
        case .nfc: return "wave.3.right"
        case .entraID: return "building.2.crop.circle"
        case .activeDirectory: return "server.rack"
        case .legacySystems: return "externaldrive.connected.to.line.below"
        case .passwordlessAuth: return "person.badge.key"
        case .keychainService: return "key.horizontal"
        case .doorLockManagement: return "lock.shield"
        }
    }
    
    var title: String {
        return rawValue
    }
}

// MARK: - EntraID Management View
struct EntraIDManagementView: View {
    @ObservedObject var service: EntraIDService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            ConnectionStatusCard(
                title: "EntraID Connection",
                isConnected: service.isAuthenticated,
                statusText: service.isAuthenticated ? "Connected" : "Not Connected",
                userInfo: service.currentUser?.displayName
            )
            
            // Authentication Actions
            VStack(spacing: 12) {
                if service.isAuthenticated {
                    Button("Sign Out") {
                        service.signOut()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button("Refresh User Info") {
                        // Refresh user information
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Connect to EntraID") {
                        service.authenticate()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            // User Information
            if let user = service.currentUser {
                UserInfoCard(user: user)
            }
            
            // Enterprise Features
            if service.isAuthenticated {
                EnterpriseFeaturesCard(service: service)
            }
        }
    }
}

// MARK: - Bluetooth Management View
struct BluetoothManagementView: View {
    @ObservedObject var service: BluetoothDoorLockService
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Bluetooth Status
            ConnectionStatusCard(
                title: "Bluetooth",
                isConnected: service.isBluetoothAvailable,
                statusText: service.isBluetoothAvailable ? "Available" : "Not Available",
                userInfo: nil
            )
            
            // Scan Controls
            VStack(spacing: 12) {
                if service.isScanning {
                    Button("Stop Scanning") {
                        service.stopScanning()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Start Scanning") {
                        service.startScanning()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            // Discovered Devices
            if !service.discoveredLocks.isEmpty {
                DiscoveredDevicesList(
                    devices: service.discoveredLocks,
                    onDeviceSelected: onDeviceSelected
                )
            }
            
            // Connected Devices
            if !service.connectedLocks.isEmpty {
                DiscoveredDevicesList(
                    devices: service.connectedLocks,
                    onDeviceSelected: onDeviceSelected
                )
            }
        }
    }
}

// MARK: - NFC Management View
struct NFCManagementView: View {
    @ObservedObject var service: NFCService
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // NFC Status
            ConnectionStatusCard(
                title: "NFC",
                isConnected: service.isNFCAvailable,
                statusText: service.isNFCAvailable ? "Available" : "Not Available",
                userInfo: nil
            )
            
            // NFC Actions
            VStack(spacing: 12) {
                if service.isScanning {
                    Button("Stop Scanning") {
                        service.stopScanning()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Start Scanning") {
                        service.startScanning()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                Button("Read Tag") {
                    service.readTagData()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Write Tag") {
                    // Implement write functionality
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            // Last Scanned Tag
            if let tag = service.lastScannedTag {
                LastScannedTagCard(tag: tag)
            }
        }
    }
}

// MARK: - Door Lock Management View
struct DoorLockManagementView: View {
    @ObservedObject var bluetoothService: BluetoothDoorLockService
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Door Lock Status
            ConnectionStatusCard(
                title: "Door Locks",
                isConnected: !bluetoothService.connectedLocks.isEmpty,
                statusText: "\(bluetoothService.connectedLocks.count) Connected",
                userInfo: nil
            )
            
            // Door Lock Actions
            VStack(spacing: 12) {
                Button("Discover Door Locks") {
                    bluetoothService.startScanning()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                if !bluetoothService.connectedLocks.isEmpty {
                    Button("Refresh Status") {
                        // Refresh door lock status
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            
            // Connected Door Locks
            if !bluetoothService.connectedLocks.isEmpty {
                DoorLockList(
                    locks: bluetoothService.connectedLocks,
                    onLockSelected: onDeviceSelected
                )
            }
        }
    }
}

// MARK: - Device Management Overview View
struct DeviceManagementOverviewView: View {
    @ObservedObject var service: DeviceManagementService
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Device Summary
            DeviceSummaryCard(
                connectedDevices: service.connectedDevices.count,
                availableDevices: service.availableDevices.count
            )
            
            // Device Actions
            VStack(spacing: 12) {
                if service.isScanning {
                    Button("Stop Scanning") {
                        service.stopScanning()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Button("Start Scanning") {
                        service.startScanning()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                Button("Refresh Devices") {
                    service.refreshDevices()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            // Connected Devices
            if !service.connectedDevices.isEmpty {
                ConnectedDevicesList(
                    devices: service.connectedDevices,
                    onDeviceSelected: onDeviceSelected
                )
            }
            
            // Available Devices
            if !service.availableDevices.isEmpty {
                AvailableDevicesList(
                    devices: service.availableDevices,
                    onDeviceSelected: onDeviceSelected
                )
            }
        }
    }
}

// MARK: - Active Directory Management View
struct ActiveDirectoryManagementView: View {
    @State private var isConnected = false
    @State private var domainController = "ad.company.com"
    @State private var lastSync = Date()
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            ConnectionStatusCard(
                title: "Active Directory",
                isConnected: isConnected,
                statusText: isConnected ? "Connected" : "Not Connected",
                userInfo: isConnected ? domainController : nil
            )
            
            // Connection Actions
            VStack(spacing: 12) {
                if isConnected {
                    Button("Disconnect") {
                        isConnected = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Sync Users") {
                        // Sync users from AD
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Connect to AD") {
                        isConnected = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            // AD Information
            if isConnected {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Directory Information")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        InfoRow(label: "Domain Controller", value: domainController)
                        InfoRow(label: "Last Sync", value: DateFormatter.localizedString(from: lastSync, dateStyle: .short, timeStyle: .short))
                        InfoRow(label: "Users Synced", value: "1,247")
                        InfoRow(label: "Groups Synced", value: "89")
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Legacy Systems Management View
struct LegacySystemsManagementView: View {
    @State private var legacySystems: [LegacySystem] = [
        LegacySystem(name: "Mainframe DB", status: .connected, lastSync: Date()),
        LegacySystem(name: "AS/400 System", status: .disconnected, lastSync: Date().addingTimeInterval(-3600)),
        LegacySystem(name: "Unix Server", status: .connected, lastSync: Date())
    ]
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Legacy Systems Status
            VStack(alignment: .leading, spacing: 12) {
                Text("Legacy Systems")
                    .font(.headline)
                
                ForEach(legacySystems) { system in
                    LegacySystemRow(system: system)
                }
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(12)
            
            // Legacy System Actions
            VStack(spacing: 12) {
                Button("Sync All Systems") {
                    // Sync all legacy systems
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Test Connections") {
                    // Test all connections
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Passwordless Auth Management View
struct PasswordlessAuthManagementView: View {
    @ObservedObject var passwordlessService: PasswordlessAuthService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Passwordless Auth Status
            ConnectionStatusCard(
                title: "Passwordless Authentication",
                isConnected: !passwordlessService.getEnrolledMethods().isEmpty,
                statusText: !passwordlessService.getEnrolledMethods().isEmpty ? "Enabled" : "Not Enabled",
                userInfo: "\(passwordlessService.getEnrolledMethods().count) methods enrolled"
            )
            
            // Available Methods
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Methods")
                    .font(.headline)
                
                ForEach(passwordlessService.availableMethods) { method in
                    TechnologyPasswordlessMethodRow(method: method)
                }
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(12)
            
            // Passwordless Actions
            VStack(spacing: 12) {
                Button("Configure Methods") {
                    // Navigate to method configuration
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Test Authentication") {
                    // Test passwordless auth
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Keychain Service Management View
struct KeychainServiceManagementView: View {
    @State private var keychainItems: [KeychainItem] = [
        KeychainItem(key: "heart_pattern_encryption", type: "Data", size: "2.1 KB"),
        KeychainItem(key: "user_credentials", type: "Dictionary", size: "512 B"),
        KeychainItem(key: "device_certificate", type: "Certificate", size: "1.8 KB")
    ]
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 20) {
            // Keychain Status
            ConnectionStatusCard(
                title: "Keychain Service",
                isConnected: true,
                statusText: "Active",
                userInfo: "\(keychainItems.count) items stored"
            )
            
            // Keychain Items
            VStack(alignment: .leading, spacing: 12) {
                Text("Stored Items")
                    .font(.headline)
                
                ForEach(keychainItems) { item in
                    KeychainItemRow(item: item)
                }
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(12)
            
            // Keychain Actions
            VStack(spacing: 12) {
                Button("Add New Item") {
                    // Add new keychain item
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Clear All Items") {
                    // Clear all keychain items
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

// MARK: - Supporting Views

struct ConnectionStatusCard: View {
    let title: String
    let isConnected: Bool
    let statusText: String
    let userInfo: String?
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(isConnected ? colors.success : colors.error)
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.headline)
                Spacer()
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(colors.text.opacity(0.7))
            }
            
            if let userInfo = userInfo {
                Text("User: \(userInfo)")
                    .font(.subheadline)
                    .foregroundColor(colors.text.opacity(0.8))
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct UserInfoCard: View {
    let user: EntraIDUser
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Name", value: user.displayName)
                InfoRow(label: "Email", value: user.email)
                if let jobTitle = user.jobTitle {
                    InfoRow(label: "Job Title", value: jobTitle)
                }
                if let department = user.department {
                    InfoRow(label: "Department", value: department)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(colors.text.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(colors.text)
        }
    }
}

struct EnterpriseFeaturesCard: View {
    @ObservedObject var service: EntraIDService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enterprise Features")
                .font(.headline)
            
            VStack(spacing: 8) {
                FeatureButton(
                    title: "View Groups",
                    icon: "person.3.fill",
                    action: {
                        // Load and display groups
                    }
                )
                
                FeatureButton(
                    title: "View Applications",
                    icon: "app.fill",
                    action: {
                        // Load and display applications
                    }
                )
                
                FeatureButton(
                    title: "Security Policies",
                    icon: "shield.fill",
                    action: {
                        // Load and display security policies
                    }
                )
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct FeatureButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(colors.accent)
                Text(title)
                    .foregroundColor(colors.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(colors.text.opacity(0.5))
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }
}

struct DiscoveredDevicesList: View {
    let devices: [BluetoothDoorLock]
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discovered Devices")
                .font(.headline)
            
            ForEach(devices) { device in
                DeviceRow(
                    name: device.name,
                    type: "Bluetooth Door Lock",
                    status: device.isConnected ? "Connected" : "Discovered",
                    rssi: device.rssi
                ) {
                    // Convert to ManagedDevice and call onDeviceSelected
                    let managedDevice = ManagedDevice(
                        name: device.name,
                        type: .bluetoothDoorLock,
                        status: device.isConnected ? .connected : .discovered,
                        bluetoothLock: device
                    )
                    onDeviceSelected(managedDevice)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct ConnectedDevicesList: View {
    let devices: [ManagedDevice]
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Devices")
                .font(.headline)
            
            ForEach(devices) { device in
                DeviceRow(
                    name: device.name,
                    type: device.type.rawValue,
                    status: device.status.rawValue,
                    rssi: nil
                ) {
                    onDeviceSelected(device)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct AvailableDevicesList: View {
    let devices: [ManagedDevice]
    let onDeviceSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Devices")
                .font(.headline)
            
            ForEach(devices) { device in
                DeviceRow(
                    name: device.name,
                    type: device.type.rawValue,
                    status: device.status.rawValue,
                    rssi: nil
                ) {
                    onDeviceSelected(device)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct DeviceRow: View {
    let name: String
    let type: String
    let status: String
    let rssi: Int?
    let action: () -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(colors.text)
                    Text(type)
                        .font(.caption)
                        .foregroundColor(colors.text.opacity(0.7))
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(status.capitalized)
                        .font(.caption)
                        .foregroundColor(colors.success)
                    if let rssi = rssi {
                        Text("\(rssi) dBm")
                            .font(.caption2)
                            .foregroundColor(colors.text.opacity(0.5))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct LastScannedTagCard: View {
    let tag: NFCTagData
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Scanned Tag")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Type", value: "\(tag.type)")
                InfoRow(label: "Timestamp", value: DateFormatter.localizedString(from: tag.timestamp, dateStyle: .short, timeStyle: .short))
                InfoRow(label: "Device ID", value: tag.deviceId)
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct DoorLockList: View {
    let locks: [BluetoothDoorLock]
    let onLockSelected: (ManagedDevice) -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Door Locks")
                .font(.headline)
            
            ForEach(locks) { lock in
                DoorLockRow(lock: lock) {
                    let managedDevice = ManagedDevice(
                        name: lock.name,
                        type: .bluetoothDoorLock,
                        status: .connected,
                        bluetoothLock: lock
                    )
                    onLockSelected(managedDevice)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct DoorLockRow: View {
    let lock: BluetoothDoorLock
    let action: () -> Void
    private let colors = HeartIDColors()
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(colors.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lock.name)
                        .font(.subheadline)
                        .foregroundColor(colors.text)
                    if let location = lock.location {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(colors.text.opacity(0.7))
                    }
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(lock.isConnected ? colors.success : colors.error)
                        .frame(width: 8, height: 8)
                    Text(lock.isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(colors.text.opacity(0.7))
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct DeviceSummaryCard: View {
    let connectedDevices: Int
    let availableDevices: Int
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(connectedDevices)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colors.accent)
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundColor(colors.text.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(availableDevices)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colors.warning)
                    Text("Available")
                        .font(.subheadline)
                        .foregroundColor(colors.text.opacity(0.7))
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct SecurityStatusCard: View {
    let passwordlessEnabled: Bool
    let entraIDConnected: Bool
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Status")
                .font(.headline)
            
            HStack {
                SecurityStatusItem(
                    title: "Passwordless Auth",
                    isEnabled: passwordlessEnabled
                )
                Spacer()
                SecurityStatusItem(
                    title: "EntraID",
                    isEnabled: entraIDConnected
                )
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct SecurityStatusItem: View {
    let title: String
    let isEnabled: Bool
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isEnabled ? colors.success : colors.error)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption)
                .foregroundColor(colors.text.opacity(0.7))
        }
    }
}

struct SecurityFeaturesList: View {
    @ObservedObject var passwordlessService: PasswordlessAuthService
    @ObservedObject var entraIDService: EntraIDService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security Features")
                .font(.headline)
            
            VStack(spacing: 8) {
                SecurityFeatureRow(
                    title: "Face ID / Touch ID",
                    isEnabled: true, // Placeholder
                    icon: "faceid"
                )
                
                SecurityFeatureRow(
                    title: "Heart Pattern Auth",
                    isEnabled: true, // Placeholder
                    icon: "heart.fill"
                )
                
                SecurityFeatureRow(
                    title: "NFC Authentication",
                    isEnabled: true, // Placeholder
                    icon: "wave.3.right"
                )
                
                SecurityFeatureRow(
                    title: "Bluetooth Security",
                    isEnabled: true, // Placeholder
                    icon: "bluetooth"
                )
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct SecurityFeatureRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(colors.accent)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(colors.text)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? colors.success : colors.error)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    private let colors = HeartIDColors()
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(colors.accent)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    private let colors = HeartIDColors()
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(colors.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(colors.accent.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Device Detail View
struct DeviceDetailView: View {
    let device: ManagedDevice
    @Environment(\.dismiss) private var dismiss
    private let colors = HeartIDColors()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Device Header
                    VStack(spacing: 12) {
                        Image(systemName: deviceIcon(for: device.type))
                            .font(.system(size: 60))
                            .foregroundColor(colors.accent)
                        
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(device.type.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(colors.text.opacity(0.7))
                    }
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(16)
                    
                    // Device Information
                    DeviceInfoSection(device: device)
                    
                    // Device Actions
                    DeviceActionsSection(device: device)
                    
                    // Device Status
                    DeviceStatusSection(device: device)
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deviceIcon(for type: DeviceType) -> String {
        switch type {
        case .bluetoothDoorLock: return "lock.shield"
        case .nfcTag: return "wave.3.right"
        case .appleWatch: return "applewatch"
        case .enterpriseDevice: return "building.2.crop.circle"
        }
    }
}

struct DeviceInfoSection: View {
    let device: ManagedDevice
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "ID", value: device.id.uuidString)
                InfoRow(label: "Type", value: device.type.rawValue)
                InfoRow(label: "Status", value: device.status.rawValue)
                if let lastSeen = device.lastSeen {
                    InfoRow(label: "Last Seen", value: DateFormatter.localizedString(from: lastSeen, dateStyle: .short, timeStyle: .short))
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct DeviceActionsSection: View {
    let device: ManagedDevice
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
            
            VStack(spacing: 8) {
                Button("Connect") {
                    // Connect to device
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Disconnect") {
                    // Disconnect from device
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Refresh Status") {
                    // Refresh device status
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct DeviceStatusSection: View {
    let device: ManagedDevice
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(statusColor(for: device.status))
                    .frame(width: 12, height: 12)
                Text(device.status.rawValue.capitalized)
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
    
    private func statusColor(for status: iPhoneDeviceStatus) -> Color {
        let colors = HeartIDColors()
        switch status {
        case .connected: return colors.success
        case .discovered: return colors.warning
        case .disconnected: return colors.error
        case .error: return colors.error
        }
    }
}

// MARK: - Technology Settings View
struct TechnologySettingsView: View {
    @ObservedObject var entraIDService: EntraIDService
    @ObservedObject var bluetoothService: BluetoothDoorLockService
    @ObservedObject var nfcService: NFCService
    @Environment(\.dismiss) private var dismiss
    private let colors = HeartIDColors()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // EntraID Settings
                    SettingsSection(
                        title: "EntraID Configuration",
                        icon: "building.2.crop.circle"
                    ) {
                        EntraIDSettingsView(service: entraIDService)
                    }
                    
                    // Bluetooth Settings
                    SettingsSection(
                        title: "Bluetooth Configuration",
                        icon: "bluetooth"
                    ) {
                        BluetoothSettingsView(service: bluetoothService)
                    }
                    
                    // NFC Settings
                    SettingsSection(
                        title: "NFC Configuration",
                        icon: "wave.3.right"
                    ) {
                        NFCSettingsView(service: nfcService)
                    }
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle("Technology Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    private let colors = HeartIDColors()
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(colors.accent)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(12)
    }
}

struct EntraIDSettingsView: View {
    @ObservedObject var service: EntraIDService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Tenant ID", value: "your-tenant-id")
            InfoRow(label: "Client ID", value: "your-client-id")
            InfoRow(label: "Status", value: service.isAuthenticated ? "Connected" : "Not Connected")
        }
    }
}

struct BluetoothSettingsView: View {
    @ObservedObject var service: BluetoothDoorLockService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Available", value: service.isBluetoothAvailable ? "Yes" : "No")
            InfoRow(label: "Scanning", value: service.isScanning ? "Yes" : "No")
            InfoRow(label: "Connected Devices", value: "\(service.connectedLocks.count)")
        }
    }
}

struct NFCSettingsView: View {
    @ObservedObject var service: NFCService
    private let colors = HeartIDColors()
    
    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Available", value: service.isNFCAvailable ? "Yes" : "No")
            InfoRow(label: "Scanning", value: service.isScanning ? "Yes" : "No")
            InfoRow(label: "Last Tag", value: service.lastScannedTag != nil ? "Scanned" : "None")
        }
    }
}

// MARK: - Supporting Data Models

struct LegacySystem: Identifiable {
    let id = UUID()
    let name: String
    let status: SystemStatus
    let lastSync: Date
}

enum SystemStatus {
    case connected
    case disconnected
    case error
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .orange
        case .error: return .red
        }
    }
}

struct KeychainItem: Identifiable {
    let id = UUID()
    let key: String
    let type: String
    let size: String
}

// MARK: - Supporting Row Views

struct LegacySystemRow: View {
    let system: LegacySystem
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: "server.rack")
                .foregroundColor(colors.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(system.name)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                Text("Last sync: \(DateFormatter.localizedString(from: system.lastSync, dateStyle: .short, timeStyle: .short))")
                    .font(.caption)
                    .foregroundColor(colors.text.opacity(0.7))
            }
            
            Spacer()
            
            Circle()
                .fill(system.status.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

struct TechnologyPasswordlessMethodRow: View {
    let method: PasswordlessMethod
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: methodIcon(for: method.type))
                .foregroundColor(colors.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(method.name)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                Text(methodTypeDescription(for: method.type))
                    .font(.caption)
                    .foregroundColor(colors.text.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: method.isEnrolled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(method.isEnrolled ? colors.success : colors.text.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    private func methodIcon(for type: PasswordlessMethodType) -> String {
        switch type {
        case .biometric: return "faceid"
        case .fido2: return "key.horizontal"
        case .nfc: return "wave.3.right"
        case .bluetooth: return "bluetooth"
        case .heartID: return "heart.fill"
        }
    }
    
    private func methodTypeDescription(for type: PasswordlessMethodType) -> String {
        switch type {
        case .biometric: return "Biometric authentication"
        case .fido2: return "FIDO2 security key"
        case .nfc: return "NFC authentication"
        case .bluetooth: return "Bluetooth authentication"
        case .heartID: return "Heart pattern authentication"
        }
    }
}

struct KeychainItemRow: View {
    let item: KeychainItem
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: "key.horizontal")
                .foregroundColor(colors.accent)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.key)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                Text("\(item.type) • \(item.size)")
                    .font(.caption)
                    .foregroundColor(colors.text.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .foregroundColor(colors.text.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TechnologyManagementView()
        .environmentObject(AuthenticationManager())
        .environmentObject(WatchConnectivityService.shared)
        .environmentObject(AuthViewModel())
}
